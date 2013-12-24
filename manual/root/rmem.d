
module root.rmem;

import core.memory : GC;
import core.stdc.string;

extern(C++)
struct Mem
{
    char* strdup(const char *p)
    {
        return p[0..strlen(p)+1].dup.ptr;
    }
    void free(void *p) {}
    void* malloc(size_t n) { return GC.malloc(n); }
    void* calloc(size_t size, size_t n) { return GC.calloc(size * n); }
    void* realloc(void *p, size_t size) { return GC.realloc(p, size); }
}
extern(C++) __gshared Mem mem;
