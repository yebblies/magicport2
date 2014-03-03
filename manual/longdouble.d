
module longdouble;

import core.stdc.stdio;

real ldouble(T)(T x) { return cast(real)x; }

size_t ld_sprint(char* str, int fmt, real x)
{
    if ((cast(real)cast(ulong)x) == x)
    {   // ((1.5 -> 1 -> 1.0) == 1.5) is false
        // ((1.0 -> 1 -> 1.0) == 1.0) is true
        // see http://en.cppreference.com/w/cpp/io/c/fprintf
        char sfmt[5] = "%#Lg\0";
        sfmt[3] = cast(char)fmt;
        return sprintf(str, sfmt.ptr, x);
    }
    else
    {
        char sfmt[4] = "%Lg\0";
        sfmt[2] = cast(char)fmt;
        return sprintf(str, sfmt.ptr, x);
    }
}
