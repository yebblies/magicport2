
// Compiler implementation of the D programming language
// Copyright (c) 1999-2013 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module libelf;

import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;
import core.stdc.time;

import core.sys.posix.sys.types;
import core.sys.posix.unistd;
import core.sys.posix.sys.stat;

import root.file, root.filename, root.outbuffer, root.stringtable;
import mars, lib, scanelf;

static if (TARGET_LINUX || TARGET_FREEBSD || TARGET_OPENBSD || TARGET_SOLARIS):

enum LOG = false;

struct ObjSymbol
{
    char* name;
    ObjModule* om;
};

extern(C++)
class LibElf : Library
{
public:
    File* libfile;
    ObjModule*[] objmodules;
    ObjSymbol*[] objsymbols;

    StringTable tab;

    this()
    {
        libfile = null;
        tab._init();
    }

    /***********************************
     * Set the library file name based on the output directory
     * and the filename.
     * Add default library file name extension.
     */
    void setFilename(const(char)* dir, const(char)* filename)
    {
        static if (LOG)
        {
            printf("LibElf.setFilename(dir = '%s', filename = '%s')\n",
                dir ? dir : "", filename ? filename : "");
        }
        const(char)* arg = filename;
        if (!arg || !*arg)
        {
            // Generate lib file name from first obj name
            const(char)* n = (*global.params.objfiles)[0];

            n = FileName.name(n);
            arg = FileName.forceExt(n, global.lib_ext);
        }
        if (!FileName.absolute(arg))
            arg = FileName.combine(dir, arg);
        const(char)* libfilename = FileName.defaultExt(arg, global.lib_ext);

        libfile = File.create(libfilename);

        loc.filename = libfile.name.toChars();
        loc.linnum = 0;
    }

    /***************************************
     * Add object module or library to the library.
     * Examine the buffer to see which it is.
     * If the buffer is null, use module_name as the file name
     * and load the file.
     */
    void addObject(const(char)* module_name, void* buf, size_t buflen)
    {
        if (!module_name)
            module_name = "";
        static if (LOG)
        {
            printf("LibElf.addObject(%s)\n", module_name);
        }
        int fromfile = 0;
        if (!buf)
        {
            assert(module_name[0]);
            auto file = File(module_name);
            readFile(Loc(), &file);
            buf = file.buffer;
            buflen = file.len;
            file._ref = 1;
            fromfile = 1;
        }
        int reason = 0;

        if (buflen < 16)
        {
            static if (LOG)
            {
                printf("buf = %p, buflen = %d\n", buf, buflen);
            }
        Lcorrupt:
            error(loc, "corrupt object module %s %d", module_name, reason);
            return;
        }

        if (memcmp(buf, cast(const(char)*)"!<arch>\n", 8) == 0)
        {
            /* Library file.
             * Pull each object module out of the library and add it
             * to the object module array.
             */
            static if (LOG)
            {
                printf("archive, buf = %p, buflen = %d\n", buf, buflen);
            }
            uint offset = 8;
            char* symtab = null;
            uint symtab_size = 0;
            char* filenametab = null;
            uint filenametab_size = 0;
            uint mstart = cast(uint)objmodules.length;
            while (offset < buflen)
            {
                if (offset + Header.sizeof >= buflen)
                {
                    reason = __LINE__;
                    goto Lcorrupt;
                }
                Header* header = cast(Header*)(cast(ubyte*)buf + offset);
                offset += Header.sizeof;
                char* endptr = null;
                uint size = cast(uint)strtoul(header.file_size.ptr, &endptr, 10);
                if (endptr >= &header.file_size[10] || *endptr != ' ')
                {
                    reason = __LINE__;
                    goto Lcorrupt;
                }
                if (offset + size > buflen)
                {
                    reason = __LINE__;
                    goto Lcorrupt;
                }

                if (header.object_name[0] == '/' &&
                    header.object_name[1] == ' ')
                {
                    /* Instead of rescanning the object modules we pull from a
                     * library, just use the already created symbol table.
                     */
                    if (symtab)
                    {
                        reason = __LINE__;
                        goto Lcorrupt;
                    }
                    symtab = cast(char*)buf + offset;
                    symtab_size = size;
                    if (size < 4)
                    {
                        reason = __LINE__;
                        goto Lcorrupt;
                    }
                }
                else if (header.object_name[0] == '/' &&
                         header.object_name[1] == '/')
                {
                    /* This is the file name table, save it for later.
                     */
                    if (filenametab)
                    {
                        reason = __LINE__;
                        goto Lcorrupt;
                    }
                    filenametab = cast(char*)buf + offset;
                    filenametab_size = size;
                }
                else
                {
                    ObjModule* om = new ObjModule();
                    om.base = cast(ubyte*)buf + offset /*- Header.sizeof*/;
                    om.length = size;
                    om.offset = 0;
                    if (header.object_name[0] == '/')
                    {
                        /* Pick long name out of file name table
                         */
                        uint foff = cast(uint)strtoul(header.object_name.ptr + 1, &endptr, 10);
                        uint i;
                        for (i = 0; 1; i++)
                        {
                            if (foff + i >= filenametab_size)
                            {
                                reason = 7;
                                goto Lcorrupt;
                            }
                            char c = filenametab[foff + i];
                            if (c == '/')
                                break;
                        }
                        om.name = cast(char*)malloc(i + 1);
                        assert(om.name);
                        memcpy(om.name, filenametab + foff, i);
                        om.name[i] = 0;
                    }
                    else
                    {
                        /* Pick short name out of header
                         */
                        om.name = cast(char*)malloc(OBJECT_NAME_SIZE);
                        assert(om.name);
                        for (int i = 0; 1; i++)
                        {
                            if (i == OBJECT_NAME_SIZE)
                            {
                                reason = __LINE__;
                                goto Lcorrupt;
                            }
                            char c = header.object_name[i];
                            if (c == '/')
                            {
                                om.name[i] = 0;
                                break;
                            }
                            om.name[i] = c;
                        }
                    }
                    om.name_offset = -1;
                    om.file_time = strtoul(header.file_time.ptr, &endptr, 10);
                    om.user_id   = cast(uint)strtoul(header.user_id.ptr, &endptr, 10);
                    om.group_id  = cast(uint)strtoul(header.group_id.ptr, &endptr, 10);
                    om.file_mode = cast(uint)strtoul(header.file_mode.ptr, &endptr, 8);
                    om.scan = 0;                   // don't scan object module for symbols
                    objmodules ~= om;
                }
                offset += (size + 1) & ~1;
            }
            if (offset != buflen)
            {
                reason = __LINE__;
                goto Lcorrupt;
            }

            /* Scan the library's symbol table, and insert it into our own.
             * We use this instead of rescanning the object module, because
             * the library's creator may have a different idea of what symbols
             * go into the symbol table than we do.
             * This is also probably faster.
             */
            uint nsymbols = sgetl(symtab);
            char* s = symtab + 4 + nsymbols * 4;
            if (4 + nsymbols * (4 + 1) > symtab_size)
            {
                reason = __LINE__;
                goto Lcorrupt;
            }
            for (uint i = 0; i < nsymbols; i++)
            {
                char* name = s;
                s += strlen(name) + 1;
                if (s - symtab > symtab_size)
                {
                    reason = __LINE__;
                    goto Lcorrupt;
                }
                uint moff = sgetl(symtab + 4 + i * 4);
    //printf("symtab[%d] moff = %x  %x, name = %s\n", i, moff, moff + Header.sizeof, name);
                for (uint m = mstart; 1; m++)
                {
                    if (m == objmodules.length)
                    {
                        reason = __LINE__;
                        goto Lcorrupt;              // didn't find it
                    }
                    ObjModule* om = objmodules[m];
    //printf("\t%x\n", cast(char*)om.base - cast(char*)buf);
                    if (moff + Header.sizeof == cast(char*)om.base - cast(char*)buf)
                    {
                        addSymbol(om, name, 1);
    //                  if (mstart == m)
    //                      mstart++;
                        break;
                    }
                }
            }

            return;
        }

        /* It's an object module
         */
        ObjModule* om = new ObjModule();
        om.base = cast(ubyte*)buf;
        om.length = cast(uint)buflen;
        om.offset = 0;
        om.name = cast(char*)FileName.name(module_name);     // remove path, but not extension
        om.name_offset = -1;
        om.scan = 1;
        if (fromfile)
        {
            stat_t statbuf;
            int i = stat(module_name, &statbuf);
            if (i == -1)            // error, errno is set
            {
                reason = __LINE__;
                goto Lcorrupt;
            }
            om.file_time = statbuf.st_ctime;
            om.user_id   = statbuf.st_uid;
            om.group_id  = statbuf.st_gid;
            om.file_mode = statbuf.st_mode;
        }
        else
        {
            /* Mock things up for the object module file that never was
             * actually written out.
             */
            static __gshared uid_t uid;
            static __gshared gid_t gid;
            static __gshared int init;
            if (!init)
            {   init = 1;
                uid = getuid();
                gid = getgid();
            }
            time(&om.file_time);
            om.user_id = uid;
            om.group_id = gid;
            om.file_mode = 0100640;
        }
        objmodules ~= om;
    }

    void addLibrary(void* buf, size_t buflen)
    {
        addObject(null, buf, buflen);
    }

    void write()
    {
        if (global.params.verbose)
            fprintf(global.stdmsg, "library   %s\n", libfile.name.toChars());

        OutBuffer libbuf;
        WriteLibToBuffer(&libbuf);

        // Transfer image to file
        libfile.setbuffer(libbuf.data, libbuf.offset);
        libbuf.extractData();

        ensurePathToNameExists(Loc(), libfile.name.toChars());

        writeFile(Loc(), libfile);
    }

    void addSymbol(ObjModule* om, char* name, int pickAny = 0)
    {
        static if (LOG)
        {
            printf("LibElf.addSymbol(%s, %s, %d)\n", om.name, name, pickAny);
        }
        StringValue *s = tab.insert(name, strlen(name));
        if (!s)
        {
            // already in table
            if (!pickAny)
            {
                s = tab.lookup(name, strlen(name));
                assert(s);
                ObjSymbol* os = cast(ObjSymbol*)s.ptrvalue;
                error(loc, "multiple definition of %s: %s and %s: %s",
                    om.name, name, os.om.name, os.name);
            }
        }
        else
        {
            ObjSymbol* os = new ObjSymbol();
            os.name = strdup(name);
            os.om = om;
            s.ptrvalue = cast(void*)os;

            objsymbols ~= os;
        }
    }

  private:
    /************************************
     * Scan single object module for dictionary symbols.
     * Send those symbols to LibElf.addSymbol().
     */
    void scanObjModule(ObjModule* om)
    {
        static if (LOG)
        {
            printf("LibElf.scanObjModule(%s)\n", om.name);
        }

        void addSymbol(char* name, int pickAny)
        {
            this.addSymbol(om, name, pickAny);
        }

        scanElfObjModule(&addSymbol, om.base, om.length, om.name, loc);
    }

    /**********************************************
     * Create and write library to libbuf.
     * The library consists of:
     *      !<arch>\n
     *      header
     *      dictionary
     *      object modules...
     */
    void WriteLibToBuffer(OutBuffer* libbuf)
    {
        static if (LOG)
        {
            printf("LibElf.WriteLibToBuffer()\n");
        }

        /************* Scan Object Modules for Symbols ******************/

        foreach(om; objmodules)
        {
            if (om.scan)
            {
                scanObjModule(om);
            }
        }

        /************* Determine string section ******************/

        /* The string section is where we store long file names.
         */
        uint noffset = 0;
        foreach(om; objmodules)
        {
            size_t len = strlen(om.name);
            if (len >= OBJECT_NAME_SIZE)
            {
                om.name_offset = noffset;
                noffset += len + 2;
            }
            else
                om.name_offset = -1;
        }

        static if (LOG)
        {
            printf("\tnoffset = x%x\n", noffset);
        }

        /************* Determine module offsets ******************/

        uint moffset = 8 + Header.sizeof + 4;

        foreach(os; objsymbols)
        {
            moffset += 4 + strlen(os.name) + 1;
        }
        uint hoffset = moffset;

        static if (LOG)
        {
            printf("\tmoffset = x%x\n", moffset);
        }

        moffset += moffset & 1;
        if (noffset)
             moffset += Header.sizeof + noffset;

        foreach(om; objmodules)
        {
            moffset += moffset & 1;
            om.offset = moffset;
            moffset += Header.sizeof + om.length;
        }

        libbuf.reserve(moffset);

        /************* Write the library ******************/
        libbuf.write(cast(const(char)*)"!<arch>\n", 8);

        ObjModule om;
        om.name_offset = -1;
        om.base = null;
        om.length = cast(uint)(hoffset - (8 + Header.sizeof));
        om.offset = 8;
        om.name = cast(char*)"";
        .time(&om.file_time);
        om.user_id = 0;
        om.group_id = 0;
        om.file_mode = 0;

        Header h;
        OmToHeader(&h, &om);
        libbuf.write(&h, h.sizeof);
        char[4] buf;
        sputl(cast(int)objsymbols.length, buf.ptr);
        libbuf.write(buf.ptr, 4);

        foreach(os; objsymbols)
        {
            sputl(os.om.offset, buf.ptr);
            libbuf.write(buf.ptr, 4);
        }

        foreach(os; objsymbols)
        {
            libbuf.writestring(os.name);
            libbuf.writeByte(0);
        }

        static if (LOG)
        {
            printf("\tlibbuf.moffset = x%x\n", libbuf.offset);
        }

        /* Write out the string section
         */
        if (noffset)
        {
            if (libbuf.offset & 1)
                libbuf.writeByte('\n');

            // header
            memset(&h, ' ', Header.sizeof);
            h.object_name[0] = '/';
            h.object_name[1] = '/';
            size_t len = sprintf(h.file_size.ptr, "%u", noffset);
            assert(len < 10);
            h.file_size[len] = ' ';
            h.trailer[0] = '`';
            h.trailer[1] = '\n';
            libbuf.write(&h, h.sizeof);

            foreach(om2; objmodules)
            {
                if (om2.name_offset >= 0)
                {
                    libbuf.writestring(om2.name);
                    libbuf.writeByte('/');
                    libbuf.writeByte('\n');
                }
            }
        }

        /* Write out each of the object modules
         */
        foreach(om2; objmodules)
        {
            if (libbuf.offset & 1)
                libbuf.writeByte('\n');    // module alignment

            assert(libbuf.offset == om2.offset);

            OmToHeader(&h, om2);
            libbuf.write(&h, h.sizeof);   // module header

            libbuf.write(om2.base, om2.length);    // module contents
        }

        static if (LOG)
        {
            printf("moffset = x%x, libbuf.offset = x%x\n", moffset, libbuf.offset);
        }
        assert(libbuf.offset == moffset);
    }

    Loc loc;
};

extern(C++)
Library LibElf_factory()
{
    return new LibElf();
}

/*****************************************************************************/

void sputl(int value, void* buffer)
{
    ubyte* p = cast(ubyte*)buffer;
    p[0] = cast(ubyte)(value >> 24);
    p[1] = cast(ubyte)(value >> 16);
    p[2] = cast(ubyte)(value >> 8);
    p[3] = cast(ubyte)(value);
}

int sgetl(void* buffer)
{
    ubyte* p = cast(ubyte*)buffer;
    return (((((p[0] << 8) | p[1]) << 8) | p[2]) << 8) | p[3];
}


struct ObjModule
{
    ubyte* base;       // where are we holding it in memory
    uint length;       // in bytes
    uint offset;       // offset from start of library
    char* name;        // module name (file name)
    int name_offset;   // if not -1, offset into string table of name
    time_t file_time;  // file time
    uint user_id;
    uint group_id;
    uint file_mode;
    int scan;          // 1 means scan for symbols
};

enum OBJECT_NAME_SIZE = 16;
struct Header
{
    char[OBJECT_NAME_SIZE] object_name;
    char[12] file_time;
    char[6] user_id;
    char[6] group_id;
    char[8] file_mode;          // in octal
    char[10] file_size;
    char[2] trailer;
};

void OmToHeader(Header* h, ObjModule* om)
{
    size_t len;
    if (om.name_offset == -1)
    {
        len = strlen(om.name);
        memcpy(h.object_name.ptr, om.name, len);
        h.object_name[len] = '/';
    }
    else
    {
        len = sprintf(h.object_name.ptr, "/%d", om.name_offset);
        h.object_name[len] = ' ';
    }
    assert(len < OBJECT_NAME_SIZE);
    memset(h.object_name.ptr + len + 1, ' ', OBJECT_NAME_SIZE - (len + 1));

    /* In the following sprintf's, don't worry if the trailing 0
     * that sprintf writes goes off the end of the field. It will
     * write into the next field, which we will promptly overwrite
     * anyway. (So make sure to write the fields in ascending order.)
     */
    len = sprintf(h.file_time.ptr, "%llu", cast(long)om.file_time);
    assert(len <= 12);
    memset(h.file_time.ptr + len, ' ', 12 - len);

    if (om.user_id > 999999)
        om.user_id = 0;
    len = sprintf(h.user_id.ptr, "%u", om.user_id);
    assert(len <= 6);
    memset(h.user_id.ptr + len, ' ', 6 - len);

    len = sprintf(h.group_id.ptr, "%u", om.group_id);
    assert(len <= 6);
    memset(h.group_id.ptr + len, ' ', 6 - len);

    len = sprintf(h.file_mode.ptr, "%o", om.file_mode);
    assert(len <= 8);
    memset(h.file_mode.ptr + len, ' ', 8 - len);

    len = sprintf(h.file_size.ptr, "%u", om.length);
    assert(len <= 10);
    memset(h.file_size.ptr + len, ' ', 10 - len);

    h.trailer[0] = '`';
    h.trailer[1] = '\n';
}