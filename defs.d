
// generated source

import mars;

// Not defined for some reason
version(Windows)
{
    extern(C) int stricmp(const char*, const char*);
    extern(C) int putenv(const char*);
    extern(C) int spawnlp(int, const char*, const char*, const char*, const char*);
    extern(C) int spawnl(int, const char*, const char*, const char*, const char*);
    extern(C) int spawnv(int, const char*, const char**);
}

uint rol(uint x, uint n)
{
    return (x << n) | (x >> (32-n));
}
uint ror(uint x, uint n)
{
    return (x >> n) | (x << (32-n));
}

int main()
{
    import core.runtime;
    auto args = Runtime.cArgs();
    return tryMain(args.argc, cast(const(char)**)args.argv);
}

// Preprocessor symbols (sometimes used as values)
template xversion(string s)
{
    enum xversion = mixin("{ version(" ~ s ~ ") return true; else return false; }")();
}

enum __linux__ = xversion!"linux";
enum linux = xversion!"linux";
enum __APPLE__ = xversion!"OSX";
enum __FreeBSD__ = xversion!"FreeBSD";
enum __OpenBSD__ = xversion!"OpenBSD";
enum __sun = xversion!"Solaris";

enum IN_GCC = xversion!"GNU";
enum __DMC__ = xversion!"DigitalMars";
enum _MSC_VER = false;
enum __clang__ = false;
enum __GNUC__ = false;
enum __MINGW32__ = false;
enum __GLIBC__ = xversion!"linux";

enum LOG = false;
enum ASYNCREAD = false;
enum CANINLINE_LOG = false;
enum LOGSEMANTIC = false;

enum TARGET_LINUX = xversion!"linux";
enum TARGET_OSX = xversion!"OSX";
enum TARGET_FREEBSD = xversion!"FreeBSD";
enum TARGET_OPENBSD = xversion!"OpenBSD";
enum TARGET_SOLARIS = xversion!"Solaris";
enum TARGET_WINDOS = xversion!"Windows";
