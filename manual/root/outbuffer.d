
module root.outbuffer;

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
    version(Windows)
    {
        void vprintf(const(char)* format, va_list args) { vprintf(format, cast(char*)args); }
        void vprintf(const(char)* format, char* args);
    }
    else
    {
        void vprintf(const(char)* format, va_list args) { vprintf(format, cast(void*)args); }
        void vprintf(const(char)* format, void* args);
    }
    void printf(const(char)* format, ...);
    void bracket(char left, char right);
    size_t bracket(size_t i, const(char)* left, size_t j, const(char)* right);
    void spread(size_t offset, size_t nbytes);
    size_t insert(size_t offset, const(void)* data, size_t nbytes);
    size_t insert(size_t offset, const(char)* data, size_t nbytes) { return insert(offset, cast(const(void)*)data, nbytes); }
    void remove(size_t offset, size_t nbytes);
    char* toChars();
    char* extractString();
};
