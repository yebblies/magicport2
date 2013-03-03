
public import core.stdc.stdarg;
public import core.stdc.stdio;
public import core.stdc.stdlib;
import core.stdc.string : strcmp, strlen, strncmp, strchr, memcmp, memset, memmove, strdup, strcpy, strcat;
public import core.stdc.ctype;
public import core.stdc.errno;
public import core.stdc.limits;
public import core.sys.windows.windows;
public import core.stdc.math;
public import core.stdc.time;

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
    int compare(_Object);
    char *toChars();
    void print();
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
    size_t dim;
    void setDim(size_t);
    ref T opIndex(size_t);
    T* tdata();
    typeof(this)* copy();
    void shift(T);
    T* data;
    void zero();
    void pop();
};

struct Mem
{
    void _init();
    void* malloc(size_t);
    void free(void*);
    char* strdup(const char*);
    void setStackBottom(void*);
    void addroots(void*, void*);
    void* calloc(size_t, size_t);
    void* realloc(void*, size_t);
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
    ubyte *data;
    size_t offset;
    void reset();
    void write(OutBuffer*);
    void write(const char*, size_t);
    void write(const ubyte*, size_t);
    void remove(size_t, size_t);
    void reserve(size_t);
    void setsize(size_t);
    size_t insert(size_t, const ubyte*, size_t);
    size_t insert(size_t, const char*, size_t);
    size_t bracket(size_t, const char *, size_t, const char *);
    void writenl();
    size_t level;
    void writeUTF8(uint);
    void writeUTF16(uint);
    void write4(uint);
    void writeword(uint);
    bool doindent;
    void spread(size_t, size_t);
    void fill0(size_t);
}

struct Port
{
    static bool isNan(real);
    static real fmodl(real, real);
    static double nan;
    static int memicmp(const char*, const char*, size_t);
    static char* strupr(const char*);
    enum ldbl_max = real.max;
    enum infinity = real.infinity;
}

enum FLT_MAX = float.max;
enum FLT_MIN = float.min;
enum FLT_DIG = float.dig;
enum FLT_EPSILON = float.epsilon;
enum FLT_MANT_DIG = float.mant_dig;
enum FLT_MAX_10_EXP = float.max_10_exp;
enum FLT_MAX_EXP = float.max_exp;
enum FLT_MIN_10_EXP = float.min_10_exp;
enum FLT_MIN_EXP = float.min_exp;
enum DBL_MAX = double.max;
enum DBL_MIN = double.min;
enum DBL_DIG = double.dig;
enum DBL_EPSILON = double.epsilon;
enum DBL_MANT_DIG = double.mant_dig;
enum DBL_MAX_10_EXP = double.max_10_exp;
enum DBL_MAX_EXP = double.max_exp;
enum DBL_MIN_10_EXP = double.min_10_exp;
enum DBL_MIN_EXP = double.min_exp;
enum LDBL_MIN = real.min;
enum LDBL_DIG = real.dig;
enum LDBL_EPSILON = real.epsilon;
enum LDBL_MANT_DIG = real.mant_dig;
enum LDBL_MAX_10_EXP = real.max_10_exp;
enum LDBL_MAX_EXP = real.max_exp;
enum LDBL_MIN_10_EXP = real.min_10_exp;
enum LDBL_MIN_EXP = real.min_exp;

struct StringValue
{
    char *ptrvalue;
    void* toDchars();
}

struct File
{
    uint _ref;
    this(const char*);
    this(FileName*);
    FileName name();
    void setbuffer(void*, size_t);
    void writev();
    char* toChars();
    bool write();
    bool read();
    bool readv();
    size_t len;
    char* buffer;
    void remove();
}

struct FileName
{
    this(const char*);
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
    static int equalsExt(const char*, const char*);
    static const(char)* combine(const char*, const char*);
    static const(char)* replaceName(const char*, const char*);
    static const(char)* safeSearchPath(Strings*, const char*);
    static ArrayBase!char* splitPath(const char*);
    static int absolute(const char*);
    static int exists(const char*);
    const char* toChars();
}
struct StringTable
{
    StringValue* lookup(const char*, size_t);
    void _init(size_t = 0);
    StringValue* update(const char*, size_t);
    StringValue* insert(const char*, size_t);
}

struct Symbol;
struct Classsym;
struct TYPE;
struct elem;
alias Symbol symbol;
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
    SignExtendedNumber opNeg();
    SignExtendedNumber opAdd(SignExtendedNumber);
    SignExtendedNumber opSub(SignExtendedNumber);
    SignExtendedNumber opMul(SignExtendedNumber);
    SignExtendedNumber opDiv(SignExtendedNumber);
    ref SignExtendedNumber opAddAssign(ulong);
    int opCmp(SignExtendedNumber);
    SignExtendedNumber opShl(SignExtendedNumber);
    SignExtendedNumber opShr(SignExtendedNumber);
}

struct IntRange
{
    SignExtendedNumber imin, imax;
    this(dinteger_t);
    this(SignExtendedNumber, SignExtendedNumber);
    static IntRange fromType(Type, bool = false);
    bool contains(IntRange);
    IntRange _cast(Type);
    static IntRange fromNumbers4(SignExtendedNumber*);
    bool containsZero();
    IntRange absNeg();
    IntRange castUnsigned(Type);
    IntRange splitBySign(IntRange, bool, IntRange, bool);
    IntRange unionOrAssign(IntRange, bool);
}

alias byte int8_t;
alias ubyte uint8_t;
alias short int16_t;
alias ushort uint16_t;
alias int int32_t;
alias uint uint32_t;
alias long int64_t;
alias ulong uint64_t;

alias long longlong;
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
void obj_end(Library, File*);
void obj_write_deferred(void*);
void obj_write_deferred(Library);
void out_config_init(int, bool, bool, bool, char, bool, char, bool, bool);
void backend_init();
void backend_term();

import dmd;

Expression createTypeInfoArray(Scope sc, Expression *args, size_t dim);

struct IRState;

ushort _rotl(ushort, int);
ushort _rotr(ushort, int);

struct AA;
_Object _aaGetRvalue(AA*, _Object);
_Object _aaGet(AA**, _Object);

void util_progress();

struct String
{
    static size_t calcHash(const char*);
}

void* speller(const char*, void* function(void*, const(char)*), Scope, const char*);
void* speller(const char*, void* function(void*, const(char)*), Dsymbol, const char*);

const(char)* idchars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";

void* memcpy()(void* dest, const void* src, size_t size);
void* memcpy(T : Type)(ref T dest, T src, size_t size);
void* memcpy(T : Parameter)(ref T dest, T src, size_t size);
void* memcpy(T : Expression)(ref T dest, T src, size_t size);
void* memcpy(T : VarDeclaration)(ref T dest, T src, size_t size);

int binary(char *, const(char)**, size_t);

int os_critsecsize32();
int os_critsecsize64();

Library LibMSCoff_factory();
