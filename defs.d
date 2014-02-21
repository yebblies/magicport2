
// c library

public import core.stdc.stdarg;
public import core.stdc.stdio : printf, sprintf, fprintf, vprintf, fputs, fwrite, putchar, remove, fflush, stdout, stderr, FILE, fread, ferror, feof, L_tmpnam, perror;
public import core.stdc.stdlib : alloca, exit, EXIT_FAILURE, EXIT_SUCCESS, strtol, strtoull, getenv, malloc, calloc, free;
public import core.stdc.ctype : isspace, isdigit, isalnum, isprint, isalpha, isxdigit, islower, tolower, toupper;
public import core.stdc.errno : errno, EEXIST, ERANGE;
public import core.stdc.limits : INT_MAX;
public import core.stdc.math : sinl, cosl, tanl, sqrtl, fabsl;
public import core.stdc.time : time_t, ctime, time;
public import core.stdc.stdint : int64_t, uint64_t, int32_t, uint32_t, int16_t, uint16_t, int8_t, uint8_t;
public import core.stdc.float_;

private import core.stdc.string : strcmp, strlen, strncmp, strchr, memset, memmove, strdup, strcpy, strcat, xmemcmp = memcmp, memcpy, strrchr, strstr;

private import core.memory;

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
    public import core.sys.windows.windows;
    alias GetModuleFileNameA GetModuleFileName;
    alias CreateFileA CreateFile;
    alias CreateFileMappingA CreateFileMapping;
    alias WIN32_FIND_DATA WIN32_FIND_DATAA;
    extern(Windows) DWORD GetFullPathNameA(LPCTSTR lpFileName, DWORD nBufferLength, LPTSTR lpBuffer, LPTSTR *lpFilePart);
    alias GetFullPathNameA GetFullPathName;

    extern(C) int mkdir(const char*);
    alias mkdir _mkdir;
}
else version(Posix)
{
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

// c lib

// So we can accept string literals
int memcmp(const char* a, const char* b, size_t len) { return .xmemcmp(a, b, len); }
int memcmp(const void* a, const void* b, size_t len) { return .xmemcmp(a, b, len); }

// Not defined for some reason
extern(C) int stricmp(const char*, const char*);
extern(C) int putenv(const char*);
extern(C) int spawnlp(int, const char*, const char*, const char*, const char*);
extern(C) int spawnl(int, const char*, const char*, const char*, const char*);
extern(C) int spawnv(int, const char*, const char**);

// Backend

struct Symbol;
struct TYPE;
alias TYPE type;
struct elem;
struct code;
struct block;
struct dt_t;
struct IRState;

extern extern(C++) void backend_init();
extern extern(C++) void backend_term();
extern extern(C++) void obj_start(char *srcfile);
extern extern(C++) void obj_end(Library library, File* objfile);
extern extern(C++) void obj_write_deferred(Library library);
extern extern(C++) Expression createTypeInfoArray(Scope* sc, Expression *args, size_t dim);
extern extern(C++) dt_t** Expression_toDt(Expression e, dt_t** pdt);
extern extern(C++) elem* toElem(Expression e, IRState *irs);
extern extern(C++) RET retStyle(TypeFunction tf);
extern extern(C++) Statement asmSemantic(AsmStatement s, Scope *sc);

uint rol(uint x, uint n)
{
    return (x << n) | (x >> (32-n));
}
uint ror(uint x, uint n)
{
    return (x >> n) | (x << (32-n));
}

int main(string[] args)
{
    scope(failure) tracedepth = -1;
    GC.disable();

    int argc = cast(int)args.length;
    auto argv = (new const(char)*[](argc)).ptr;
    foreach(i, a; args)
        argv[i] = (a ~ '\0').ptr;

    return tryMain(argc, argv);
}

__gshared int tracedepth;

// version=trace;
// version=fulltrace;

version(trace)
{
    enum dmd_trace_code = "tracein(); scope(success) traceout(); scope(failure) traceerr();";
    void trace(string pretty = __PRETTY_FUNCTION__, size_t line = __LINE__)
    {
        printf("%.*s:%d\n", pretty.length, pretty.ptr, line);
    }
    void tracein(string pretty = __PRETTY_FUNCTION__, size_t line = __LINE__)
    {
        if (tracedepth < 0)
            return;
        version(fulltrace)
        {
            foreach(i; 0..tracedepth*2)
                putchar(' ');
            printf("+ %.*s:%d\n", pretty.length, pretty.ptr, line);
        }
        tracedepth++;
    }

    void traceout(string pretty = __PRETTY_FUNCTION__, size_t line = __LINE__)
    {
        if (tracedepth < 0)
            return;
        tracedepth--;
        version(fulltrace)
        {
            foreach(i; 0..tracedepth*2)
                putchar(' ');
            printf("- %.*s:%d\n", pretty.length, pretty.ptr, line);
        }
    }

    void traceerr(string pretty = __PRETTY_FUNCTION__, size_t line = __LINE__)
    {
        if (tracedepth < 0)
            return;
        tracedepth--;
        foreach(i; 0..tracedepth*2)
            putchar(' ');
        printf("! %.*s:%d\n", pretty.length, pretty.ptr, line);
    }
}
else
{
    enum dmd_trace_code = "";
    void trace(string pretty = __PRETTY_FUNCTION__, size_t line = __LINE__) {}
    void tracein(string pretty = __PRETTY_FUNCTION__, size_t line = __LINE__) {}
    void traceout(string pretty = __PRETTY_FUNCTION__, size_t line = __LINE__) {}
    void traceerr(string pretty = __PRETTY_FUNCTION__, size_t line = __LINE__) {}
}

// Preprocessor symbols (sometimes used as values)
template xversion(string s)
{
    enum xversion = mixin("{ version(" ~ s ~ ") return true; else return false; }")();
}

enum DDMD = true;

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
enum TARGET_WINDOS = xversion!"Windows";;
