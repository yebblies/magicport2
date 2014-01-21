
bool[string] basicTypes;
bool[string] structTypes;
bool[string] classTypes;

bool lookup(bool[string] aa, string n)
{
    auto p = n in aa;
    if (p) *p = true;
    return p !is null;
}