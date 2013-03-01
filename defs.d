
public import core.stdc.stdarg;
public import core.stdc.stdio;
public import core.stdc.stdlib;
import core.stdc.string : strcmp, memcpy, strlen, strncmp;
public import core.stdc.ctype;
public import core.stdc.errno;
public import core.stdc.limits;

int memcmp(const char*, const char*, size_t len);

enum NULL = null;

class _Object
{
}

struct ArrayBase(T) if (!is(T == class))
{
    void push(T*);
    void append(ArrayBase!T*);
    void reserve(size_t);
    void remove(size_t);
    void insert(size_t, ArrayBase!T*);
    size_t dim();
    void setDim(size_t);
    ref T* opIndex(size_t);
    T** tdata();
};

struct ArrayBase(T) if (is(T == class))
{
    void push(T);
    void append(ArrayBase!T*);
    void reserve(size_t);
    void remove(size_t);
    void insert(size_t, ArrayBase!T*);
    size_t dim();
    void setDim(size_t);
    ref T opIndex(size_t);
    T* tdata;
};

struct Mem
{
    void init();
    void* malloc(size_t);
    void free(void*);
    char* strdup(char*);
    void setStackBottom(void*);
    void addroots(void*, void*);
}
extern extern(C) uint _xi_a;
extern extern(C) uint _end;

Mem mem;

int response_expand(size_t*, char***);
void browse(const char*);

struct OutBuffer
{
    int vprintf(const char* format, ...);
    void writebyte(int);
    void writeByte(int);
    void writestring(const char*);
    char *toChars();
    char *extractData();
    void *data;
    size_t offset;
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
}

struct FileName
{
    const(char)* str();
    static const(char)* ext(const char *);
    static const(char)* name(const char *);
    static void ensurePathToNameExists(const char *);
    static int equals(const char*, const char*);
    static int compare(const char*, const char*);
    static const(char)* forceExt(const char*, const char*);
    static const(char)* defaultExt(const char*, const char*);
    static const(char)* combine(const char*, const char*);
    static ArrayBase!char* splitPath(const char*);
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

struct IntRange;

alias byte int8_t;
alias ubyte uint8_t;
alias short int16_t;
alias ushort uint16_t;
alias int int32_t;
alias uint uint32_t;
alias long int64_t;
alias ulong uint64_t;

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
