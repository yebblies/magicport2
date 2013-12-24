
module root.stringtable;

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
