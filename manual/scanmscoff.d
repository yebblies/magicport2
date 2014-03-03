
// Compiler implementation of the D programming language
// Copyright (c) 1999-2012 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

/* Implements scanning an object module for names to go in the library table of contents.
 * The object module format is MS-COFF.
 * This format is described in the Microsoft document
 * "Microsoft Portable Executable and Common Object File Format Specification"
 * Revision 8.2 September 21, 2010
 */

module scanmscoff;

import core.stdc.string;
import mars, lib;

static if (TARGET_WINDOS):

enum LOG = 0;

/*****************************************
 * Reads an object module from base[0..buflen] and passes the names
 * of any exported symbols to (*pAddSymbol)().
 * Input:
 *      pctx            context pointer, pass to *pAddSymbol
 *      pAddSymbol      function to pass the names to
 *      base[0..buflen] contains contents of object module
 *      module_name     name of the object module (used for error messages)
 *      loc             location to use for error printing
 */

void scanMSCoffObjModule(void delegate(char* name, int pickAny) pAddSymbol, void* base, size_t buflen, const(char)* module_name, Loc loc)
{
    static if (LOG)
        printf("scanMSCoffObjModule(%s)\n", module_name);

    ubyte* buf = cast(ubyte*)base;
    int reason;

    /* First do sanity checks on object file
     */
    if (buflen < filehdr.sizeof)
    {
        reason = __LINE__;
    Lcorrupt:
        error(loc, "MS-Coff object module %s is corrupt, %d", module_name, reason);
        return;
    }

    filehdr* header = cast(filehdr*)buf;

    switch (header.f_magic)
    {
    case IMAGE_FILE_MACHINE_UNKNOWN:
    case IMAGE_FILE_MACHINE_I386:
    case IMAGE_FILE_MACHINE_AMD64:
        break;

    default:
        if (buf[0] == 0x80)
            error(loc, "Object module %s is 32 bit OMF, but it should be 64 bit MS-Coff",
                    module_name);
        else
            error(loc, "MS-Coff object module %s has magic = %x, should be %x",
                    module_name, header.f_magic, IMAGE_FILE_MACHINE_AMD64);
        return;
    }

    // Get string table:  string_table[0..string_len]
    size_t off = header.f_symptr;
    if (off == 0)
    {
        error(loc, "MS-Coff object module %s has no string table", module_name);
        return;
    }
    off += header.f_nsyms * syment.sizeof;
    if (off + 4 > buflen)
    {
        reason = __LINE__;
        goto Lcorrupt;
    }
    uint string_len = *cast(uint*)(buf + off);
    char* string_table = cast(char*)(buf + off + 4);
    if (off + string_len > buflen)
    {
        reason = __LINE__;
        goto Lcorrupt;
    }
    string_len -= 4;

    for (int i = 0; i < header.f_nsyms; i++)
    {
        syment *n;
        char[8 + 1] s;
        char *p;

        static if (LOG)
            printf("Symbol %d:\n",i);
        off = header.f_symptr + i * (*n).sizeof;
        if (off > buflen)
        {
            reason = __LINE__;
            goto Lcorrupt;
        }
        n = cast(syment*)(buf + off);
        if (n.n_zeroes)
        {
            strncpy(s.ptr,n.n_name.ptr,8);
            s[SYMNMLEN] = 0;
            p = s.ptr;
        }
        else
            p = string_table + n.n_offset - 4;
        i += n.n_numaux;
        static if (LOG)
        {
            printf("n_name    = '%s'\n",p);
            printf("n_value   = x%08lx\n",n.n_value);
            printf("n_scnum   = %d\n", n.n_scnum);
            printf("n_type    = x%04x\n",n.n_type);
            printf("n_sclass  = %d\n", n.n_sclass);
            printf("n_numaux  = %d\n",n.n_numaux);
        }
        switch (n.n_scnum)
        {
        case IMAGE_SYM_DEBUG:
            continue;
        case IMAGE_SYM_ABSOLUTE:
            if (strcmp(p, "@comp.id") == 0)
                continue;
            break;
        case IMAGE_SYM_UNDEFINED:
            // A non-zero value indicates a common block
            if (n.n_value)
                break;
            continue;

        default:
            break;
        }
        switch (n.n_sclass)
        {
        case IMAGE_SYM_CLASS_EXTERNAL:
            break;
        case IMAGE_SYM_CLASS_STATIC:
            if (n.n_value == 0)            // if it's a section name
                continue;
            continue;
        case IMAGE_SYM_CLASS_FUNCTION:
        case IMAGE_SYM_CLASS_FILE:
        case IMAGE_SYM_CLASS_LABEL:
            continue;
        default:
            continue;
        }
        pAddSymbol(p, 1);
    }
}

enum IMAGE_FILE_MACHINE_UNKNOWN = 0;            // applies to any machine type
enum IMAGE_FILE_MACHINE_I386    = 0x14C;        // x86
enum IMAGE_FILE_MACHINE_AMD64   = 0x8664;       // x86_64

enum IMAGE_FILE_RELOCS_STRIPPED            = 1;
enum IMAGE_FILE_EXECUTABLE_IMAGE           = 2;
enum IMAGE_FILE_LINE_NUMS_STRIPPED         = 4;
enum IMAGE_FILE_LOCAL_SYMS_STRIPPED        = 8;
enum IMAGE_FILE_AGGRESSIVE_WS_TRIM         = 0x10;
enum IMAGE_FILE_LARGE_ADDRESS_AWARE        = 0x20;
enum IMAGE_FILE_BYTES_REVERSED_LO          = 0x80;
enum IMAGE_FILE_32BIT_MACHINE              = 0x100;
enum IMAGE_FILE_DEBUG_STRIPPED             = 0x200;
enum IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP    = 0x400;
enum IMAGE_FILE_NET_RUN_FROM_SWAP          = 0x800;
enum IMAGE_FILE_SYSTEM                     = 0x1000;
enum IMAGE_FILE_DLL                        = 0x2000;
enum IMAGE_FILE_UP_SYSTEM_ONLY             = 0x4000;
enum IMAGE_FILE_BYTES_REVERSED_HI          = 0x8000;

struct filehdr
{
align(1):
    ushort f_magic; // identifies type of target machine
    ushort f_nscns; // number of sections (96 is max)
    int f_timdat;        // creation date, number of seconds since 1970
    int f_symptr;          // file offset of symbol table
    int f_nsyms;           // number of entried in the symbol table
    ushort f_opthdr; // optional header size (0)
    ushort f_flags;
};

/***********************************************/

enum SYMNMLEN        = 8;

enum IMAGE_SYM_DEBUG               = -2;
enum IMAGE_SYM_ABSOLUTE            = -1;
enum IMAGE_SYM_UNDEFINED           = 0;

/* Values for n_sclass  */
enum IMAGE_SYM_CLASS_EXTERNAL      = 2;
enum IMAGE_SYM_CLASS_STATIC        = 3;
enum IMAGE_SYM_CLASS_LABEL         = 6;
enum IMAGE_SYM_CLASS_FUNCTION      = 101;
enum IMAGE_SYM_CLASS_FILE          = 103;

struct syment
{
align(1):
    union
    {
        char n_name[SYMNMLEN];
        struct
        {
            int n_zeroes;
            int n_offset;
        }
    }

    uint n_value;
    short n_scnum;
    ushort n_type;      // 0x20 function; 0x00 not a function
    ubyte n_sclass;
    ubyte n_numaux;
};

