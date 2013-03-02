
public import core.stdc.stdarg;
public import core.stdc.stdio;
public import core.stdc.stdlib;
import core.stdc.string : strcmp, memcpy, strlen, strncmp, strchr, memcmp, memset, memmove, strdup;
public import core.stdc.ctype;
public import core.stdc.errno;
public import core.stdc.limits;
public import core.sys.windows.windows;

alias GetModuleFileNameA GetModuleFileName;

int memcmp(const char*, const char*, size_t len);
int memcmp(void*, void*, size_t len);
int stricmp(const char*, const char*);
int ld_sprint(const char*, ...);
void __locale_decpoint(const char*);
char* __locale_decpoint();
int putenv(const char*);
int spawnlp(int, const char*, const char*, const char*, const char*);
int spawnl(int, const char*, const char*, const char*, const char*);
int spawnv(int, const char*, const char**);

enum NULL = null;

class _Object
{
    int dyncast()
    {
        assert(0);
    }
    int equals(_Object);
}

struct ArrayBase(U)
{
    static if (!is(U == class))
        alias U* T;
    else
        alias U T;
    void push(T);
    void push(const T);
    void append(typeof(this)*);
    void reserve(size_t);
    void remove(size_t);
    void insert(size_t, typeof(this)*);
    void insert(size_t, T);
    size_t dim();
    void setDim(size_t);
    ref T opIndex(size_t);
    T* tdata();
    typeof(this)* copy();
    void shift(T);
    T* data;
};

struct Mem
{
    void init();
    void* malloc(size_t);
    void free(void*);
    char* strdup(const char*);
    void setStackBottom(void*);
    void addroots(void*, void*);
    void* calloc(size_t, size_t);
}
extern extern(C) uint _xi_a;
extern extern(C) uint _end;

Mem mem;

int response_expand(size_t*, char***);
void browse(const char*);

struct OutBuffer
{
    int vprintf(const char* format, va_list);
    int printf(const char* format, ...);
    void writebyte(int);
    void writeByte(int);
    void writestring(const char*);
    void prependstring(const char*);
    char *toChars();
    char *extractData();
    char *data;
    size_t offset;
    void reset();
    void write(OutBuffer*);
    void write(const char*, size_t);
    void remove(size_t, size_t);
    void reserve(size_t);
    void setsize(size_t);
    size_t insert(size_t, const char*, size_t);
    size_t bracket(size_t, const char *, size_t, const char *);
}

struct Port
{
    static bool isNan(real);
    static real fmodl(real, real);
    double nan;
    static int memicmp(const char*, const char*, size_t);
    static char* strupr(const char*);
}

struct StringValue
{
    char *ptrvalue;
}

struct File
{
    uint _ref;
    this(const char*);
    FileName name();
    void setbuffer(void*, size_t);
    void writev();
    char* toChars();
    bool write();
    bool read();
    size_t len;
    char* buffer;
}

struct FileName
{
    const(char)* str();
    static void free(const char *);
    static const(char)* ext(const char *);
    static const(char)* path(const char *);
    static const(char)* removeExt(const char *);
    static const(char)* name(const char *);
    static void ensurePathToNameExists(const char *);
    static int equals(const char*, const char*);
    static int compare(const char*, const char*);
    static const(char)* forceExt(const char*, const char*);
    static const(char)* defaultExt(const char*, const char*);
    static const(char)* combine(const char*, const char*);
    static const(char)* replaceName(const char*, const char*);
    static ArrayBase!char* splitPath(const char*);
    static int absolute(const char*);
    static int exists(const char*);
}
struct StringTable
{
    StringValue* lookup(const char*, size_t);
}

struct Symbol;
struct Classsym;
struct TYPE;
struct elem;
alias Symbol symbol;
struct AA;
struct Outbuffer {}
struct jmp_buf {}
struct code;
struct block;
struct Blockx;
alias uint opflag_t;
struct PTRNTAB;
struct OP;
struct dt_t;
struct Config {};
struct Configv {};

struct SignExtendedNumber
{
    ulong value;
    bool negative;
}

struct IntRange
{
    SignExtendedNumber imin, imax;
}

alias byte int8_t;
alias ubyte uint8_t;
alias short int16_t;
alias ushort uint16_t;
alias int int32_t;
alias uint uint32_t;
alias long int64_t;
alias ulong uint64_t;

alias ulong ulonglong;

alias long targ_llong;
alias size_t targ_size_t;

alias real longdouble;
alias uint regm_t;
alias uint tym_t;
alias uint list_t;
alias uint idx_t;

enum TARGET_LINUX = 0;
enum TARGET_OSX = 0;
enum TARGET_FREEBSD = 0;
enum TARGET_OPENBSD = 0;
enum TARGET_SOLARIS = 0;
enum TARGET_WINDOS = 1;
enum _WIN32 = 1;

enum I64 = false;

real creall(creal);
real cimagl(creal);
real ldouble(double);


void obj_start(const char*);
void obj_end(void*, File*);
void obj_write_deferred(void*);
void out_config_init(int, bool, bool, bool, char, bool, char, bool, bool);
void backend_init();
void backend_term();

import dmd;

Expression createTypeInfoArray(Scope sc, Expression *args, size_t dim);

struct IRState;
