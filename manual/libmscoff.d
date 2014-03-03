
// Compiler implementation of the D programming language
// Copyright (c) 1999-2012 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

/* Implements object library reading and writing in the MS-COFF object
 * module format.
 * This format is described in the Microsoft document
 * "Microsoft Portable Executable and Common Object File Format Specification"
 * Revision 8.2 September 21, 2010
 * chapter 6 "Archive (Library) File Format"
 */

module libmscoff;

import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;
import core.stdc.time;

import root.file, root.filename, root.outbuffer, root.stringtable;
import mars, lib, scanmscoff;

static if (TARGET_WINDOS):

enum LOG = false;

struct ObjSymbol
{
    char* name;
    ObjModule* om;
};

/*********
 * Do lexical comparison of ObjSymbol's for qsort()
 */
extern(C)
int ObjSymbol_cmp(const void* p, const void* q)
{
    ObjSymbol* s1 = *cast(ObjSymbol**)p;
    ObjSymbol* s2 = *cast(ObjSymbol**)q;
    return strcmp(s1.name, s2.name);
}

extern(C++)
class LibMSCoff : Library
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
            printf("LibMSCoff.setFilename(dir = '%s', filename = '%s')\n",
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
    void addObject(const(char)* module_name, void *buf, size_t buflen)
    {
        if (!module_name)
            module_name = "";
        static if (LOG)
        {
            printf("LibMSCoff.addObject(%s)\n", module_name);
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
                printf("buf = %p, buflen = %d\n", buf, buflen);
        Lcorrupt:
            error(loc, "corrupt object module %s %d", module_name, reason);
            exit(EXIT_FAILURE);
        }

        if (memcmp(cast(char*)buf, cast(char*)"!<arch>\n", 8) == 0)
        {
            /* It's a library file.
             * Pull each object module out of the library and add it
             * to the object module array.
             */
            static if (LOG)
                printf("archive, buf = %p, buflen = %d\n", buf, buflen);
            Header* flm = null;     // first linker member

            Header* slm = null;     // second linker member
            uint number_of_members = 0;
            uint* member_file_offsets = null;
            uint number_of_symbols = 0;
            ushort* indices = null;
            char* string_table = null;
            size_t string_table_length = 0;

            Header* lnm = null;     // longname member
            char* longnames = null;
            size_t longnames_length = 0;

            size_t offset = 8;
            char* symtab = null;
            uint symtab_size = 0;
            size_t mstart = objmodules.length;
            while (1)
            {
                offset = (offset + 1) & ~1;         // round to even boundary
                if (offset >= buflen)
                    break;
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

                //printf("header.object_name = '%.*s'\n", OBJECT_NAME_SIZE, header.object_name);

                if (memcmp(header.object_name.ptr, cast(char*)"/               ", OBJECT_NAME_SIZE) == 0)
                {
                    if (!flm)
                    {
                        // First Linker Member, which is ignored
                        flm = header;
                    }
                    else if (!slm)
                    {
                        // Second Linker Member, which we require even though the format doesn't require it
                        slm = header;
                        if (size < 4 + 4)
                        {
                            reason = __LINE__;
                            goto Lcorrupt;
                        }
                        number_of_members = sgetl(cast(char*)buf + offset);
                        member_file_offsets = cast(uint*)(cast(char* )buf + offset + 4);
                        if (size < 4 + number_of_members * 4 + 4)
                        {
                            reason = __LINE__;
                            goto Lcorrupt;
                        }
                        number_of_symbols = sgetl(cast(char*)buf + offset + 4 + number_of_members * 4);
                        indices = cast(ushort*)(cast(char*)buf + offset + 4 + number_of_members * 4 + 4);
                        string_table = cast(char*)(cast(char*)buf + offset + 4 + number_of_members * 4 + 4 + number_of_symbols * 2);
                        if (size <= (4 + number_of_members * 4 + 4 + number_of_symbols * 2))
                        {
                            reason = __LINE__;
                            goto Lcorrupt;
                        }
                        string_table_length = size - (4 + number_of_members * 4 + 4 + number_of_symbols * 2);

                        /* The number of strings in the string_table must be number_of_symbols; check it
                         * The strings must also be in ascending lexical order; not checked.
                         */
                        size_t i = 0;
                        for (uint n = 0; n < number_of_symbols; n++)
                        {
                            while (1)
                            {
                                if (i >= string_table_length)
                                {
                                    reason = __LINE__;
                                    goto Lcorrupt;
                                }
                                if (!string_table[i++])
                                    break;
                            }
                        }
                        if (i != string_table_length)
                        {
                            reason = __LINE__;
                            goto Lcorrupt;
                        }
                    }
                }
                else if (memcmp(header.object_name.ptr, cast(char*)"//              ", OBJECT_NAME_SIZE) == 0)
                {
                    if (!lnm)
                    {
                        lnm = header;
                        longnames = cast(char*)buf + offset;
                        longnames_length = size;
                    }
                }
                else
                {
                    if (!slm)
                    {
                        reason = __LINE__;
                        goto Lcorrupt;
                    }
                    // Microsoft Spec says longnames member must appear, but Microsoft Lib says otherwise
                    // if (!lnm)
                    // {   reason = __LINE__;
                        // goto Lcorrupt;
                    // }

                    ObjModule* om = new ObjModule();
                    // Include Header in base[0..length], so we don't have to repro it
                    om.base = cast(ubyte*)buf + offset - Header.sizeof;
                    om.length = cast(uint)(size + Header.sizeof);
                    om.offset = 0;
                    if (header.object_name[0] == '/')
                    {
                        /* Pick long name out of longnames[]
                         */
                        uint foff = cast(uint)strtoul(header.object_name.ptr + 1, &endptr, 10);
                        uint i;
                        for (i = 0; 1; i++)
                        {
                            if (foff + i >= longnames_length)
                            {
                                reason = __LINE__;
                                goto Lcorrupt;
                            }
                            char c = longnames[foff + i];
                            if (c == 0)
                                break;
                        }
                        char* oname = cast(char*)malloc(i + 1);
                        assert(oname);
                        memcpy(oname, longnames + foff, i);
                        oname[i] = 0;
                        om.name = oname;
                        //printf("\tname = '%s'\n", om.name);
                    }
                    else
                    {
                        /* Pick short name out of header
                         */
                        char* oname = cast(char*)malloc(OBJECT_NAME_SIZE);
                        assert(oname);
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
                                oname[i] = 0;
                                break;
                            }
                            oname[i] = c;
                        }
                        om.name = oname;
                    }
                    om.file_time = cast(int)strtoul(header.file_time.ptr, &endptr, 10);
                    om.user_id   = cast(uint)strtoul(header.user_id.ptr, &endptr, 10);
                    om.group_id  = cast(uint)strtoul(header.group_id.ptr, &endptr, 10);
                    om.file_mode = cast(uint)strtoul(header.file_mode.ptr, &endptr, 8);
                    om.scan = 0;                   // don't scan object module for symbols
                    objmodules ~= om;
                }
                offset += size;
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
            if (!slm)
            {
                reason = __LINE__;
                goto Lcorrupt;
            }

            char* s = string_table;
            for (uint i = 0; i < number_of_symbols; i++)
            {
                char* name = s;
                s += strlen(s) + 1;

                uint memi = indices[i] - 1;
                if (memi >= number_of_members)
                {
                    reason = __LINE__;
                    goto Lcorrupt;
                }
                uint moff = member_file_offsets[memi];
                for (size_t m = mstart; 1; m++)
                {
                    if (m == objmodules.length)
                    {
                        reason = __LINE__;
                        goto Lcorrupt;              // didn't find it
                    }
                    ObjModule* om = objmodules[m];
                    //printf("\tom offset = x%x\n", (char* )om.base - (char* )buf);
                    if (moff == cast(char*)om.base - cast(char*)buf)
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
        om.name = global.params.preservePaths ? module_name : FileName.name(module_name);     // remove path, but not extension
        om.scan = 1;
        if (0 && fromfile)
        {
            // stat_t statbuf;
            // int i = stat(module_name, &statbuf);
            // if (i == -1)            // error, errno is set
            // {
                // reason = 14;
                // goto Lcorrupt;
            // }
            // om.file_time = statbuf.st_ctime;
            // om.user_id   = statbuf.st_uid;
            // om.group_id  = statbuf.st_gid;
            // om.file_mode = statbuf.st_mode;
        }
        else
        {
            /* Mock things up for the object module file that never was
             * actually written out.
             */
            time_t file_time = 0;
            time(&file_time);
            om.file_time = cast(int)file_time;
            om.user_id = 0;                // meaningless on Windows
            om.group_id = 0;               // meaningless on Windows
            om.file_mode = 0100644;
        }
        objmodules ~= om;
    }

    void addLibrary(void *buf, size_t buflen)
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
            printf("LibMSCoff.addSymbol(%s, %s, %d)\n", om.name, name, pickAny);
        ObjSymbol* os = new ObjSymbol();
        os.name = strdup(name);
        os.om = om;
        objsymbols ~= os;
    }

private:
    /************************************
     * Scan single object module for dictionary symbols.
     * Send those symbols to LibMSCoff.addSymbol().
     */
    void scanObjModule(ObjModule* om)
    {
        static if (LOG)
        {
            printf("LibMSCoff.scanObjModule(%s)\n", om.name);
        }

        void addSymbol(char* name, int pickAny)
        {
            this.addSymbol(om, name, pickAny);
        }

        scanMSCoffObjModule(&addSymbol, om.base, om.length, om.name, loc);
    }

    /**********************************************
     * Create and write library to libbuf.
     * The library consists of:
     *      !<arch>\n
     *      header
     *      1st Linker Member
     *      Header
     *      2nd Linker Member
     *      Header
     *      Longnames Member
     *      object modules...
     */
    void WriteLibToBuffer(OutBuffer* libbuf)
    {
        static if (LOG)
            printf("LibElf.WriteLibToBuffer()\n");

        assert(Header.sizeof == 60);

        /************* Scan Object Modules for Symbols ******************/

        foreach(om; objmodules)
        {
            if (om.scan)
            {
                scanObjModule(om);
            }
        }

        /************* Determine longnames size ******************/

        /* The longnames section is where we store long file names.
         */
        uint noffset = 0;
        foreach(om; objmodules)
        {
            size_t len = strlen(om.name);
            if (len >= OBJECT_NAME_SIZE)
            {
                om.name_offset = noffset;
                noffset += len + 1;
            }
            else
                om.name_offset = -1;
        }

        static if (LOG)
            printf("\tnoffset = x%x\n", noffset);

        /************* Determine string table length ******************/

        size_t slength = 0;

        foreach(os; objsymbols)
        {
            slength += strlen(os.name) + 1;
        }

        /************* Offset of first module ***********************/

        size_t moffset = 8;       // signature

        size_t firstLinkerMemberOffset = moffset;
        moffset += Header.sizeof + 4 + objsymbols.length * 4 + slength;       // 1st Linker Member
        moffset += moffset & 1;

        size_t secondLinkerMemberOffset = moffset;
        moffset += Header.sizeof + 4 + objmodules.length * 4 + 4 + objsymbols.length * 2 + slength;
        moffset += moffset & 1;

        size_t LongnamesMemberOffset = moffset;
        moffset += Header.sizeof + noffset;                        // Longnames Member size

        static if (LOG)
            printf("\tmoffset = x%x\n", moffset);

        /************* Offset of each module *************************/

        foreach(om; objmodules)
        {
            moffset += moffset & 1;
            om.offset = cast(uint)moffset;
            if (om.scan)
                moffset += Header.sizeof + om.length;
            else
                moffset += om.length;
        }

        libbuf.reserve(moffset);

        /************* Write the library ******************/
        libbuf.write(cast(const(char)*)"!<arch>\n", 8);

        ObjModule om;
        om.name_offset = -1;
        om.base = null;
        om.length = cast(uint)(4 + objsymbols.length * 4 + slength);
        om.offset = 8;
        om.name = cast(char*)"";
        time_t file_time = 0;
        .time(&file_time);
        om.file_time = cast(int)file_time;
        om.user_id = 0;
        om.group_id = 0;
        om.file_mode = 0;

        /*** Write out First Linker Member ***/

        assert(libbuf.offset == firstLinkerMemberOffset);

        Header h;
        OmToHeader(&h, &om);
        libbuf.write(&h, h.sizeof);

        char buf[4];
        sputl_big(cast(int)objsymbols.length, buf.ptr);
        libbuf.write(buf.ptr, 4);

        // Sort objsymbols[] in module offset order
        qsort(objsymbols.ptr, objsymbols.length, typeof(objsymbols[0]).sizeof, &ObjSymbol_offset_cmp);

        uint lastoffset;
        foreach(i, os; objsymbols)
        {
            //printf("objsymbols[%d] = '%s', offset = %u\n", i, os.name, os.om.offset);
            if (i)
                // Should be sorted in module order
                assert(lastoffset <= os.om.offset);
            lastoffset = os.om.offset;
            sputl_big(lastoffset, buf.ptr);
            libbuf.write(buf.ptr, 4);
        }

        foreach(os; objsymbols)
        {
            libbuf.writestring(os.name);
            libbuf.writeByte(0);
        }

        /*** Write out Second Linker Member ***/

        if (libbuf.offset & 1)
            libbuf.writeByte('\n');

        assert(libbuf.offset == secondLinkerMemberOffset);

        om.length = cast(uint)(4 + objmodules.length * 4 + 4 + objsymbols.length * 2 + slength);
        OmToHeader(&h, &om);
        libbuf.write(&h, h.sizeof);

        sputl(cast(int)objmodules.length, buf.ptr);
        libbuf.write(buf.ptr, 4);

        foreach(i, om2; objmodules)
        {
            om2.index = cast(ushort)i;
            sputl(om2.offset, buf.ptr);
            libbuf.write(buf.ptr, 4);
        }

        sputl(cast(int)objsymbols.length, buf.ptr);
        libbuf.write(buf.ptr, 4);

        // Sort objsymbols[] in lexical order
        qsort(objsymbols.ptr, objsymbols.length, typeof(objsymbols[0]).sizeof, &ObjSymbol_cmp);

        foreach(os; objsymbols)
        {
            sputl(os.om.index + 1, buf.ptr);
            libbuf.write(buf.ptr, 2);
        }

        foreach(os; objsymbols)
        {
            libbuf.writestring(os.name);
            libbuf.writeByte(0);
        }

        /*** Write out longnames Member ***/

        if (libbuf.offset & 1)
            libbuf.writeByte('\n');

        //printf("libbuf %x longnames %x\n", (int)libbuf.offset, (int)LongnamesMemberOffset);
        assert(libbuf.offset == LongnamesMemberOffset);

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
                libbuf.writeByte(0);
            }
        }

        /* Write out each of the object modules
         */
        foreach(om2; objmodules)
        {
            if (libbuf.offset & 1)
                libbuf.writeByte('\n');    // module alignment

            //printf("libbuf %x om %x\n", (int)libbuf.offset, (int)om2.offset);
            assert(libbuf.offset == om2.offset);

            if (om2.scan)
            {
                OmToHeader(&h, om2);
                libbuf.write(&h, h.sizeof);   // module header

                libbuf.write(om2.base, om2.length);    // module contents
            }
            else
            {
                // Header is included in om.base[0..length]
                libbuf.write(om2.base, om2.length);    // module contents
            }
        }

        static if (LOG)
            printf("moffset = x%x, libbuf.offset = x%x\n", cast(uint)moffset, cast(uint)libbuf.offset);
        assert(libbuf.offset == moffset);
    }

    Loc loc;
};

extern(C++) Library LibMSCoff_factory()
{
    return new LibMSCoff();
}

/*****************************************************************************/

// Little endian
void sputl(int value, void* buffer)
{
    ubyte* p = cast(ubyte*)buffer;
    p[3] = cast(ubyte)(value >> 24);
    p[2] = cast(ubyte)(value >> 16);
    p[1] = cast(ubyte)(value >> 8);
    p[0] = cast(ubyte)(value);
}

// Little endian
int sgetl(void* buffer)
{
    ubyte* p = cast(ubyte*)buffer;
    return (((((p[3] << 8) | p[2]) << 8) | p[1]) << 8) | p[0];
}

// Big endian
void sputl_big(int value, void* buffer)
{
    ubyte* p = cast(ubyte*)buffer;
    p[0] = cast(ubyte)(value >> 24);
    p[1] = cast(ubyte)(value >> 16);
    p[2] = cast(ubyte)(value >> 8);
    p[3] = cast(ubyte)(value);
}

// Big endian
int sgetl_big(void* buffer)
{
    ubyte* p = cast(ubyte*)buffer;
    return (((((p[0] << 8) | p[1]) << 8) | p[2]) << 8) | p[3];
}

struct ObjModule
{
    ubyte* base;        // where are we holding it in memory
    uint length;            // in bytes
    uint offset;            // offset from start of library
    ushort index;       // index in Second Linker Member
    const(char)* name;           // module name (file name)
    int name_offset;            // if not -1, offset into string table of name
    int file_time;             // file time
    uint user_id;
    uint group_id;
    uint file_mode;
    int scan;                   // 1 means scan for symbols
};

/*********
 * Do module offset comparison of ObjSymbol's for qsort()
 */
extern(C) int ObjSymbol_offset_cmp(const void* p, const void* q)
{
    ObjSymbol* s1 = *cast(ObjSymbol**)p;
    ObjSymbol* s2 = *cast(ObjSymbol**)q;
    return s1.om.offset - s2.om.offset;
}

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

    // Match what MS tools do (set to all blanks)
    memset(h.user_id.ptr, ' ', h.user_id.sizeof);
    memset(h.group_id.ptr, ' ', h.group_id.sizeof);

    len = sprintf(h.file_mode.ptr, "%o", om.file_mode);
    assert(len <= 8);
    memset(h.file_mode.ptr + len, ' ', 8 - len);

    len = sprintf(h.file_size.ptr, "%u", om.length);
    assert(len <= 10);
    memset(h.file_size.ptr + len, ' ', 10 - len);

    h.trailer[0] = '`';
    h.trailer[1] = '\n';
}
