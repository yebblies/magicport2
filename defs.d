
// generated source

import mars;
import lib;
import root.file;
import expression;
import dscope;
import mtype;
import statement;

// win32

version(Windows)
{
    private import core.sys.windows.windows;
    extern(Windows) DWORD GetFullPathNameA(LPCTSTR lpFileName, DWORD nBufferLength, LPTSTR lpBuffer, LPTSTR *lpFilePart);
    alias WIN32_FIND_DATA WIN32_FIND_DATAA;

    extern(C) int mkdir(const char*);
    alias mkdir _mkdir;
}
else version(Posix)
{
    import core.stdc.stdio;
    public import core.sys.posix.sys.stat : stat_t, stat, S_ISDIR;
    public import core.sys.posix.fcntl : fstat, open, O_RDONLY, O_CREAT, O_WRONLY, O_TRUNC;
    public import core.sys.posix.unistd : read, close, write, pid_t, fork, dup2, STDERR_FILENO, execvp, execv;
    public import core.sys.posix.utime : utime, utimbuf;
    public import core.sys.posix.sys.types : off_t, ssize_t;
    public import core.sys.posix.stdio : P_tmpdir;
    public import core.sys.posix.stdlib : mkstemp, realpath;
    public import core.sys.posix.sys.wait : waitpid, WIFEXITED, WEXITSTATUS, WIFSIGNALED, WTERMSIG;

    extern(C) int mkdir(const char*, int);
    extern(C) char *canonicalize_file_name(const char*);
    extern(C) FILE* fdopen(int, const char*);
    extern(C) int pipe(int *);
}
else
    static assert(0);

// Not defined for some reason
extern(C) int stricmp(const char*, const char*);
extern(C) int putenv(const char*);
extern(C) int spawnlp(int, const char*, const char*, const char*, const char*);
extern(C) int spawnl(int, const char*, const char*, const char*, const char*);
extern(C) int spawnv(int, const char*, const char**);

uint rol(uint x, uint n)
{
    return (x << n) | (x >> (32-n));
}
uint ror(uint x, uint n)
{
    return (x >> n) | (x << (32-n));
}

int main()
{
    import core.runtime;
    auto args = Runtime.cArgs();
    return tryMain(args.argc, cast(const(char)**)args.argv);
}

// Preprocessor symbols (sometimes used as values)
template xversion(string s)
{
    enum xversion = mixin("{ version(" ~ s ~ ") return true; else return false; }")();
}

enum __linux__ = xversion!"linux";
enum linux = xversion!"linux";
enum __APPLE__ = xversion!"OSX";
enum __FreeBSD__ = xversion!"FreeBSD";
enum __OpenBSD__ = xversion!"OpenBSD";
enum __sun = xversion!"Solaris";

enum IN_GCC = xversion!"GNU";
enum __DMC__ = xversion!"DigitalMars";
enum _MSC_VER = false;
enum __clang__ = false;
enum __GNUC__ = false;
enum __MINGW32__ = false;
enum __GLIBC__ = xversion!"linux";

enum LOG = false;
enum ASYNCREAD = false;
enum CANINLINE_LOG = false;
enum LOGSEMANTIC = false;

enum TARGET_LINUX = xversion!"linux";
enum TARGET_OSX = xversion!"OSX";
enum TARGET_FREEBSD = xversion!"FreeBSD";
enum TARGET_OPENBSD = xversion!"OpenBSD";
enum TARGET_SOLARIS = xversion!"Solaris";
enum TARGET_WINDOS = xversion!"Windows";
