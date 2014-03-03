
// generated source

import mars;

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
enum __APPLE__ = xversion!"OSX";
enum __FreeBSD__ = xversion!"FreeBSD";
enum __OpenBSD__ = xversion!"OpenBSD";
enum __sun = xversion!"Solaris";

enum IN_GCC = xversion!"GNU";
enum _MSC_VER = false;
enum __GLIBC__ = xversion!"linux";

enum TARGET_LINUX = xversion!"linux";
enum TARGET_OSX = xversion!"OSX";
enum TARGET_FREEBSD = xversion!"FreeBSD";
enum TARGET_OPENBSD = xversion!"OpenBSD";
enum TARGET_SOLARIS = xversion!"Solaris";
enum TARGET_WINDOS = xversion!"Windows";
