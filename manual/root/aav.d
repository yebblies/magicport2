
module root.aav;

import root.rootobject;
import defs;

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
