
module root.port;

import core.stdc.ctype;
import core.stdc.string;

import target;

version(Windows)
__gshared extern(C) extern const(char)* __locale_decpoint;

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
    static real fequal(real a, real b) { return memcmp(&a, &b, 10) == 0; }
    static int memicmp(const char* s1, const char* s2, size_t n)
    {
        int result = 0;

        for (int i = 0; i < n; i++)
        {   char c1 = s1[i];
            char c2 = s2[i];

            result = c1 - c2;
            if (result)
            {
                result = toupper(c1) - toupper(c2);
                if (result)
                    break;
            }
        }
        return result;
    }
    static char* strupr(char* s)
    {
        char *t = s;

        while (*s)
        {
            *s = cast(char)toupper(*s);
            s++;
        }

        return t;
    }
    static int isSignallingNan(double r) { return isNan(r) && !(((cast(ubyte*)&r)[6]) & 8); }
    static int isSignallingNan(real r) { return isNan(r) && !(((cast(ubyte*)&r)[7]) & 0x40); }
    static int isInfinity(double r) { return r is double.infinity || r is -double.infinity; }
    static float strtof(const(char)* p, char** endp)
    {
        version(Windows)
        {
            auto save = __locale_decpoint;
            __locale_decpoint = ".";
        }
        auto r = .strtof(p, endp);
        version(Windows)
            __locale_decpoint = save;
        return r;
    }
    static double strtod(const(char)* p, char** endp)
    {
        version(Windows)
        {
            auto save = __locale_decpoint;
            __locale_decpoint = ".";
        }
        auto r = .strtod(p, endp);
        version(Windows)
            __locale_decpoint = save;
        return r;
    }
    static real strtold(const(char)* p, char** endp)
    {
        version(Windows)
        {
            auto save = __locale_decpoint;
            __locale_decpoint = ".";
        }
        auto r = .strtold(p, endp);
        version(Windows)
            __locale_decpoint = save;
        return r;
    }
}
