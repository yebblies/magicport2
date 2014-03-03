
module root.aav;

import root.rootobject;

struct AA;

RootObject _aaGetRvalue(AA* aa, RootObject o)
{
    auto x = *cast(RootObject[void*]*)&aa;
    auto k = cast(void*)o;
    if (auto p = k in x)
        return *p;
    return null;
}

RootObject* _aaGet(AA** aa, RootObject o)
{
    auto x = *cast(RootObject[void*]**)&aa;
    auto k = cast(void*)o;
    if (auto p = k in *x)
        return p;
    else
        (*x)[k] = null;
    return k in *x;
}

size_t _aaLen(AA* aa)
{
    auto x = *cast(RootObject[void*]*)&aa;
    return x.length;
}
