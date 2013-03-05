
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
alias CreateFileA CreateFile;
alias CreateFileMappingA CreateFileMapping;
alias WIN32_FIND_DATA WIN32_FIND_DATAA;
extern(Windows) DWORD GetFullPathNameA(LPCTSTR lpFileName, DWORD nBufferLength, LPTSTR lpBuffer, LPTSTR *lpFilePart);
alias GetFullPathNameA GetFullPathName;

int memcmp(const char*, const char*, size_t len) { assert(0); }
int memcmp(void*, void*, size_t len) { assert(0); }
int stricmp(const char*, const char*) { assert(0); }
int ld_sprint(const char*, ...) { assert(0); }
void __locale_decpoint(const char*) { assert(0); }
char* __locale_decpoint() { assert(0); }
extern(C) int putenv(const char*);
int spawnlp(int, const char*, const char*, const char*, const char*) { assert(0); }
int spawnl(int, const char*, const char*, const char*, const char*) { assert(0); }
int spawnv(int, const char*, const char**) { assert(0); }

enum NULL = null;

class _Object
{
    int dyncast() { assert(0); }
    int equals(_Object) { assert(0); }
    int compare(_Object) { assert(0); }
    char *toChars() { assert(0); }
    void print() { assert(0); }
}

struct ArrayBase(U)
{
    static if (!is(U == class))
        alias U* T;
    else
        alias U T;

public:
    size_t dim;
    void** data;

private:
    size_t allocdim;

public:
    void push(T ptr)
    {
        reserve(1);
        data[dim++] = cast(void*)ptr;
    }
    void append(typeof(this)*) { assert(0); }
    void reserve(size_t nentries)
    {
        //printf("Array::reserve: dim = %d, allocdim = %d, nentries = %d\n", (int)dim, (int)allocdim, (int)nentries);
        if (allocdim - dim < nentries)
        {
            if (allocdim == 0)
            {   // Not properly initialized, someone memset it to zero
                allocdim = nentries;
                data = cast(void **)mem.malloc(allocdim * (*data).sizeof);
            }
            else
            {   allocdim = dim + nentries;
                data = cast(void **)mem.realloc(data, allocdim * (*data).sizeof);
            }
        }
    }
    void remove(size_t) { assert(0); }
    void insert(size_t, typeof(this)*) { assert(0); }
    void insert(size_t, T) { assert(0); }
    void setDim(size_t newdim)
    {
        if (dim < newdim)
        {
            reserve(newdim - dim);
        }
        dim = newdim;
    }
    ref T opIndex(size_t i)
    {
        return tdata()[i];
    }
    T* tdata()
    {
        return cast(T*)data;
    }
    typeof(this)* copy() { assert(0); }
    void shift(T) { assert(0); }
    void zero() { assert(0); }
    void pop() { assert(0); }
    int apply(apply_fp_t, void*) { assert(0); }
};

extern extern(C) uint _xi_a;
extern extern(C) uint _end;

struct GC {}

int response_expand(size_t*, const(char)***)
{
    return 0;
}
void browse(const char*) { assert(0); }

extern(C) int memicmp(const char*, const char*, size_t);
extern(C) char* strupr(const char*);

struct Port
{
    static bool isNan(double r) { return !(r == r); }
    static real fmodl(real a, real b) { return a % b; }
    enum nan = double.nan;
    static int memicmp(const char* s1, const char* s2, size_t n) { return .memicmp(s1, s2, n); }
    static char* strupr(const char* s) { return .strupr(s); }
    enum ldbl_max = real.max;
    enum infinity = double.infinity;
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
    SignExtendedNumber opNeg() { assert(0); }
    SignExtendedNumber opAdd(SignExtendedNumber) { assert(0); }
    SignExtendedNumber opSub(SignExtendedNumber) { assert(0); }
    SignExtendedNumber opMul(SignExtendedNumber) { assert(0); }
    SignExtendedNumber opDiv(SignExtendedNumber) { assert(0); }
    ref SignExtendedNumber opAddAssign(ulong) { assert(0); }
    int opCmp(SignExtendedNumber) { assert(0); }
    SignExtendedNumber opShl(SignExtendedNumber) { assert(0); }
    SignExtendedNumber opShr(SignExtendedNumber) { assert(0); }
}

struct IntRange
{
    SignExtendedNumber imin, imax;
    this(dinteger_t) { assert(0); }
    this(SignExtendedNumber, SignExtendedNumber) { assert(0); }
    static IntRange fromType(Type, bool = false) { assert(0); }
    bool contains(IntRange) { assert(0); }
    IntRange _cast(Type) { assert(0); }
    static IntRange fromNumbers4(SignExtendedNumber*) { assert(0); }
    bool containsZero() { assert(0); }
    IntRange absNeg() { assert(0); }
    IntRange castUnsigned(Type) { assert(0); }
    IntRange splitBySign(IntRange, bool, IntRange, bool) { assert(0); }
    IntRange unionOrAssign(IntRange, bool) { assert(0); }
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

enum linux = false;
enum __APPLE__ = false;
enum __FreeBSD__ = false;
enum __OpenBSD__ = false;
enum __sun = false;

real creall(creal) { assert(0); }
real cimagl(creal) { assert(0); }
real ldouble(double) { assert(0); }


void obj_start(const char*) { assert(0); }
void obj_end(void*, File*) { assert(0); }
void obj_end(Library, File*) { assert(0); }
void obj_write_deferred(void*) { assert(0); }
void obj_write_deferred(Library) { assert(0); }
void out_config_init(int, bool, bool, bool, char, bool, char, bool, bool) { assert(0); }
void backend_init() { assert(0); }
void backend_term() { assert(0); }

import dmd;

Expression createTypeInfoArray(Scope sc, Expression *args, size_t dim) { assert(0); }

struct IRState;

ushort _rotl(ushort, int) { assert(0); }
ushort _rotr(ushort, int) { assert(0); }

struct AA;
_Object _aaGetRvalue(AA*, _Object) { assert(0); }
_Object _aaGet(AA**, _Object) { assert(0); }

void util_progress() { assert(0); }

struct String
{
    static size_t calcHash(const char*) { assert(0); }
}

void* speller(const char*, void* function(void*, const(char)*), Scope, const char*) { assert(0); }
void* speller(const char*, void* function(void*, const(char)*), Dsymbol, const char*) { assert(0); }

const(char)* idchars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";

static import stdstring = core.stdc.string;

void* memcpy()(void* dest, const void* src, size_t size) { return stdstring.memcpy(dest, src, size); }
void* memcpy(T : Type)(ref T dest, T src, size_t size) { assert(0); }
void* memcpy(T : Parameter)(ref T dest, T src, size_t size) { assert(0); }
void* memcpy(T : Expression)(ref T dest, T src, size_t size) { assert(0); }
void* memcpy(T : VarDeclaration)(ref T dest, T src, size_t size) { assert(0); }

int binary(char *, const(char)**, size_t) { assert(0); }

int os_critsecsize32() { assert(0); }
int os_critsecsize64() { assert(0); }

Library LibMSCoff_factory() { assert(0); }

void main(string[] args)
{
    int argc = cast(int)args.length;
    auto argv = (new const(char)*[](argc)).ptr;
    foreach(i, a; args)
        argv[i] = cast(const(char)*)(a ~ '\0').ptr;
    global = new Global();
    xmain(argc, argv);
}

GC gc;

extern(C) int mkdir(const char*);
alias mkdir _mkdir;
