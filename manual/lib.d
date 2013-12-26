
// Compiler implementation of the D programming language
// Copyright (c) 1999-2012 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module lib;

import defs, mars;

extern extern(C++) Library LibMSCoff_factory();
extern extern(C++) Library LibOMF_factory();
extern extern(C++) Library LibElf_factory();
extern extern(C++) Library LibMach_factory();

extern(C++)
class Library
{
public:
    static Library factory()
    {
        static if (TARGET_WINDOS)
            return global.params.is64bit ? LibMSCoff_factory() : LibOMF_factory();
        else static if (TARGET_LINUX || TARGET_FREEBSD || TARGET_OPENBSD || TARGET_SOLARIS)
            return LibElf_factory();
        else static if (TARGET_OSX)
            return LibMach_factory();
        else
            assert(0, "fix this");
    }

    abstract void setFilename(const(char)* dir, const(char)* filename);
    abstract void addObject(const(char)* module_name, void* buf, size_t buflen);
    abstract void addLibrary(void* buf, size_t buflen);
    abstract void write();
};
