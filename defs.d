
// c library

public import core.stdc.stdarg;
public import core.stdc.stdio;
public import core.stdc.stdlib;
import core.stdc.string : strcmp, strlen, strncmp, strchr, memcmp, memset, memmove, strdup, strcpy, strcat, xmemcmp = memcmp;
public import core.stdc.ctype;
public import core.stdc.errno;
public import core.stdc.limits;
public import core.sys.windows.windows;
public import core.stdc.math;
public import core.stdc.time;
public import core.stdc.stdint;
public import core.stdc.float_;

// generated source

import dmd;

// win32

alias GetModuleFileNameA GetModuleFileName;
alias CreateFileA CreateFile;
alias CreateFileMappingA CreateFileMapping;
alias WIN32_FIND_DATA WIN32_FIND_DATAA;
extern(Windows) DWORD GetFullPathNameA(LPCTSTR lpFileName, DWORD nBufferLength, LPTSTR lpBuffer, LPTSTR *lpFilePart);
alias GetFullPathNameA GetFullPathName;

// c lib

// So we can accept string literals
int memcmp(const char* a, const char* b, size_t len) { return .xmemcmp(a, b, len); }
int memcmp(void* a, void* b, size_t len) { return .xmemcmp(a, b, len); }
__gshared extern(C) const(char)* __locale_decpoint;

// Not defined for some reason
extern(C) int stricmp(const char*, const char*);
extern(C) int putenv(const char*);
extern(C) int spawnlp(int, const char*, const char*, const char*, const char*);
extern(C) int spawnl(int, const char*, const char*, const char*, const char*);
extern(C) int spawnv(int, const char*, const char**);
extern(C) int mkdir(const char*);
alias mkdir _mkdir;
extern(C) int memicmp(const char*, const char*, size_t);
extern(C) char* strupr(const char*);
extern(C) ushort _rotl(ushort, int);
extern(C) ushort _rotr(ushort, int);

extern extern(C) uint _xi_a;
extern extern(C) uint _end;

// root.Object

class _Object
{
    extern(C++) int dyncast() { assert(0); }
    extern(C++) int equals(_Object) { assert(0); }
    extern(C++) int compare(_Object) { assert(0); }
    extern(C++) char *toChars() { assert(0); }
    extern(C++) void toBuffer(OutBuffer *buf) { assert(0); }
    extern(C++) void print()
    {
        printf("%s %p\n", toChars(), this);
    }
}

// root.Array

struct Array(U)
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
    void push(size_t line = __LINE__)(T ptr)
    {
        static if (is(T == Dsymbol) && 0)
        {
            printf("from %d\n", line);
            printf("pushing 0x%.8X\n", ptr);
            printf("%s\n", ptr.kind());
            if (ptr.ident)
            {
                printf("ident 0x%.8X\n", ptr.ident);
                printf("ident %.*s\n", ptr.ident.len, ptr.ident.toChars());
            }
        }
        reserve(1);
        data[dim++] = cast(void*)ptr;
    }
    void append(typeof(this)* a)
    {
        insert(dim, a);
    }
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
    void remove(size_t i)
    {
        if (dim - i - 1)
            memmove(data + i, data + i + 1, (dim - i - 1) * (data[0]).sizeof);
        dim--;
    }
    void insert(size_t index, typeof(this)* a)
    {
        if (a)
        {
            size_t d = a.dim;
            reserve(d);
            if (dim != index)
                memmove(data + index + d, data + index, (dim - index) * (*data).sizeof);
            memcpy(data + index, a.data, d * (*data).sizeof);
            dim += d;
        }
    }
    void insert(size_t index, T ptr)
    {
        reserve(1);
        memmove(data + index + 1, data + index, (dim - index) * (*data).sizeof);
        data[index] = cast(void*)ptr;
        dim++;
    }
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
    typeof(this)* copy()
    {
        auto a = new typeof(this)();
        a.setDim(dim);
        memcpy(a.data, data, dim * (void *).sizeof);
        return a;
    }
    void shift(T ptr)
    {
        reserve(1);
        memmove(data + 1, data, dim * (*data).sizeof);
        data[0] = cast(void*)ptr;
        dim++;
    }
    void zero()
    {
        memset(data,0,dim * (data[0]).sizeof);
    }
    void pop() { assert(0); }
    extern(C++) int apply(int function(T, void*) fp, void* param)
    {
        static if (is(typeof(T.init.apply(fp, null))))
        {
            for (size_t i = 0; i < dim; i++)
            {   T e = tdata()[i];

                if (e)
                {
                    if (e.apply(fp, param))
                        return 1;
                }
            }
            return 0;
        }
        else
            assert(0);
    }
};

// root.rmem

struct Mem
{
    import core.memory;
extern(C++):
    char* strdup(const char *p)
    {
        return p[0..strlen(p)+1].dup.ptr;
    }
    void free(void *p) {}
    void mark(void *pointer) {}
    void* malloc(size_t n) { return GC.malloc(n); }
    void* calloc(size_t size, size_t n) { return GC.calloc(size, n); }
    void* realloc(void *p, size_t size) { return GC.realloc(p, size); }
    void _init() {}
    void setStackBottom(void *bottom) {}
    void addroots(char* pStart, char* pEnd) {}
}
extern(C++) Mem mem;

// root.response

int response_expand(size_t*, const(char)***)
{
    return 0;
}

// root.man

void browse(const char*) { assert(0); }

// root.port

struct Port
{
extern(C++):
    static bool isNan(double r) { return !(r == r); }
    static real fmodl(real a, real b) { return a % b; }
    enum nan = double.nan;
    static int memicmp(const char* s1, const char* s2, size_t n) { return .memicmp(s1, s2, n); }
    static char* strupr(const char* s) { return .strupr(s); }
    static int isSignallingNan(double r) { return isNan(r) && !(((cast(ubyte*)&r)[6]) & 8); }
    static int isSignallingNan(real r) { return isNan(r) && !(((cast(ubyte*)&r)[7]) & 0x40); }
    enum ldbl_max = real.max;
    enum infinity = double.infinity;
}

// IntRange

struct SignExtendedNumber
{
    ulong value;
    bool negative;
    static SignExtendedNumber fromInteger(uinteger_t value)
    {
        assert(0);
    }
    static SignExtendedNumber extreme(bool minimum)
    {
        assert(0);
    }
    static SignExtendedNumber max()
    {
        assert(0);
    }
    static SignExtendedNumber min()
    {
        return SignExtendedNumber(0, true);
    }
    bool isMinimum() const
    {
        return negative && value == 0;
    }
    bool opEquals(const ref SignExtendedNumber a) const
    {
        assert(0);
    }
    int opCmp(const ref SignExtendedNumber a) const
    {
        if (negative != a.negative)
        {
            if (negative)
                return -1;
            else
                return 1;
        }
        if (value < a.value)
            return -1;
        else if (value > a.value)
            return 1;
        else
            return 0;
    }
    SignExtendedNumber opNeg() const
    {
        assert(0);
    }
    SignExtendedNumber opAdd(const ref SignExtendedNumber a) const
    {
        assert(0);
    }
    SignExtendedNumber opSub(const ref SignExtendedNumber a) const
    {
        assert(0);
    }
    SignExtendedNumber opMul(const ref SignExtendedNumber a) const
    {
        assert(0);
    }
    SignExtendedNumber opDiv(const ref SignExtendedNumber a) const
    {
        assert(0);
    }
    SignExtendedNumber opMod(const ref SignExtendedNumber a) const
    {
        assert(0);
    }
    ref SignExtendedNumber opAddAssign(int a)
    {
        assert(0);
    }
    SignExtendedNumber opShl(const ref SignExtendedNumber a)
    {
        assert(0);
    }
    SignExtendedNumber opShr(const ref SignExtendedNumber a)
    {
        assert(0);
    }
}

struct IntRange
{
    SignExtendedNumber imin, imax;

    this(dinteger_t)
    {
        assert(0);
    }
    this(const ref SignExtendedNumber a)
    {
        imin = a;
        imax = a;
    }
    this(SignExtendedNumber lower, SignExtendedNumber upper)
    {
        imin = lower;
        imax = lower;
    }

    static IntRange fromType(Type type)
    {
        return fromType(type, type.isunsigned());
    }
    static IntRange fromType(Type type, bool isUnsigned)
    {
        if (!type.isintegral())
            return widest();

        uinteger_t mask = type.sizemask();
        auto lower = SignExtendedNumber(0);
        auto upper = SignExtendedNumber(mask);
        if (type.toBasetype().ty == Tdchar)
            upper.value = 0x10FFFFUL;
        else if (!isUnsigned)
        {
            lower.value = ~(mask >> 1);
            lower.negative = true;
            upper.value = (mask >> 1);
        }
        return IntRange(lower, upper);
    }
    static IntRange fromNumbers4(SignExtendedNumber* numbers)
    {
        assert(0);
    }
    static IntRange widest()
    {
        assert(0);
    }
    IntRange castSigned(uinteger_t mask)
    {
        assert(0);
    }
    IntRange castUnsigned(uinteger_t mask)
    {
        assert(0);
    }
    IntRange castDchar()
    {
        assert(0);
    }
    IntRange _cast(Type type)
    {
        assert(0);
    }
    IntRange castUnsigned(Type type)
    {
        assert(0);
    }
    bool contains(const ref IntRange a)
    {
        return imin <= a.imin && imax >= a.imax;
    }
    bool containsZero() const
    {
        assert(0);
    }
    IntRange absNeg() const
    {
        assert(0);
    }
    IntRange unionWidth(const ref IntRange other) const
    {
        assert(0);
    }
    IntRange unionOrAssign(IntRange other, ref bool union_)
    {
        assert(0);
    }
    ref const(IntRange) dump(const(char)* funcName, Expression e) const
    {
        assert(0);
    }
    IntRange splitBySign(ref IntRange negRange, ref bool hasNegRange, ref IntRange nonNegRange, ref bool hasNonNegRange) const
    {
        assert(0);
    }
}

enum I64 = false;

// complex_t

real creall(creal x) { return x.re; }
real cimagl(creal x) { return x.im; }

// longdouble.h

real ldouble(T)(T x) { return cast(real)x; }

size_t ld_sprint(char* str, int fmt, real x)
{
    tracein("ld_sprint");
    scope(success) traceout("ld_sprint");
    scope(failure) traceerr("ld_sprint");

    if ((cast(real)cast(ulong)x) == x)
    {   // ((1.5 -> 1 -> 1.0) == 1.5) is false
        // ((1.0 -> 1 -> 1.0) == 1.0) is true
        // see http://en.cppreference.com/w/cpp/io/c/fprintf
        char sfmt[5] = "%#Lg\0";
        sfmt[3] = fmt;
        return sprintf(str, sfmt, x);
    }
    else
    {
        char sfmt[4] = "%Lg\0";
        sfmt[2] = fmt;
        return sprintf(str, sfmt, x);
    }
}

// Backend

struct Symbol;
struct TYPE;
struct elem;
struct code;
struct block;
struct dt_t;
struct IRState;

extern extern(C++) void backend_init();
extern extern(C++) void backend_term();
extern extern(C++) void obj_start(char *srcfile);
extern extern(C++) void obj_end(Library library, File objfile);
extern extern(C++) void obj_write_deferred(Library library);
extern extern(C++) Expression createTypeInfoArray(Scope sc, Expression *args, size_t dim);
extern extern(C++) int os_critsecsize64();
extern extern(C++) int os_critsecsize32();
extern extern(C++) Library LibMSCoff_factory();

// Util

void util_progress() { assert(0); }
int binary(char *, const(char)**, size_t) { assert(0); }

struct AA;
_Object _aaGetRvalue(AA* aa, _Object o)
{
    tracein("_aaGetRvalue");
    scope(success) traceout("_aaGetRvalue");
    scope(failure) traceerr("_aaGetRvalue");
    auto x = *cast(_Object[void*]*)&aa;
    auto k = cast(void*)o;
    if (auto p = k in x)
        return *p;
    return null;
}
_Object* _aaGet(AA** aa, _Object o)
{
    tracein("_aaGet");
    scope(success) traceout("_aaGet");
    scope(failure) traceerr("_aaGet");
    auto x = *cast(_Object[void*]**)&aa;
    auto k = cast(void*)o;
    if (auto p = k in *x)
        return p;
    else
        (*x)[k] = null;
    return k in *x;
}

struct String
{
    static size_t calcHash(const char*) { assert(0); }
}

// root.speller

extern(C++) void* speller(const char*, void* function(void*, const(char)*), Scope, const char*) { assert(0); }
extern(C++) void* speller(const char*, void* function(void*, const(char)*), Dsymbol, const char*) { assert(0); }

const(char)* idchars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";

// root.stringtable

struct StringValue
{
    void *ptrvalue;

private:
    const(char)[] value;

public:
    size_t len() const { return value.length; }
    const(char)* toDchars() const { return value.ptr; }
};

struct StringTable
{
private:
    StringValue*[const(char)[]] table;

public:
    extern(C++) void _init(size_t size = 37)
    {
    }
    ~this()
    {
        table = null;
    }

    extern(C++) StringValue *lookup(const(char)* s, size_t len)
    {
        auto p = s[0..len] in table;
        if (p)
            return *p;
        return null;
    }
    extern(C++) StringValue *insert(const(char)* s, size_t len)
    {
        auto key = s[0..len];
        auto p = key in table;
        if (p)
            return null;
        key = key ~ '\0';
        return (table[key[0..$-1]] = new StringValue(null, key));
    }
    extern(C++) StringValue *update(const(char)* s, size_t len)
    {
        //printf("StringTable::update %d %.*s\n", len, len, s);
        auto key = s[0..len];
        auto p = key in table;
        if (p)
            return *p;
        key = key ~ '\0';
        return (table[key[0..$-1]] = new StringValue(null, key));
    }
};

// hacks to support cloning classed with memcpy

static import stdstring = core.stdc.string;
import typenames;

void* memcpy()(void* dest, const void* src, size_t size) { return stdstring.memcpy(dest, src, size); }
Type memcpy(T : Type)(ref T dest, T src, size_t size)
{
    dest = cast(T)src.clone();;
    assert(dest);
    assert(typeid(dest) == typeid(src));
    switch(typeid(src).toString())
    {
        foreach(s; typeTypes.expand)
        {
            case "dmd." ~ s:
                mixin("copyMembers!(" ~ s ~ ")(cast(" ~ s ~ ")dest, cast(" ~ s ~ ")src);");
                return dest;
        }
    default:
        assert(0, "Cannot copy type " ~ typeid(src).toString());
    }
    return dest;
}
T memcpy(T : Parameter)(ref T dest, T src, size_t size)
{
    dest = new Parameter(src.storageClass, src.type, src.ident, src.defaultArg);
    return dest;
}
Expression memcpy(T : Expression)(ref T dest, T src, size_t size)
{
    dest = cast(T)src.clone();;
    assert(dest);
    assert(typeid(dest) == typeid(src), typeid(src).toString());
    switch(typeid(src).toString())
    {
        foreach(s; expTypes.expand)
        {
            case "dmd." ~ s:
                mixin("copyMembers!(" ~ s ~ ")(cast(" ~ s ~ ")dest, cast(" ~ s ~ ")src);");
                return dest;
        }
    default:
        assert(0, "Cannot copy expression " ~ typeid(src).toString());
    }
    return dest;
}
void* memcpy(T : VarDeclaration)(ref T dest, T src, size_t size) { assert(0); }

// something is wrong with strtof/d/ld

extern(C) float strtof(const(char)* p, char** endp);
extern(C) double strtod(const(char)* p, char** endp);
extern(C) real strtold(const(char)* p, char** endp);

void copyMembers(T : Type)(T dest, T src)
{
    static if (!is(T == _Object))
    {
        foreach(i, v; dest.tupleof)
            dest.tupleof[i] = src.tupleof[i];
        static if (!is(T == Type) && is(T U == super))
            copyMembers!(U)(dest, src);
   }
}
void copyMembers(T : Expression)(T dest, T src)
{
    static if (!is(T == _Object))
    {
        foreach(i, v; dest.tupleof)
            dest.tupleof[i] = src.tupleof[i];
        static if (!is(T == Expression) && is(T U == super))
            copyMembers!(U)(dest, src);
   }
}
void copyMembers(T : _Object)(T dest, T src)
{
}

void main(string[] args)
{
    scope(success) exit(0);
    scope(failure) tracedepth = -1;

    int argc = cast(int)args.length;
    auto argv = (new const(char)*[](argc)).ptr;
    foreach(i, a; args)
        argv[i] = cast(const(char)*)(a ~ '\0').ptr;

    try
    {
        xmain(argc, argv);
    }
    catch (Error e)
    {
        printf("Error: %.*s\n", e.msg);
    }
}

int tracedepth;

version=trace;
//version=fulltrace;

version(trace)
{
    void trace(size_t line = __LINE__)
    {
        printf("%d\n", line);
    }
    void tracein(const char* s, size_t line = __LINE__)
    {
        if (tracedepth < 0)
            return;
        version(fulltrace)
        {
            foreach(i; 0..tracedepth*2)
                putchar(' ');
            printf("+ %s %d\n", s, line);
        }
        tracedepth++;
    }

    void traceout(const char* s, size_t line = __LINE__)
    {
        if (tracedepth < 0)
            return;
        tracedepth--;
        version(fulltrace)
        {
            foreach(i; 0..tracedepth*2)
                putchar(' ');
            printf("- %s %d\n", s, line);
        }
    }

    void traceerr(const char* s, size_t line = __LINE__)
    {
        if (tracedepth < 0)
            return;
        tracedepth--;
        foreach(i; 0..tracedepth*2)
            putchar(' ');
        printf("! %s %d\n", s, line);
    }
}
else
{
    void tracein(const char* s) {}
    void traceout(const char* s) {}
    void traceerr(const char* s) {}
}

// Preprocessor symbols (sometimes used as values)
enum LOG = false;
enum DEBUG = false;
enum IN_GCC = false;
enum MACHOBJ = false;
enum DMDV1 = false;
enum EXTRA_DEBUG = false;
enum linux = false;
enum __APPLE__ = false;
enum __FreeBSD__ = false;
enum __OpenBSD__ = false;
enum __sun = false;
enum SHOWPERFORMANCE = false;
enum LOGASSIGN = false;
enum TARGET_LINUX = false;
enum TARGET_OSX = false;
enum TARGET_FREEBSD = false;
enum TARGET_OPENBSD = false;
enum TARGET_SOLARIS = false;
enum TARGET_NET = false;
enum ASYNCREAD = false;
enum WINDOWS_SEH = false;
enum LITTLE_ENDIAN = false;
enum ELFOBJ = false;
enum _WINDLL = false;
enum UNITTEST = false;
enum CPP_MANGLE = false;
enum __clang__ = false;
enum __GNUC__ = false;
enum __SVR4 = false;
enum MEM_DEBUG = false;
enum GCC_SAFE_DMD = false;
enum OUREH = false;
enum _WIN64 = false;
enum STRINGTABLE = false;
enum __MINGW32__ = false;
enum LOGDEFAULTINIT = false;
enum LOGDOTEXP = false;
enum LOGM = false;
enum LOG_LEASTAS = false;
enum FIXBUG8863 = false;
enum D1INOUT = false;
enum __GLIBC__ = false;
enum CANINLINE_LOG = false;
enum MODULEINFO_IS_STRUCT = false;
enum POSIX = false;
enum MACINTOSH = false;
enum _POSIX_VERSION = false;
enum PATH_MAX = false;
enum TEXTUAL_ASSEMBLY_OUT = false;

enum DMDV2 = true;
enum __DMC__ = true;
enum TX86 = true;
enum TARGET_WINDOS = true;
enum SARRAYVALUE = true;
enum _WIN32 = true;
enum _MSC_VER = true;
enum OMFOBJ = true;
enum BREAKABI = true;
enum UTIL_PH = true;
enum SEH = true;
enum MAGICPORT = true;
enum SNAN_DEFAULT_INIT = true;
enum BUG6652 = true;
enum INTERFACE_VIRTUAL = true;
enum CCASTSYNTAX = true;
enum CARRAYDECL = true;

enum LOGSEMANTIC = false;
enum DOS386 = false;
enum DOS16RM = false;
enum __SC__ = false;
enum MEMMODELS = false;
enum HTOD = false;
enum SCPP = false;

enum MARS = true;
enum DM_TARGET_CPU_X86 = true;
enum MMFIO = true;
enum LINEARALLOC = true;
enum _M_I86 = true;
enum LONGLONG = true;
