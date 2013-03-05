
import std.stdio;
import std.array;
import std.conv;

import tokens;
import ast;

string preprocess(Lexer tokens, string fn)
{
    string r;
    size_t line = 1;
    Token next()
    {
        auto t = tokens.front;
        tokens.popFront();
        return t;
    }
    string text()
    {
        return tokens.front.text;
    }
    void dumpt(Token t)
    {
        while(line < t.line)
        {
            r ~= "\n";
            line++;
        }
        r ~= t.text;
        if (!t.flag)
            r ~= ' ';
    }
    void dump()
    {
        dumpt(tokens.front);
        next();
    }

    struct PP {
    bool parsePPCond()
    {
        auto l = tokens.front.line;
        Token[] etoks;
        while (l == tokens.front.line)
            etoks ~= next();
        auto e = parsePPExp(etoks);
        return eval(e) != 0;
    }
    Token[] parsePPInside()
    {
        Token[] r;
        while(!tokens.empty)
        {
            switch(text())
            {
            case "#else":
            case "#elif":
            case "#endif":
                return r;
            case "#if":
            case "#ifdef":
            case "#ifndef":
                r ~= parsePPBlock();
                break;
            default:
                r ~= next();
            }
        }
        assert(0);
    }

    Token[] parsePPBlock()
    {
        auto ndef = (text() == "#ifndef");
        next();
        auto c = parsePPCond();
        if (ndef)
            c = !c;
        auto t = parsePPInside();
        Token[] r;
        if (c)
            r = t;
        while(!tokens.empty && text() != "#endif")
        {
            switch(text())
            {
            case "#else":
                next();
                auto i = parsePPInside();
                if (!c)
                    r = i;
                break;
            case "#elif":
                next();
                auto nc = parsePPCond();
                auto i = parsePPInside();
                if (nc && !c)
                    r = i;
                c = c || nc;
                break;
            default:
                assert(0);
            }
        }
        assert(text() == "#endif");
        next();
        return r;
    }
    }
    PP pp;

    while(!tokens.empty)
    {
        if (text() == "#if" || text() == "#ifdef" || text() == "#ifndef")
        {
            auto toks = pp.parsePPBlock();
            foreach(t; toks)
                dumpt(t);
        }
        else
            dump();
    }

    return r;
}

Expression parsePPExp(ref Token[] toks)
{
    return parsePPOrOrExp(toks);
}

Expression parsePPOrOrExp(ref Token[] toks)
{
    auto e = parsePPAndAndExp(toks);
    while (toks.length && toks.front.text == "||")
    {
        toks.popFront();
        e = new OrOrExpr(e, parsePPAndAndExp(toks));
    }
    return e;
}

Expression parsePPAndAndExp(ref Token[] toks)
{
    auto e = parsePPEqualExp(toks);
    while (toks.length && toks.front.text == "||")
    {
        toks.popFront();
        e = new OrOrExpr(e, parsePPEqualExp(toks));
    }
    return e;
}

Expression parsePPEqualExp(ref Token[] toks)
{
    auto e = parsePPUnaExp(toks);
    while (toks.length && toks.front.text == "==")
    {
        toks.popFront();
        e = new CmpExpr("==", e, parsePPUnaExp(toks));
    }
    return e;
}

Expression parsePPUnaExp(ref Token[] toks)
{
    switch(toks.front.type)
    {
    case TOKid:
        if (toks.front.text == "defined")
        {
            toks.popFront();
            return parsePPUnaExp(toks);
        }
        auto e = new IdentExpr(toks.front.text);
        toks.popFront();
        return e;
    case TOKop:
        switch(toks.front.text)
        {
        case "!":
            toks.popFront();
            return new NotExpr(parsePPExp(toks));
        case "(":
            toks.popFront();
            auto e = parsePPExp(toks);
            assert(toks.front.text == ")", to!string(toks.front.line));
            toks.popFront();
            return e;
        default:
            assert(0, toks.front.text);
        }
    case TOKnum:
        auto t = toks.front.text;
        toks.popFront();
        return new LitExpr(t);
    default:
        assert(0, toks.front.text);
    }
}

private int eval(Expression e)
{
    if (auto le = cast(LitExpr)e)
    {
        switch(le.val)
        {
        case "2":
            return 2;
        case "1":
            return 1;
        case "0":
            return 0;
        default:
            assert(0, le.val);
        }
    } else if (auto ie = cast(IdentExpr)e)
    {
        switch(ie.id)
        {
        case "LOG":
        case "DEBUG":
        case "IN_GCC":
        case "MACHOBJ":
        case "DMDV1":
        case "EXTRA_DEBUG":
        case "linux":
        case "__APPLE__":
        case "__FreeBSD__":
        case "__OpenBSD__":
        case "__sun":
        case "SHOWPERFORMANCE":
        case "LOGASSIGN":
        case "TARGET_LINUX":
        case "TARGET_OSX":
        case "TARGET_FREEBSD":
        case "TARGET_OPENBSD":
        case "TARGET_SOLARIS":
        case "TARGET_NET":
        case "ASYNCREAD":
        case "WINDOWS_SEH":
        case "LITTLE_ENDIAN":
        case "ELFOBJ":
        case "_WINDLL":
        case "UNITTEST":
        case "CPP_MANGLE":
        case "__clang__":
        case "__GNUC__":
        case "__SVR4":
        case "MEM_DEBUG":
        case "GCC_SAFE_DMD":
        case "OUREH":
        case "_WIN64":
        case "STRINGTABLE":
        case "__MINGW32__":
        case "LOGDEFAULTINIT":
        case "LOGDOTEXP":
        case "LOGM":
        case "LOG_LEASTAS":
        case "FIXBUG8863":
        case "D1INOUT":
        case "CARRAYDECL":
        case "CCASTSYNTAX":
        case "__GLIBC__":
        case "CANINLINE_LOG":
        case "MODULEINFO_IS_STRUCT":
        case "POSIX":
        case "MACINTOSH":
        case "_POSIX_VERSION":
        case "PATH_MAX":
            return 0;
        case "DMDV2":
        case "__DMC__":
        case "TX86":
        case "TARGET_WINDOS":
        case "SARRAYVALUE":
        case "_WIN32":
        case "_MSC_VER":
        case "OMFOBJ":
        case "BREAKABI":
        case "UTIL_PH":
        case "SEH":
        case "MAGICPORT":
        case "SNAN_DEFAULT_INIT":
        case "LOGSEMANTIC":
        case "BUG6652":
        case "TEXTUAL_ASSEMBLY_OUT":
        case "INTERFACE_VIRTUAL":
            return 1;
        case "DOS386":
        case "DOS16RM":
        case "__SC__":
        case "MEMMODELS":
        case "HTOD":
        case "SCPP":
            return 0;
        case "MARS":
        case "DM_TARGET_CPU_X86":
        case "MMFIO":
        case "LINEARALLOC":
        case "_M_I86":
        case "LONGLONG":
            return 1;
        default:
            if (ie.id[$-2..$] == "_H") return false;
            assert(0, ie.id);
        }
    } else if (auto ne = cast(NotExpr)e)
    {
        return !eval(ne.e);
    } else if (auto aae = cast(AndAndExpr)e)
    {
        return eval(aae.e1) && eval(aae.e2);
    } else if (auto ooe = cast(OrOrExpr)e)
    {
        return eval(ooe.e1) || eval(ooe.e2);
    } else if (auto ce = cast(CallExpr)e)
    {
        auto ie = cast(IdentExpr)ce.func;
        assert(ie && ie.id == "defined");
        assert(ce.args.length == 1);
        return eval(ce.args[0]);
    } else if (auto ce = cast(CmpExpr)e)
    {
        assert(ce.op == "==");
        return eval(ce.e1) == eval(ce.e2);
    }
    assert(0, typeid(e).toString());
}
