
bool[string] basicTypes;
bool[string] structTypes;
bool[string] classTypes;
bool[string] rootClasses;
string[][] overridenFuncs;

bool lookup(bool[string] aa, string n)
{
    auto p = n in aa;
    if (p) *p = true;
    return p !is null;
}