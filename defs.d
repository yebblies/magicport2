
public import core.stdc.stdarg;
public import core.stdc.stdio;

enum NULL = null;

struct ArrayBase(T)
{
};

struct OutBuffer {}
struct File {}
struct StringTable {}

struct Symbol;
struct Classsym;
struct TYPE;
struct elem;
alias Symbol symbol;
struct AA;
struct Outbuffer {}
struct jmp_buf {}
struct code;
struct block;
struct Blockx;
alias uint opflag_t;
struct PTRNTAB;
struct OP;
struct dt_t;
struct Config {};
struct Configv {};

struct IntRange;

alias byte int8_t;
alias ubyte uint8_t;
alias short int16_t;
alias ushort uint16_t;
alias int int32_t;
alias uint uint32_t;
alias long int64_t;
alias ulong uint64_t;

alias long targ_llong;
alias size_t targ_size_t;

alias real longdouble;
alias uint regm_t;
alias uint tym_t;
alias uint list_t;
alias uint idx_t;

enum TARGET_LINUX = 0;
enum TARGET_OSX = 0;
enum TARGET_FREEBSD = 0;
enum TARGET_OPENBSD = 0;
enum TARGET_SOLARIS = 0;
enum TARGET_WINDOS = 1;
enum _WIN32 = 1;

enum I64 = false;
