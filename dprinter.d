
import std.conv;
import std.algorithm;
import std.stdio;
import std.string;
import std.path;

import tokens;
import ast;
import visitor;
import scanner;
import typenames;
import namer;

class DPrinter : Visitor
{
    void delegate(string) target;
    Scanner scan;
    this(void delegate(string) target, Scanner scan)
    {
        this.target = target;
        this.scan = scan;
    }

    Expression E;
    StructDeclaration P;
    Type inittype;
    string[] stackclasses;
    FuncDeclaration fd;
    Declaration D;
    Declaration D2;
    SwitchStatement sswitch;
    string[] buffers;

    int indent;
    bool wasnl;
    int inexternc;
    bool instaticif;

    void print(string arg)
    {
        if (wasnl)
            foreach(i; 0..indent)
                target("    ");
        target(arg);
        wasnl = false;
    }
    void println(string arg)
    {
        if (wasnl && arg.length)
            foreach(i; 0..indent)
                target("    ");
        target(arg);
        target("\n");
        wasnl = true;
    }
    void lparen(Expression ast)
    {
        if (ast.hasParens)
            print("(");
    }
    void rparen(Expression ast)
    {
        if (ast.hasParens)
            print(")");
    }

    void maybeBuffer(Expression e)
    {
        if (auto ie = cast(IdentExpr)e)
        {
            if (buffers.canFind(ie.id))
            print(".ptr");
        }
    }
    void printArgs(Expression[] args)
    {
        foreach(i, a; args)
        {
            if (i)
                print(", ");
            visitX(a);
            maybeBuffer(a);
        }
    }
    void printParams(Param[] args)
    {
        foreach(i, a; args)
        {
            visitX(a);
            if (i != args.length - 1)
                print(", ");
        }
    }
    void visitX()(int stc)
    {
        static immutable names = ["static", "enum", "extern", "extern(C)", "virtual", "__cdecl", "abstract", "__inline", "register"];
        bool one;
        assert(!(stc & STCconst));
        /*if (!(stc & STCvirtual))
            print("final ");*/
        stc &= ~STCvirtual;
        stc &= ~STCregister;
        stc &= ~STCinline;
        stc &= ~STCcdecl;
        foreach(i, n; names)
        {
            if (stc & (1 << i))
            {
                print(names[i]);
                print(" ");
                one = true;
            }
        }
    }
    void visitX(int line = __LINE__)(Ast ast)
    {
        if (!ast)
            writeln(line);
        assert(ast);

        auto saveE = E;
        auto saveP = P;
        auto saveD = D;
        auto saveD2 = D2;
        if (cast(Expression)ast) E = cast(Expression)ast;
        if (cast(StructDeclaration)ast) E = null;
        if (cast(AnonStructDeclaration)ast) E = null;
        if (cast(StructDeclaration)ast) P = cast(StructDeclaration)ast;
        if (cast(Declaration)ast)
        {
            D2 = D;
            D = cast(Declaration)ast;
        }

        ast.visit(this);
        
        P = saveP;
        E = saveE;
        D = saveD;
        D2 = saveD2;
    }
    void visitX(T)(T[] arr) if (is(typeof(visitX(arr[0]))) && !is(T[] : string))
    {
        foreach(v; arr)
            visitX(v);
    }

    /////////////////////////////////////////////////////////////////////
    
    void visitIdent(string s)
    {
        switch(s)
        {
        case "NULL": print("null"); return;
        case "__IMPORT__": print("\"v\" ~ import(\"VERSION\")[0..$-1]"); return;
        case "import", "module", "version", "ref", "scope",
            "body", "alias", "is",
            "delegate", "cast", "mangleof",
            "foreach", "super", "init", "tupleof":
            print("_");
            print(s);
            return;
        default:
            print(s);
            return;
        }
    }

    override void visit(FuncDeclaration ast)
    {
        auto stackclassessave = stackclasses;
        scope(exit) stackclasses = stackclassessave;
        auto fdsave = fd;
        scope(exit) fd = fdsave;
        fd = ast;
        buffers = null;
        if (ast.id == "operator new") return;
        if (ast.id == "main")
        {
            println("int main()");
            println("{");
            indent++;
            println("import core.memory;");
            println("GC.disable();");
            println("import core.runtime;");
            println("auto args = Runtime.cArgs();");
            println("return tryMain(args.argc, cast(const(char)**)args.argv);");
            indent--;
            println("}");
            println("");
            return;
        }
        if (!P && !ast.hasbody && ast.skip) return;
        auto dropdefaultctor = ["Loc", "Token", "HdrGenState", "CtfeStack", "InterState", "BaseClass", "Mem", "StringValue", "OutBuffer", "Scope", "DocComment", "PrefixAttributes"];
        if (ast.type.id == ast.id && ast.params.length == 0 && dropdefaultctor.canFind(ast.id))
            return; // Can't have no-args ctor, and Loc/Token doesn't need one
        if (ast.comment)
            printComment(ast.comment);
        bool isvirtual = (ast.stc & STCvirtual) != 0;
        // if (!isvirtual && ast.id == "visit")
        // {
            // print("override ");
        // }
        foreach(m; overridenFuncs)
        {
            if (m[0] == "Type" && m[1] == "size" && ast.params.length != 0)
            {
            }
            else if ((m[0] == "*" || P && m[0] == P.id) &&
                     (m[1] == "*" || m[1] == ast.id))
            {
                isvirtual = true;
                break;
            }
        }
        auto nonfinalclass = P && nonFinalClasses.canFind(P.id);
        // if (ast.stc & STCvirtual)
            // print("virtual ");
        if (!isvirtual && !(ast.stc & STCabstract) && nonfinalclass)
            print("final ");
        if (!inexternc && (!P || !classTypes.lookup(P.id)) && ast.type.id != ast.id)
            print("extern(C++) ");
        visitX(ast.stc);
        if (ast.type.id == ast.id)
        {
            print("extern(D) this");
        } else if (ast.id[0] == '~')
        {
            print("~this");
        } else {
            visitX(ast.type);
            print(" ");
            visitIdent(ast.id);
        }
        print("(");
        printParams(ast.params);
        print(")");
        if (ast.initlist.length)
        {
            assert(ast.hasbody);
            println("");
            println("{");
            indent++;
            // println("mixin(dmd_trace_code);");
            if (ast.initlist.length == 1 && classTypes.lookup((cast(IdentExpr)ast.initlist[0].func).id))
            {
                print("super(");
                printArgs(ast.initlist[0].args);
                println(");");
            }
            else
            {
                foreach(i; ast.initlist)
                {
                    if (i.args.length == 0)
                        continue;
                    print("this.");
                    visitX(i.func);
                    print(" = ");
                    assert(i.args.length == 1);
                    visitX(i.args);
                    println(";");
                }
            }
            foreach(s; ast.fbody)
                visitX(s);
            indent--;
            println("}");
        } else if (ast.hasbody)
        {
            println("");
            println("{");
            indent++;
            // println("mixin(dmd_trace_code);");
            foreach(s; ast.fbody)
                visitX(s);
            indent--;
            println("}");
        } else {
            println(";");
        }
        println("");
    }

    override void visit(FuncBodyDeclaration ast)
    {
    }

    override void visit(StaticMemberVarDeclaration ast)
    {
    }

    override void visit(VarDeclaration ast)
    {
        if (ast.stc & STCextern) return;
        if (ast.id == "ASYNCREAD") return;
        bool manifest;
        auto at = cast(ArrayType)ast.type;
        if (!D2)
            ast.stc &= ~STCstatic;
        if (!ast.type)
            manifest = true;
        bool realarray;
        if (ast.type && !ast.xinit && at && at.dim)
            realarray = true;
        if (fd && !(ast.stc & STCstatic) && !cast(AnonStructDeclaration)D2)
            realarray = false;
        if (ast.comment)
            printComment(ast.comment);
        if (!ast.xinit && at && at.dim && !realarray && !cast(StructDeclaration)D2 && !cast(AnonStructDeclaration)D2)
        {
            visitX((ast.stc & STCstatic) | STCvirtual);
            visitX(at.next);
            print("[");
            visitX(at.dim);
            print("] ");
            print(ast.id);
            assert(!ast.trailingcomment);
            if (!E)
                println(";");
            buffers ~= ast.id;
            return;
        }
        bool gshared;
        if ((ast.stc & STCstatic) && !cast(FuncDeclaration)D2 && P)
        {
            // foreach(vd; scan.staticMemberVarDeclarations)
            // {
                // if (P.id == vd.id && ast.id == vd.id2)
                // {
                    // //writeln("found value for ", vd.id, "::", vd.id2);
                    // ast.xinit = vd.xinit;
                // }
            // }
            if (!manifest) print("extern(C++) ");
            if (!manifest) gshared = true;
        }
        else if (ast.stc & STCstatic)
        {
            if (!manifest) gshared = true;
        }
        else if (!P && !fd && !manifest)
        {
            print("extern(C++) ");
            gshared = true;
        }
        if (manifest)
            print("enum");
        else
        {
            visitX(ast.stc | STCvirtual);
            if (gshared)
                print("__gshared");
        }
        ExprInit ei = ast.xinit ? cast(ExprInit)ast.xinit : null;
        NewExpr ne = ei ? cast(NewExpr)ei.e : null;
        PointerType pt = ast.type ? cast(PointerType)ast.type : null;
        if (pt && ne && ne.t.id == pt.next.id)
        {
            if (manifest || gshared || (ast.stc & (STCstatic | STCconst | STCexternc)))
                print(" ");
            print("auto");
        }
        else if (ast.type)
        {
            if (manifest || gshared || (ast.stc & (STCstatic | STCconst | STCexternc)))
                print(" ");
            if (realarray)
            {
                visitX(at.next);
                print("[");
                visitX(at.dim);
                print("]");
            }
            else
                visitX(ast.type);
        }
        print(" ");
        visitIdent(ast.id);
        if (ast.xinit)
        {
            print(" = ");
            this.inittype = ast.type;
            visitX(ast.xinit);
            inittype = null;
        }
        else if (isClass(ast.type))
        {
            stackclasses ~= ast.id;
            print(" = new ");
            visitX(ast.type);
            print("()");
        }
        if (!E)
        {
            if (ast.trailingcomment)
            {
                print("; ");
                println(ast.trailingcomment.strip);
            }
            else
            {
                println(";");
            }
        }
    }

    override void visit(MultiVarDeclaration ast)
    {
        assert(fd && E);
        foreach(t; ast.types[0..$])
            assert(t && typeMatch(t, ast.types[0]));
        foreach(i; 0..ast.types.length)
        {
            if (i)
                println(", ");
            else
            {
                visitX(ast.stc | STCvirtual);
                visitX(ast.types[i]);
                print(" ");
            }
            visitIdent(ast.ids[i]);
            if (ast.inits[i])
            {
                print(" = ");
                this.inittype = ast.types[i];
                visitX(ast.inits[i]);
                inittype = null;
            }
        }
    }

    bool isClass(Type t)
    {
        if (auto ct = cast(ClassType)t)
        {
            auto id = ct.id;
            if (id.startsWith("class "))
                id = id[6..$];
            if (classTypes.lookup(id))
                return true;
            foreach(sd; scan.structsUsingInheritance)
            {
                if (sd.id == id)
                {
                    return true;
                }
            }
            if (rootClasses.lookup(id))
                return true;
        }
        return false;
    }

    override void visit(ConstructDeclaration ast)
    {
        stackclasses ~= ast.id;
        visitX(new PointerType(ast.type));
        print(" ");
        visitIdent(ast.id);
        print(" = new ");
        visitX(ast.type);
        print("(");
        printArgs(ast.args);
        print(")");
    }

    void versionCommon(T)(T ast)
    {
        foreach(i, c; ast.cond)
        {
            if (c)
            {
                if (i)
                    print("else ");
                auto ie = cast(IdentExpr)c;
                auto le = cast(LitExpr)c;
                if (ie)
                {
                    switch(ie.id)
                    {
                    case "DEBUG":          println("debug"); break;
                    case "UNITTEST":       println("version(unittest)"); break;

                    case "_WIN32":         println("version(Windows)"); break;
                    case "POSIX":          println("version(Posix)"); break;
                    case "__linux__":      println("version(linux)"); break;
                    case "__APPLE__":
                    case "MACINTOSH":      println("version(OSX)"); break;
                    case "__FreeBSD__":    println("version(FreeBSD)"); break;
                    case "__OpenBSD__":    println("version(OpenBSD)"); break;
                    case "__sun":          println("version(Solaris)"); break;

                    case "IN_GCC":         println("version(GNU)"); break;

                    case "DMDV1":          println("version(DMDV1)"); break;
                    case "DMDV2":          println("version(DMDV2)"); break;

                    default:               println("static if (" ~ ie.id ~ ")"); break;
                    }
                }
                else if (le)
                {
                    switch(le.val)
                    {
                    case "0": println("version(none)"); break;
                    case "1": println("version(all)"); break;
                    default:  assert(0);
                    }
                }
                else
                {
                    print("static if (");
                    instaticif = true;
                    visitX(c);
                    instaticif = false;
                    println(")");
                }
            }
            else
            {
                println("else");
            }
            println("{");
            indent++;
            visitX(ast.members[i]);
            indent--;
            println("}");
        }
    }

    override void visit(VersionDeclaration ast)
    {
        if (ast.comment)
            printComment(ast.comment);
        if (ast.getName() == "version typedef dinteger_t")
        {
            println("");
            println("// Be careful not to care about sign when using dinteger_t");
            println("// use this instead of integer_t to");
            println("// avoid conflicts with system #include's");
            println("alias dinteger_t = ulong;");
            println("// Signed and unsigned variants");
            println("alias sinteger_t = long;");
            println("alias uinteger_t = ulong;");
            println("");
            return;
        }
        versionCommon(ast);
    }

    override void visit(TypedefDeclaration ast)
    {
        if (ast.comment)
            printComment(ast.comment);
        if (auto ft = cast(FunctionType)ast.t)
        {
            if (ft.cdecl)
                print("extern(C) ");
            else
                print("extern(C++) ");
        }
        if (ast.id == "utf8_t")
            return;
        print("alias ");
        visitX(ast.t);
        print(" ");
        visitIdent(ast.id);
        println(";");
    }

    override void visit(MacroDeclaration ast)
    {
        if (ast.id == "assert") return;

        auto tParams = ["T", "U", "V", "W", "X", "Y"];

        if (ast.comment)
            printComment(ast.comment);
        print("auto ");
        visitIdent(ast.id);
        print("(");
        foreach(i, id; tParams[0..ast.params.length])
        {
            print(id);
            if (i != ast.params.length - 1)
                print(", ");
        }
        print(")(");
        foreach(i, id; ast.params)
        {
            print(tParams[i]);
            print(" ");
            print(id);
            if (i != ast.params.length - 1)
                print(", ");
        }
        print(") { return ");
        visitX(ast.e);
        println("; }");
    }

    override void visit(MacroUnDeclaration ast)
    {
    }

    override void visit(StructDeclaration ast)
    {
        bool isclass;
        if (ast.comment)
            printComment(ast.comment);
        if (ast.superid || rootClasses.lookup(ast.id))
            isclass = true;
        if (isclass)
        {
            print("extern(C++) ");
            if (!nonFinalClasses.canFind(ast.id))
                print("final ");
            print("class");
        }
        else
            print(ast.kind);
        print(" ");
        visitIdent(ast.id);
        if (ast.superid)
        {
            print(" : ");
            visitIdent(ast.superid);
        }
        // else if (isclass)
            // print(" : RootObject");
        println("");
        println("{");
        indent++;
        if (ast.superid == "Visitor" || ast.superid == "StoppableVisitor" || ast.superid == "StatementRewriteWalker")
        {
            // base class aliasing rules are different in C++
            println("alias visit = super.visit;");
        }
        foreach(d; ast.decls)
            visitX(d);
        indent--;
        println("}");
        println("");
    }

    override void visit(AnonStructDeclaration ast)
    {
        print(ast.kind);
        if (ast.id)
        {
            print(" __AnonStruct__");
            visitIdent(ast.id);
            println("");
        } else
            println("");
        println("{");
        foreach(d; ast.decls)
            visitX(d);
        if (ast.id)
        {
            println("};");
            print("__AnonStruct__");
            visitIdent(ast.id);
            print(" ");
            visitIdent(ast.id);
        } else {
            println("}");
        }
        if (!E)
            println(";");
    }

    override void visit(ExternCDeclaration ast)
    {
        if (ast.comment)
            printComment(ast.comment);
        println("extern(C) {");
        inexternc++;
        foreach(d; ast.decls)
            visitX(d);
        inexternc--;
        println("}");
    }

    override void visit(EnumDeclaration ast)
    {
        print("enum ");
        visitIdent(ast.id);
        println(" : int");
        println("{");
        indent++;
        foreach(m; ast.members)
        {
            if (m.id)
            {
                visitIdent(m.id);
                if (m.val)
                {
                    print(" = ");
                    visitX(m.val);
                }
                if (m.comment)
                {
                    print(", ");
                    println(m.comment.strip);
                }
                else
                    println(",");
            }
            else
            {
                printComment(m.comment.strip);
            }
        }
        indent--;
        println("}");
        if (ast.id)
        {
            foreach(m; ast.members)
            {
                if (!m.id)
                    continue;
                print("alias ");
                visitIdent(m.id);
                print(" = ");
                visitIdent(ast.id);
                print(".");
                visitIdent(m.id);
                println(";");
            }
        }
        println("");
    }

    override void visit(ErrorDeclaration ast)
    {
        print("static assert(0, ");
        visitX(ast.e);
        print(")");
        if (!E)
            println(";");
    }

    override void visit(ProtDeclaration ast)
    {
        indent--;
        print(ast.id);
        println(":");
        indent++;
    }

    override void visit(LitExpr ast)
    {
        if (ast.val.endsWith("L", "l"))
        {
            print(ast.val[0..$-1]);
        } else {
            print(ast.val);
        }
    }

    override void visit(IdentExpr ast)
    {
        if (ast.id == "this" && P)
        {
            if (P && structTypes.lookup(P.id))
            {
                print("&this");
                return;
            }
        }
        visitIdent(ast.id);
    }

    override void visit(DotIdExpr ast)
    {
        // bypass this -> &this for lhs
        auto ie = cast(IdentExpr)ast.e;
        if (ie && ie.id == "this")
            print("this");
        else
            visitX(ast.e);
        print(".");
        visitIdent(ast.id);
    }

    override void visit(CallExpr ast)
    {
        auto ie = cast(IdentExpr)ast.func;
        if (instaticif && ie && ie.id == "defined")
        {
            assert(ast.args.length == 1);
            visitX(ast.args[0]);
            return;
        }
        else if (ie && ie.id == "va_start")
        {
            assert(ast.args.length == 2);
            print("version(X86_64) va_start(");
            visitX(ast.args[0]);
            print(", __va_argsave); else va_start(");
            printArgs(ast.args);
            print(")");
            return;
        }
        if (ie && ie.id == "memcmp")
        {
            auto le = cast(LitExpr)ast.args[1];
            if (le && le.val[0] == '"')
            {
                ast.args[1] = new CastExpr(new PointerType(new BasicType("char")), ast.args[1]);
            }
        }
        visitX(ast.func);
        print("(");
        printArgs(ast.args);
        print(")");
    }

    override void visit(CmpExpr ast)
    {
        auto ie1 = cast(IdentExpr)ast.e1;
        auto ie2 = cast(IdentExpr)ast.e2;
        auto n1 = ie1 && ie1.id == "NULL";
        auto n2 = ie2 && ie2.id == "NULL";

        lparen(ast);
        visitX(ast.e1);
        maybeBuffer(ast.e1);
        print(" ");
        if ((n1 || n2) && ast.op == "==")
            print("is");
        else if ((n1 || n2) && ast.op == "!=")
            print("!is");
        else
            print(ast.op);
        print(" ");
        visitX(ast.e2);
        maybeBuffer(ast.e2);
        rparen(ast);
    }

    override void visit(MulExpr ast)
    {
        lparen(ast);
        visitX(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visitX(ast.e2);
        rparen(ast);
    }

    override void visit(AddExpr ast)
    {
        lparen(ast);
        visitX(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visitX(ast.e2);
        rparen(ast);
    }

    override void visit(OrOrExpr ast)
    {
        lparen(ast);
        visitX(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visitX(ast.e2);
        rparen(ast);
    }

    override void visit(AndAndExpr ast)
    {
        lparen(ast);
        visitX(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visitX(ast.e2);
        rparen(ast);
    }

    override void visit(OrExpr ast)
    {
        lparen(ast);
        visitX(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visitX(ast.e2);
        rparen(ast);
    }

    override void visit(XorExpr ast)
    {
        lparen(ast);
        visitX(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visitX(ast.e2);
        rparen(ast);
    }

    override void visit(AndExpr ast)
    {
        lparen(ast);
        visitX(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visitX(ast.e2);
        rparen(ast);
    }

    override void visit(AssignExpr ast)
    {
        lparen(ast);
        visitX(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visitX(ast.e2);
        maybeBuffer(ast.e2);
        rparen(ast);
    }

    override void visit(DeclarationExpr ast)
    {
        visitX(ast.d);
    }

    override void visit(PostExpr ast)
    {
        lparen(ast);
        visitX(ast.e);
        print(ast.op);
        rparen(ast);
    }

    override void visit(PreExpr ast)
    {
        lparen(ast);
        print(ast.op);
        visitX(ast.e);
        rparen(ast);
    }

    override void visit(PtrExpr ast)
    {
        lparen(ast);
        print("*");
        visitX(ast.e);
        rparen(ast);
    }

    override void visit(AddrExpr ast)
    {
        if (auto ie = cast(IdentExpr)ast.e)
        {
            if (stackclasses.canFind(ie.id))
            {
                visitX(ast.e);
                return;
            }
        }
        lparen(ast);
        print("&");
        visitX(ast.e);
        rparen(ast);
    }

    override void visit(NegExpr ast)
    {
        lparen(ast);
        print("-");
        visitX(ast.e);
        rparen(ast);
    }

    override void visit(ComExpr ast)
    {
        lparen(ast);
        print("~");
        visitX(ast.e);
        rparen(ast);
    }

    override void visit(DeleteExpr ast)
    {
        print("/*delete*/");
    }

    override void visit(NotExpr ast)
    {
        lparen(ast);
        print("!");
        visitX(ast.e);
        rparen(ast);
    }

    override void visit(IndexExpr ast)
    {
        visitX(ast.e);
        print("[");
        printArgs(ast.args);
        print("]");
    }

    override void visit(CondExpr ast)
    {
        lparen(ast);
        visitX(ast.cond);
        print(" ? ");
        visitX(ast.e1);
        maybeBuffer(ast.e1);
        print(" : ");
        visitX(ast.e2);
        maybeBuffer(ast.e2);
        rparen(ast);
    }

    override void visit(CastExpr ast)
    {
        lparen(ast);
        print("cast(");
        visitX(ast.t);
        print(")");
        visitX(ast.e);
        rparen(ast);
    }

    override void visit(NewExpr ast)
    {
        if (ast.dim)
        {
            assert(!ast.args.length);
            lparen(ast);
            print("new ");
            visitX(ast.t);
            print("[](");
            visitX(ast.dim);
            print(")");
            rparen(ast);
        }
        else
        {
            lparen(ast);
            print("new ");
            visitX(ast.t);
            print("(");
            printArgs(ast.args);
            print(")");
            rparen(ast);
        }
    }

    override void visit(OuterScopeExpr ast)
    {
        print(".");
        visitX(ast.e);
    }

    override void visit(CommaExpr ast)
    {
        lparen(ast);
        visitX(ast.e1);
        print(", ");
        visitX(ast.e2);
        rparen(ast);
    }

    override void visit(SizeofExpr ast)
    {
        if (ast.t && isClass(ast.t))
        {
            print("__traits(classInstanceSize, ");
            visitX(ast.t);
            print(")");
        }
        else
        {
            print("(");
            if (ast.e)
                visitX(ast.e);
            else
                visitX(ast.t);
            print(").sizeof");
        }
    }

    override void visit(ExprInit ast)
    {
        visitX(ast.e);
    }

    override void visit(ArrayInit ast)
    {
        if (auto ts = cast(ClassType)inittype)
        {
            print(ts.id);
            print("(");
            foreach(i, v; ast.xinit)
            {
                if (i)
                    print(", ");
                visitX(v);
            }
            print(")");
        }
        else if (auto at = cast(ArrayType)inittype)
        {
            auto inittypesave = inittype;
            scope(exit) inittype = inittypesave;
            inittype = at.next;
            if (ast.xinit.length < 10)
            {
                print("[ ");
                foreach(i, v; ast.xinit)
                {
                    if (i)
                        print(", ");
                    visitX(v);
                }
                print(" ]");
            }
            else
            {
                // multiline
                println("");
                println("[");
                indent++;
                foreach(i, v; ast.xinit)
                {
                    if (i)
                        println(",");
                    visitX(v);
                }
                println("");
                indent--;
                println("]");
            }
        }
    }

    override void visit(BasicType ast)
    {
        if (ast.isConst)
            print("const(");
        
        auto map =
        [
            "unsigned char" : "ubyte",
            "signed char" : "byte",
            "long long" : "long",
            "longlong" : "long",
            "ulonglong" : "ulong",
            "longdouble" : "real",
            "volatile_longdouble" : "real",
            "unsigned long long" : "ulong",
            "unsigned short" : "ushort",
            "unsigned" : "uint",
            "unsigned int" : "uint",
            "unsigned long" : "uint",
            "_Complex long double" : "creal",
            "volatile char" : "char",
            "utf8_t" : "char",
        ];
        
        if (ast.id in map)
        {
            print(map[ast.id]);
        } else {
            print(ast.id);
        }
        if (ast.isConst)
            print(")");
    }

    override void visit(ClassType ast)
    {
        if (ast.isConst)
            print("const(");
        if (ast.id == "struct stat")
        {
            print("stat_t");
        }
        else if (ast.id.length > 7 && ast.id[0..7] == "struct ")
        {
            assert(ast.id[7..$] != "stat");
            visitIdent(ast.id[7..$]);
        }
        else if (ast.id.length > 6 && ast.id[0..6] == "class ")
        {
            assert(ast.id[6..$] != "stat");
            visitIdent(ast.id[6..$]);
        }
        else 
        {
            visitIdent(ast.id);
        }
        if (ast.isConst)
            print(")");
    }

    override void visit(PointerType ast)
    {
        if (ast.isConst)
            print("const(");
        visitX(ast.next);
        if (!isClass(ast.next))
            print("*");
        if (ast.isConst)
            print(")");
    }

    override void visit(RefType ast)
    {
        print("ref ");
        visitX(ast.next);
    }

    override void visit(ArrayType ast)
    {
        visitX(ast.next);
        print("*");
    }

    override void visit(FunctionType ast)
    {
        visitX(ast.next);
        print(" function(");
        printParams(ast.params);
        print(")");
    }

    override void visit(TemplateType ast)
    {
        visitX(ast.next);
        print("!(");
        visitX(ast.param);
        print(")");
    }

    override void visit(Param ast)
    {
        if (ast.id == "...")
            print(ast.id);
        else
        {
            visitX(ast.t);
            print(" ");
            if (ast.id)
                visitIdent(ast.id);
            // else
                // assert(!ast.def);
            if (ast.def)
            {
                print(" = ");
                visitX(ast.def);
            }
        }
    }

    override void visit(CompoundStatement ast)
    {
        auto stackclassessave = stackclasses;
        scope(exit) stackclasses = stackclassessave;
        auto bufferssave = buffers;
        scope(exit) buffers = bufferssave;
        println("{");
        indent++;
        visitX(ast.s);
        indent--;
        println("}");
    }

    void printComment(string c)
    {
        bool block;
        foreach(i, l; c.splitLines)
        {
            auto lx = l.strip;
            if (!block)
            {
                if (lx.startsWith("/*"))
                {
                    block = true;
                }
                else
                {
                    assert(lx.startsWith("//"));
                    println(lx);
                }
            }
            if (block)
            {
                if (!lx.startsWith("/*"))
                {
                    print(" ");
                }
                println(lx);
                if (lx.endsWith("*/"))
                {
                    block = false;
                }
            }
        }
    }

    override void visit(CommentStatement ast)
    {
        printComment(ast.comment);
    }

    override void visit(ReturnStatement ast)
    {
        print("return");
        if (ast.e)
        {
            print(" ");
            visitX(ast.e);
        }
        if (ast.trailingcomment)
        {
            print("; ");
            println(ast.trailingcomment.strip);
        }
        else
            println(";");
    }

    override void visit(ExpressionStatement ast)
    {
        if (ast.e)
        {
            visitX(ast.e);
            if (ast.trailingcomment)
            {
                print("; ");
                println(ast.trailingcomment.strip);
            }
            else
                println(";");
        } else {
            if (ast.trailingcomment)
            {
                print("{} ");
                println(ast.trailingcomment.strip);
            }
            else
                println("{}");
        }
    }

    override void visit(VersionStatement ast)
    {
        auto ne = cast(NotExpr)ast.cond[0];
        auto ie = ne ? cast(IdentExpr)ne.e : null;
        if (ie && ie.id == "SYSCONFDIR")
        {
            println("enum SYSCONFDIR = \"/etc/dmd.conf\";");
            return;
        }
        ie = cast(IdentExpr)ast.cond[0];
        if (ie && ie.id == "DDMD")
        {
            visitX(ast.members[0]);
            return;
        }
        versionCommon(ast);
    }

    override void visit(IfStatement ast)
    {
        print("if (");
        visitX(ast.e);
        if (ast.trailingcomment)
        {
            print(") ");
            println(ast.trailingcomment.strip);
        }
        else
        {
            println(")");
        }
        if (!cast(CompoundStatement)ast.sbody)
            indent++;
        visitX(ast.sbody);
        if (!cast(CompoundStatement)ast.sbody)
            indent--;
        if (ast.selse)
        {
            print("else");
            auto elseisif = cast(IfStatement)ast.selse !is null;
            if (elseisif)
                print(" ");
            else
                println("");
            if (!cast(CompoundStatement)ast.selse && !elseisif)
                indent++;
            visitX(ast.selse);
            if (!cast(CompoundStatement)ast.selse && !elseisif)
                indent--;
        }
    }

    override void visit(ForStatement ast)
    {
        print("for (");
        if (ast.xinit)
            visitX(ast.xinit);
        print(";");
        if (ast.cond)
        {
            print(" ");
            visitX(ast.cond);
        }
        print(";");
        if (ast.inc)
        {
            print(" ");
            visitX(ast.inc);
        }
        println(")");
        if (!cast(CompoundStatement)ast.sbody)
            indent++;
        visitX(ast.sbody);
        if (!cast(CompoundStatement)ast.sbody)
            indent--;
    }

    override void visit(SwitchStatement ast)
    {
        auto sswitchsave = sswitch;
        scope(exit) sswitch = sswitchsave;
        sswitch = ast;
        print("switch (");
        visitX(ast.e);
        println(")");
        println("{");
        indent++;
        foreach(s; ast.sbody)
            visitX(s);
        if (!ast.hasdefault)
        {
            indent--;
            println("default:");
            indent++;
            println("break;");
        }
        indent--;
        println("}");
    }

    override void visit(CaseStatement ast)
    {
        indent--;
        print("case ");
        visitX(ast.e);
        println(":");
        indent++;
    }

    override void visit(BreakStatement ast)
    {
        println("break;");
    }

    override void visit(ContinueStatement ast)
    {
        println("continue;");
    }

    override void visit(DefaultStatement ast)
    {
        assert(sswitch);
        sswitch.hasdefault = true;
        indent--;
        println("default:");
        indent++;
    }

    override void visit(WhileStatement ast)
    {
        print("while (");
        visitX(ast.e);
        println(")");
        if (!cast(CompoundStatement)ast.sbody)
            indent++;
        visitX(ast.sbody);
        if (!cast(CompoundStatement)ast.sbody)
            indent--;
    }

    override void visit(DoWhileStatement ast)
    {
        println("do");
        if (!cast(CompoundStatement)ast.sbody)
            indent++;
        visitX(ast.sbody);
        if (!cast(CompoundStatement)ast.sbody)
            indent--;
        print("while (");
        visitX(ast.e);
        println(");");
    }

    override void visit(GotoStatement ast)
    {
        print("goto ");
        visitIdent(ast.id);
        println(";");
    }

    override void visit(LabelStatement ast)
    {
        indent--;
        visitIdent(ast.id);
        println(":");
        indent++;
    }

};
