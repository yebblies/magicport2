
// c library

public import core.stdc.stdarg : va_list, va_start, va_end;
public import core.stdc.stdio : printf, sprintf, fprintf, vprintf, vfprintf, fputs, fwrite, _vsnprintf, putchar, remove, _snprintf, fflush, stdout, stderr;
public import core.stdc.stdlib : alloca, exit, EXIT_FAILURE, EXIT_SUCCESS, strtol, strtoull, getenv, malloc, calloc, free;
public import core.stdc.ctype : isspace, isdigit, isalnum, isprint, isalpha, isxdigit, islower, tolower;
public import core.stdc.errno : errno, EEXIST, ERANGE;
public import core.stdc.limits : INT_MAX;
public import core.stdc.math : sinl, cosl, tanl, sqrtl, fabsl;
public import core.stdc.time : time_t, ctime, time;
public import core.stdc.stdint : int64_t, uint64_t, int32_t, uint32_t, int16_t, uint16_t, int8_t, uint8_t;
public import core.stdc.float_;

private import core.stdc.string : strcmp, strlen, strncmp, strchr, memset, memmove, strdup, strcpy, strcat, xmemcmp = memcmp, xmemcpy = memcpy;

public import core.sys.windows.windows;

private import core.memory;

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
int memcmp(const void* a, const void* b, size_t len) { return .xmemcmp(a, b, len); }
int memcmp(void* a, void* b, size_t len) { return .xmemcmp(a, b, len); }

// Not defined for some reason
extern(C) int stricmp(const char*, const char*);
extern(C) int putenv(const char*);
extern(C) int spawnlp(int, const char*, const char*, const char*, const char*);
extern(C) int spawnl(int, const char*, const char*, const char*, const char*);
extern(C) int spawnv(int, const char*, const char**);
extern(C) int mkdir(const char*);
alias mkdir _mkdir;
private extern(C) int memicmp(const char*, const char*, size_t);
private extern(C) char* strupr(const char*);

extern extern(C) __gshared uint _xi_a;
extern extern(C) __gshared uint _end;

// root.Object

extern(C++)
class RootObject
{
    void dtor() { assert(0); }
    bool equals(RootObject o)
    {
        return o is this;
    }
    hash_t hashCode() { assert(0); }
    int compare(RootObject) { assert(0); }
    void print()
    {
        printf("%s %p\n", toChars(), this);
    }
    char *toChars() { assert(0); }
    void toBuffer(OutBuffer* buf) { assert(0); }
    int dyncast() { assert(0); }
}

// root.Array

extern(C++)
struct Array(U)
{
    static if (!is(U == class))
        alias U* T;
    else
        alias U T;

public:
    size_t dim;
    T* data;

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
        data[dim++] = ptr;
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
                data = cast(T*)mem.malloc(allocdim * (*data).sizeof);
            }
            else
            {   allocdim = dim + nentries;
                data = cast(T*)mem.realloc(data, allocdim * (*data).sizeof);
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
            xmemcpy(data + index, a.data, d * (*data).sizeof);
            dim += d;
        }
    }
    void insert(size_t index, T ptr)
    {
        reserve(1);
        memmove(data + index + 1, data + index, (dim - index) * (*data).sizeof);
        data[index] = ptr;
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
        return data[i];
    }
    T* tdata()
    {
        return data;
    }
    typeof(this)* copy()
    {
        auto a = new typeof(this)();
        a.setDim(dim);
        xmemcpy(a.data, data, dim * (void *).sizeof);
        return a;
    }
    void shift(T ptr)
    {
        reserve(1);
        memmove(data + 1, data, dim * (*data).sizeof);
        data[0] = ptr;
        dim++;
    }
    void zero()
    {
        memset(data,0,dim * (data[0]).sizeof);
    }
    void pop() { assert(0); }
    int apply(int function(T, void*) fp, void* param)
    {
        static if (is(typeof(T.init.apply(fp, null))))
        {
            for (size_t i = 0; i < dim; i++)
            {   T e = data[i];

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

extern(C++)
struct Mem
{
    char* strdup(const char *p)
    {
        return p[0..strlen(p)+1].dup.ptr;
    }
    void free(void *p) {}
    void mark(void *pointer) {}
    void* malloc(size_t n) { return GC.malloc(n); }
    void* calloc(size_t size, size_t n) { return GC.calloc(size * n); }
    void* realloc(void *p, size_t size) { return GC.realloc(p, size); }
    void _init() { GC.disable(); }
    void setStackBottom(void *bottom) {}
    void addroots(char* pStart, char* pEnd) {}
}
extern(C++) __gshared Mem mem;

// root.response

int response_expand(size_t*, const(char)***)
{
    return 0;
}

// root.man

void browse(const char*) { assert(0); }

// root.port

__gshared extern(C) const(char)* __locale_decpoint;

extern(C) float strtof(const(char)* p, char** endp);
extern(C) double strtod(const(char)* p, char** endp);
extern(C) real strtold(const(char)* p, char** endp);

extern(C++)
struct Port
{
    enum nan = double.nan;
    enum infinity = double.infinity;
    enum ldbl_max = real.max;
    enum ldbl_nan = real.nan;
    enum ldbl_infinity = real.infinity;
    static __gshared real snan;
    static this()
    {
        /*
         * Use a payload which is different from the machine NaN,
         * so that uninitialised variables can be
         * detected even if exceptions are disabled.
         */
        ushort* us = cast(ushort *)&snan;
        us[0] = 0;
        us[1] = 0;
        us[2] = 0;
        us[3] = 0xA000;
        us[4] = 0x7FFF;

        /*
         * Although long doubles are 10 bytes long, some
         * C ABIs pad them out to 12 or even 16 bytes, so
         * leave enough space in the snan array.
         */
        assert(Target.realsize <= snan.sizeof);
    }
    static bool isNan(double r) { return !(r == r); }
    static real fmodl(real a, real b) { return a % b; }
    static int memicmp(const char* s1, const char* s2, size_t n) { return .memicmp(s1, s2, n); }
    static char* strupr(const char* s) { return .strupr(s); }
    static int isSignallingNan(double r) { return isNan(r) && !(((cast(ubyte*)&r)[6]) & 8); }
    static int isSignallingNan(real r) { return isNan(r) && !(((cast(ubyte*)&r)[7]) & 0x40); }
    static int isInfinity(double r) { return r is double.infinity || r is -double.infinity; }
    static float strtof(const(char)* p, char** endp)
    {
        auto save = __locale_decpoint;
        __locale_decpoint = ".";
        auto r = .strtof(p, endp);
        __locale_decpoint = save;
        return r;
    }
    static double strtod(const(char)* p, char** endp)
    {
        auto save = __locale_decpoint;
        __locale_decpoint = ".";
        auto r = .strtod(p, endp);
        __locale_decpoint = save;
        return r;
    }
    static real strtold(const(char)* p, char** endp)
    {
        auto save = __locale_decpoint;
        __locale_decpoint = ".";
        auto r = .strtold(p, endp);
        __locale_decpoint = save;
        return r;
    }
}

// IntRange

enum UINT64_MAX = 0xFFFFFFFFFFFFFFFFUL;

static uinteger_t copySign(uinteger_t x, bool sign)
{
    // return sign ? -x : x;
    return (x - cast(uinteger_t)sign) ^ -cast(uinteger_t)sign;
}

struct SignExtendedNumber
{
    ulong value;
    bool negative;
    static SignExtendedNumber fromInteger(uinteger_t value_)
    {
        return SignExtendedNumber(value_, value_ >> 63);
    }
    static SignExtendedNumber extreme(bool minimum)
    {
        return SignExtendedNumber(minimum-1, minimum);
    }
    static SignExtendedNumber max()
    {
        return SignExtendedNumber(UINT64_MAX, false);
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
        return value == a.value && negative == a.negative;
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
        if (value == 0)
            return SignExtendedNumber(-cast(ulong)negative);
        else
            return SignExtendedNumber(-value, !negative);
    }
    SignExtendedNumber opAdd(const SignExtendedNumber a) const
    {
        uinteger_t sum = value + a.value;
        bool carry = sum < value && sum < a.value;
        if (negative != a.negative)
            return SignExtendedNumber(sum, !carry);
        else if (negative)
            return SignExtendedNumber(carry ? sum : 0, true);
        else
            return SignExtendedNumber(carry ? UINT64_MAX : sum, false);
    }
    SignExtendedNumber opSub(const SignExtendedNumber a) const
    {
        if (a.isMinimum())
            return negative ? SignExtendedNumber(value, false) : max();
        else
            return this + (-a);
    }
    SignExtendedNumber opMul(const SignExtendedNumber a) const
    {
        // perform *saturated* multiplication, otherwise we may get bogus ranges
        //  like 0x10 * 0x10 == 0x100 == 0.

        /* Special handling for zeros:
            INT65_MIN * 0 = 0
            INT65_MIN * + = INT65_MIN
            INT65_MIN * - = INT65_MAX
            0 * anything = 0
        */
        if (value == 0)
        {
            if (!negative)
                return this;
            else if (a.negative)
                return max();
            else
                return a.value == 0 ? a : this;
        }
        else if (a.value == 0)
            return a * this;   // don't duplicate the symmetric case.

        SignExtendedNumber rv;
        // these are != 0 now surely.
        uinteger_t tAbs = copySign(value, negative);
        uinteger_t aAbs = copySign(a.value, a.negative);
        rv.negative = negative != a.negative;
        if (UINT64_MAX / tAbs < aAbs)
            rv.value = rv.negative-1;
        else
            rv.value = copySign(tAbs * aAbs, rv.negative);
        return rv;
    }
    SignExtendedNumber opDiv(const SignExtendedNumber a) const
    {
        /* special handling for zeros:
            INT65_MIN / INT65_MIN = 1
            anything / INT65_MIN = 0
            + / 0 = INT65_MAX  (eh?)
            - / 0 = INT65_MIN  (eh?)
        */
        if (a.value == 0)
        {
            if (a.negative)
                return SignExtendedNumber(value == 0 && negative);
            else
                return extreme(negative);
        }

        uinteger_t aAbs = copySign(a.value, a.negative);
        uinteger_t rvVal;

        if (!isMinimum())
            rvVal = copySign(value, negative) / aAbs;
        // Special handling for INT65_MIN
        //  if the denominator is not a power of 2, it is same as UINT64_MAX / x.
        else if (aAbs & (aAbs-1))
            rvVal = UINT64_MAX / aAbs;
        // otherwise, it's the same as reversing the bits of x.
        else
        {
            if (aAbs == 1)
                return extreme(!a.negative);
            rvVal = 1UL << 63;
            aAbs >>= 1;
            if (aAbs & 0xAAAAAAAAAAAAAAAAUL) rvVal >>= 1;
            if (aAbs & 0xCCCCCCCCCCCCCCCCUL) rvVal >>= 2;
            if (aAbs & 0xF0F0F0F0F0F0F0F0UL) rvVal >>= 4;
            if (aAbs & 0xFF00FF00FF00FF00UL) rvVal >>= 8;
            if (aAbs & 0xFFFF0000FFFF0000UL) rvVal >>= 16;
            if (aAbs & 0xFFFFFFFF00000000UL) rvVal >>= 32;
        }
        bool rvNeg = negative != a.negative;
        rvVal = copySign(rvVal, rvNeg);

        return SignExtendedNumber(rvVal, rvVal != 0 && rvNeg);
    }
    SignExtendedNumber opMod(const SignExtendedNumber a) const
    {
        if (a.value == 0)
            return !a.negative ? a : isMinimum() ? SignExtendedNumber(0) : this;

        uinteger_t aAbs = copySign(a.value, a.negative);
        uinteger_t rvVal;

        // a % b == sgn(a) * abs(a) % abs(b).
        if (!isMinimum())
            rvVal = copySign(value, negative) % aAbs;
        // Special handling for INT65_MIN
        //  if the denominator is not a power of 2, it is same as UINT64_MAX%x + 1.
        else if (aAbs & (aAbs - 1))
            rvVal = UINT64_MAX % aAbs + 1;
        //  otherwise, the modulus is trivially zero.
        else
            rvVal = 0;

        rvVal = copySign(rvVal, negative);
        return SignExtendedNumber(rvVal, rvVal != 0 && negative);
    }
    ref SignExtendedNumber opAddAssign(int a)
    {
        assert(a == 1);
        if (value != UINT64_MAX)
            ++ value;
        else if (negative)
        {
            value = 0;
            negative = false;
        }
        return this;
    }
    SignExtendedNumber opShl(const SignExtendedNumber a)
    {
        // assume left-shift the shift-amount is always unsigned. Thus negative
        //  shifts will give huge result.
        if (value == 0)
            return this;
        else if (a.negative)
            return extreme(negative);

        uinteger_t v = copySign(value, negative);

        // compute base-2 log of 'v' to determine the maximum allowed bits to shift.
        // Ref: http://graphics.stanford.edu/~seander/bithacks.html#IntegerLog

        // Why is this a size_t? Looks like a bug.
        size_t r, s;

        r = (v > 0xFFFFFFFFUL) << 5; v >>= r;
        s = (v > 0xFFFFUL    ) << 4; v >>= s; r |= s;
        s = (v > 0xFFUL      ) << 3; v >>= s; r |= s;
        s = (v > 0xFUL       ) << 2; v >>= s; r |= s;
        s = (v > 0x3UL       ) << 1; v >>= s; r |= s;
                                               r |= (v >> 1);

        uinteger_t allowableShift = 63 - r;
        if (a.value > allowableShift)
            return extreme(negative);
        else
            return SignExtendedNumber(value << a.value, negative);
    }
    SignExtendedNumber opShr(const SignExtendedNumber a)
    {
        if (a.negative || a.value > 64)
            return negative ? SignExtendedNumber(-1, true) : SignExtendedNumber(0);
        else if (isMinimum())
            return a.value == 0 ? this : SignExtendedNumber(-1UL << (64-a.value), true);

        uinteger_t x = value ^ -cast(int)negative;
        x >>= a.value;
        return SignExtendedNumber(x ^ -cast(int)negative, negative);
    }
}

struct IntRange
{
    SignExtendedNumber imin, imax;

    this(SignExtendedNumber a)
    {
        imin = a;
        imax = a;
    }
    this(SignExtendedNumber lower, SignExtendedNumber upper)
    {
        imin = lower;
        imax = upper;
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
    static IntRange fromNumbers2(SignExtendedNumber* numbers)
    {
        if (numbers[0] < numbers[1])
            return IntRange(numbers[0], numbers[1]);
        else
            return IntRange(numbers[1], numbers[0]);
    }
    static IntRange fromNumbers4(SignExtendedNumber* numbers)
    {
        IntRange ab = fromNumbers2(numbers);
        IntRange cd = fromNumbers2(numbers + 2);
        if (cd.imin < ab.imin)
            ab.imin = cd.imin;
        if (cd.imax > ab.imax)
            ab.imax = cd.imax;
        return ab;
    }
    static IntRange widest()
    {
        return IntRange(SignExtendedNumber.min(), SignExtendedNumber.max());
    }
    IntRange castSigned(uinteger_t mask)
    {
        // .... 0x1e7f ] [0x1e80 .. 0x1f7f] [0x1f80 .. 0x7f] [0x80 .. 0x17f] [0x180 ....
        //
        // regular signed type. We use a technique similar to the unsigned version,
        //  but the chunk has to be offset by 1/2 of the range.
        uinteger_t halfChunkMask = mask >> 1;
        uinteger_t minHalfChunk = imin.value & ~halfChunkMask;
        uinteger_t maxHalfChunk = imax.value & ~halfChunkMask;
        int minHalfChunkNegativity = imin.negative; // 1 = neg, 0 = nonneg, -1 = chunk containing ::max
        int maxHalfChunkNegativity = imax.negative;
        if (minHalfChunk & mask)
        {
            minHalfChunk += halfChunkMask+1;
            if (minHalfChunk == 0)
                -- minHalfChunkNegativity;
        }
        if (maxHalfChunk & mask)
        {
            maxHalfChunk += halfChunkMask+1;
            if (maxHalfChunk == 0)
                -- maxHalfChunkNegativity;
        }
        if (minHalfChunk == maxHalfChunk && minHalfChunkNegativity == maxHalfChunkNegativity)
        {
            imin.value &= mask;
            imax.value &= mask;
            // sign extend if necessary.
            imin.negative = imin.value & ~halfChunkMask;
            imax.negative = imax.value & ~halfChunkMask;
            halfChunkMask += 1;
            imin.value = (imin.value ^ halfChunkMask) - halfChunkMask;
            imax.value = (imax.value ^ halfChunkMask) - halfChunkMask;
        }
        else
        {
            imin = SignExtendedNumber(~halfChunkMask, true);
            imax = SignExtendedNumber(halfChunkMask, false);
        }
        return this;
    }
    IntRange castUnsigned(uinteger_t mask)
    {
        // .... 0x1eff ] [0x1f00 .. 0x1fff] [0 .. 0xff] [0x100 .. 0x1ff] [0x200 ....
        //
        // regular unsigned type. We just need to see if ir steps across the
        //  boundary of validRange. If yes, ir will represent the whole validRange,
        //  otherwise, we just take the modulus.
        // e.g. [0x105, 0x107] & 0xff == [5, 7]
        //      [0x105, 0x207] & 0xff == [0, 0xff]
        uinteger_t minChunk = imin.value & ~mask;
        uinteger_t maxChunk = imax.value & ~mask;
        if (minChunk == maxChunk && imin.negative == imax.negative)
        {
            imin.value &= mask;
            imax.value &= mask;
        }
        else
        {
            imin.value = 0;
            imax.value = mask;
        }
        imin.negative = imax.negative = false;
        return this;
    }
    IntRange castDchar()
    {
        // special case for dchar. Casting to dchar means "I'll ignore all
        //  invalid characters."
        castUnsigned(0xFFFFFFFFUL);
        if (imin.value > 0x10FFFFUL)   // ??
            imin.value = 0x10FFFFUL;   // ??
        if (imax.value > 0x10FFFFUL)
            imax.value = 0x10FFFFUL;
        return this;
    }
    IntRange _cast(Type type)
    {
        if (!type.isintegral())
            return this;
        else if (!type.isunsigned())
            return castSigned(type.sizemask());
        else if (type.toBasetype().ty == Tdchar)
            return castDchar();
        else
            return castUnsigned(type.sizemask());
    }
    IntRange castUnsigned(Type type)
    {
        if (!type.isintegral())
            return castUnsigned(UINT64_MAX);
        else if (type.toBasetype().ty == Tdchar)
            return castDchar();
        else
            return castUnsigned(type.sizemask());
    }
    bool contains(IntRange a)
    {
        return imin <= a.imin && imax >= a.imax;
    }
    bool containsZero() const
    {
        return (imin.negative && !imax.negative)
            || (!imin.negative && imin.value == 0);
    }
    IntRange absNeg() const
    {
        if (imax.negative)
            return this;
        else if (!imin.negative)
            return IntRange(-imax, -imin);
        else
        {
            SignExtendedNumber imaxAbsNeg = -imax;
            return IntRange(imaxAbsNeg < imin ? imaxAbsNeg : imin,
                            SignExtendedNumber(0));
        }
    }
    IntRange unionWidth(const ref IntRange other) const
    {
        return IntRange(imin < other.imin ? imin : other.imin,
                        imax > other.imax ? imax : other.imax);
    }
    void unionOrAssign(IntRange other, ref bool union_)
    {
        if (!union_ || imin > other.imin)
            imin = other.imin;
        if (!union_ || imax < other.imax)
            imax = other.imax;
        union_ = true;
    }
    ref const(IntRange) dump(const(char)* funcName, Expression e) const
    {
        printf("[(%c)%#018llx, (%c)%#018llx] @ %s ::: %s\n",
               imin.negative?'-':'+', cast(ulong)imin.value,
               imax.negative?'-':'+', cast(ulong)imax.value,
               funcName, e.toChars());
        return this;
    }
    void splitBySign(ref IntRange negRange, ref bool hasNegRange, ref IntRange nonNegRange, ref bool hasNonNegRange) const
    {
        hasNegRange = imin.negative;
        if (hasNegRange)
        {
            negRange.imin = imin;
            negRange.imax = imax.negative ? imax : SignExtendedNumber(-1, true);
        }
        hasNonNegRange = !imax.negative;
        if (hasNonNegRange)
        {
            nonNegRange.imin = imin.negative ? SignExtendedNumber(0) : imin;
            nonNegRange.imax = imax;
        }
    }
}

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
extern extern(C++) void obj_end(Library library, File* objfile);
extern extern(C++) void obj_write_deferred(Library library);
extern extern(C++) Expression createTypeInfoArray(Scope* sc, Expression *args, size_t dim);

// Util

int binary(char* p, const(char)** tab, size_t n)
{
    for (int i = 0; i < n; ++i)
        if (!strcmp(p, tab[i]))
            return i;
    return -1;
}

struct AA;
RootObject _aaGetRvalue(AA* aa, RootObject o)
{
    tracein("_aaGetRvalue");
    scope(success) traceout("_aaGetRvalue");
    scope(failure) traceerr("_aaGetRvalue");
    auto x = *cast(RootObject[void*]*)&aa;
    auto k = cast(void*)o;
    if (auto p = k in x)
        return *p;
    return null;
}
RootObject* _aaGet(AA** aa, RootObject o)
{
    tracein("_aaGet");
    scope(success) traceout("_aaGet");
    scope(failure) traceerr("_aaGet");
    auto x = *cast(RootObject[void*]**)&aa;
    auto k = cast(void*)o;
    if (auto p = k in *x)
        return p;
    else
        (*x)[k] = null;
    return k in *x;
}

// root.speller

extern(C++) void* speller(const char*, void* function(void*, const(char)*), Scope*, const char*) { return null; }
extern(C++) void* speller(const char*, void* function(void*, const(char)*), Dsymbol, const char*) { return null; }

extern(C++) __gshared const(char)* idchars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";

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

extern(C++)
struct StringTable
{
private:
    StringValue*[const(char)[]] table;

public:
    void _init(size_t size = 37)
    {
        table = null;
    }
    ~this()
    {
        table = null;
    }

    StringValue *lookup(const(char)* s, size_t len)
    {
        auto p = s[0..len] in table;
        if (p)
            return *p;
        return null;
    }
    StringValue *insert(const(char)* s, size_t len)
    {
        auto key = s[0..len];
        auto p = key in table;
        if (p)
            return null;
        key = key ~ '\0';
        return (table[key[0..$-1]] = new StringValue(null, key));
    }
    StringValue *update(const(char)* s, size_t len)
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

// root.outbuffer

extern(C++)
struct OutBuffer
{
    ubyte* data;
    size_t offset;
    size_t size;

    int doindent;
    int level;
    int notlinehead;
    char *extractData();
    void mark();

    void reserve(size_t nbytes);
    void setsize(size_t size);
    void reset();
    void write(const(void)* data, size_t nbytes);
    void writebstring(ubyte* string);
    void writestring(const(char)* string);
    void prependstring(const(char)* string);
    void writenl();                     // write newline
    void writeByte(uint b);
    void writebyte(uint b) { writeByte(b); }
    void writeUTF8(uint b);
    void prependbyte(uint b);
    void writewchar(uint w);
    void writeword(uint w);
    void writeUTF16(uint w);
    void write4(uint w);
    void write(OutBuffer *buf);
    void write(RootObject obj);
    void fill0(size_t nbytes);
    void _align(size_t size);
    void vprintf(const(char)* format, va_list args) { vprintf(format, cast(char*)args); }
    void vprintf(const(char)* format, char* args);
    void printf(const(char)* format, ...);
    void bracket(char left, char right);
    size_t bracket(size_t i, const(char)* left, size_t j, const(char)* right);
    void spread(size_t offset, size_t nbytes);
    size_t insert(size_t offset, const(void)* data, size_t nbytes);
    size_t insert(size_t offset, const(char)* data, size_t nbytes);
    void remove(size_t offset, size_t nbytes);
    char* toChars();
    char* extractString();
};

// hacks to support cloning classed with memcpy

import typenames : typeTypes, expTypes;

void* memcpy()(void* dest, const void* src, size_t size) { return xmemcpy(dest, src, size); }
Type memcpy(T : Type)(ref T dest, T src, size_t size)
{
    dest = cast(T)src.clone();;
    assert(dest);
    xmemcpy(cast(void*)dest, cast(void*)src, GC.sizeOf(cast(void*)dest));
    return dest;
}
T memcpy(T : Parameter)(ref T dest, T src, size_t size)
{
    dest = new Parameter(src.storageClass, src.type, src.ident, src.defaultArg);
    assert(dest);
    xmemcpy(cast(void*)dest, cast(void*)src, GC.sizeOf(cast(void*)dest));
    return dest;
}
Expression memcpy(T : Expression)(ref T dest, T src, size_t size)
{
    dest = cast(T)src.clone();;
    assert(dest);
    xmemcpy(cast(void*)dest, cast(void*)src, GC.sizeOf(cast(void*)dest));
    return dest;
}
T memcpy(T : VarDeclaration)(ref T dest, T src, size_t size)
{
    dest = new VarDeclaration(src.loc, src.type, src.ident, src._init);
    xmemcpy(cast(void*)dest, cast(void*)src, GC.sizeOf(cast(void*)dest));
    return dest;
}

void main(string[] args)
{
    scope(success) exit(0);
    scope(failure) tracedepth = -1;
    __locale_decpoint = ".";

    int argc = cast(int)args.length;
    auto argv = (new const(char)*[](argc)).ptr;
    foreach(i, a; args)
        argv[i] = (a ~ '\0').ptr;

    // try
    // {
        xmain(argc, argv);
    // }
    // catch (Error e)
    // {
        // printf("Error: %.*s\n", e.msg);
    // }
}

__gshared int tracedepth;

version=trace;
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
    void trace() {}
    void tracein() {}
    void traceout() {}
    void traceerr() {}
}

// Preprocessor symbols (sometimes used as values)
template xversion(string s)
{
    enum xversion = mixin("{ version(" ~ s ~ ") return true; else return false; }")();
}

enum DDMD = true;

enum linux = xversion!"linux";
enum __APPLE__ = xversion!"OSX";
enum __FreeBSD__ = xversion!"FreeBSD";
enum __OpenBSD__ = xversion!"OpenBSD";
enum __sun = xversion!"Solaris";
enum _WIN32 = xversion!"Windows";

enum IN_GCC = xversion!"GNU";
enum __DMC__ = xversion!"DigitalMars";
enum _MSC_VER = false;

enum LOG = false;
enum ASYNCREAD = false;
enum WINDOWS_SEH = false;
enum OMFOBJ = true;
enum UNITTEST = false;
enum CANINLINE_LOG = false;
enum TEXTUAL_ASSEMBLY_OUT = false;
enum LOGSEMANTIC = false;

enum TARGET_LINUX = false;
enum TARGET_OSX = false;
enum TARGET_FREEBSD = false;
enum TARGET_OPENBSD = false;
enum TARGET_SOLARIS = false;
enum TARGET_WINDOS = true;

enum __GNUC__ = false;
enum __MINGW32__ = false;
enum GCC_SAFE_DMD = false;
