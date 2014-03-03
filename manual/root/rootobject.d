
module root.rootobject;

import core.stdc.stdio;

import root.outbuffer;

extern(C++)
class RootObject
{
    this()
    {
    }
    bool equals(RootObject o)
    {
        return o is this;
    }
    int compare(RootObject) { assert(0); }
    void print()
    {
        printf("%s %p\n", toChars(), this);
    }
    char *toChars() { assert(0); }
    void toBuffer(OutBuffer* buf) { assert(0); }
    int dyncast() { assert(0); }
}
