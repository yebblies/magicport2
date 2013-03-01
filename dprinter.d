
import std.conv;
import std.algorithm;
import std.stdio;
import std.string;
import std.path;

import tokens;
import ast;
import visitor;
import scanner;


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

    void print(string arg)
    {
        target(arg);
    }
    void println(string arg)
    {
        target(arg);
        target("\n");
    }
    void printArgs(Expression[] args)
    {
        foreach(i, a; args)
        {
            visit(a);
            if (i != args.length - 1)
                print(", ");
        }
    }
    void printParams(Param[] args)
    {
        foreach(i, a; args)
        {
            visit(a);
            if (i != args.length - 1)
                print(", ");
        }
    }
    void visit()(int stc)
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
    void visit(int line = __LINE__)(Ast ast)
    {
        if (!ast)
            writeln(line);
        assert(ast);

        auto saveE = E;
        auto saveP = P;
        if (cast(Expression)ast) E = cast(Expression)ast;
        if (cast(StructDeclaration)ast) E = null;
        if (cast(AnonStructDeclaration)ast) E = null;
        if (cast(StructDeclaration)ast) P = cast(StructDeclaration)ast;

        ast.visit(this);
        
        P = saveP;
        E = saveE;
    }
    /*void visit(int line = __LINE__)(string ast)
    {
        if (!ast)
            writeln(line);
        assert(ast);
        print(ast);
    }*/
    void visit(T)(T[] arr) if (is(typeof(visit(arr[0]))) && !is(T[] : string))
    {
        foreach(v; arr)
            visit(v);
    }

    /////////////////////////////////////////////////////////////////////
    
    void visitIdent(string s)
    {
        auto list =
        [
            "import", "module", "version", "align", "dchar", "ref", "scope", "wchar", "pragma",
            "body", "real", "alias", "is", "invariant", "TypeInfo", "in", "byte", "debug", "inout",
            "override", "final", "toString", "delegate", "cast", "mangleof", "stringof",
            "enum", "foreach", "finally", "super",
        ];
        print(list.canFind(s) ? '_' ~ s : s);
    }
    
    override void visitModule(Module ast)
    {
        visit(ast.decls);
    }

    override void visitImportDeclaration(ImportDeclaration ast)
    {
        return;
        if (ast.fn == "assert.h")
            return;
        auto list =
        [
            "stdio.h" : "core.stdc.stdio",
            "stdlib.h" : "core.stdc.stdlib",
        ];
        if (ast.fn in list)
        {
            print("import ");
            print(list[ast.fn]);
            println(";");
            return;
        }
        auto v = split(ast.fn, "\\");
        assert(v.length == 1, v[0]);
        if (v[0].extension() == ".h" || v[0].extension() == "")
        {
            print("import ");
            visitIdent(v[0].stripExtension());
            print("; // ");
            println(ast.fn);
        } else
            assert(v[0].extension() == ".c");
    }

    override void visitFuncDeclaration(FuncDeclaration ast)
    {
        if (ast.id == "operator new") return;
        if (!P && !ast.fbody) return;
        visit(ast.stc);
        if (ast.type.id == ast.id)
        {
            print("this");
        } else if (ast.id[0] == '~')
        {
            print("~this");
        } else {
            visit(ast.type);
            print(" ");
            visitIdent(ast.id);
        }
        print("(");
        printParams(ast.params);
        print(")");
        if (ast.superargs)
        {
            assert(ast.fbody);
            println("");
            println("{");
            print("super(");
            printArgs(ast.superargs);
            println(");");
            visit(ast.fbody);
            println("}");
        } else if (ast.fbody)
        {
            println("");
            visit(ast.fbody);
        } else {
            FuncBodyDeclaration fbody;
            foreach(fb; scan.funcBodyDeclarations)
            {
                if (fb.id2 == ast.id && fb.id == P.id)
                {
                    //writeln(fb.id, "::", fb.id2);
                    if (fb.params.length == ast.params.length)
                    {
                        bool samep = true;
                        foreach(i, p; fb.params)
                        {
                            if (!typeMatch(p.t, ast.params[i].t))
                            {
                                samep = false;
                                break;
                            }
                        }
                        if (samep)
                        {
                            assert(!fbody, "Duplicate definition of: " ~ fb.id);
                            fbody = fb;
                        }
                    }
                }
            }
            println(";");
        }
    }

    override void visitFuncBodyDeclaration(FuncBodyDeclaration ast)
    {
    }

    override void visitStaticMemberVarDeclaration(StaticMemberVarDeclaration ast)
    {
    }

    override void visitVarDeclaration(VarDeclaration ast)
    {
        if (ast.stc & STCextern) return;
        foreach(i; 0..ast.types.length)
        {
            if (ast.types[i])
            {
                if (ast.ids[i] == "__locale_decpoint") return;
                visit(ast.stc | STCvirtual);
                visit(ast.types[i]);
                print(" ");
                visitIdent(ast.ids[i]);
                if (ast.inits[i])
                {
                    print(" = ");
                    visit(ast.inits[i]);
                }
                if (!E || i != ast.types.length - 1)
                    println(";");
            } else {
                if (ast.ids[i] == "LOG" || ast.ids[i] == "LOGSEMANTIC") return;
                assert(ast.stc & STCconst);
                print("enum ");
                visitIdent(ast.ids[i]);
                if (ast.inits[i])
                {
                    print(" = ");
                    visit(ast.inits[i]);
                } else {
                    print(" = 0");
                }
                println(";");
            }
        }
    }
    
    bool isClass(Type t)
    {
        if (auto ct = cast(ClassType)t)
        {
            foreach(sd; scan.structsUsingInheritance)
            {
                if (sd.id == ct.id)
                {
                    return true;
                }
            }
        }
        return false;
    }

    override void visitConstructDeclaration(ConstructDeclaration ast)
    {
        visit(ast.type);
        if (!isClass(ast.type))
            print("*");
        print(" ");
        visitIdent(ast.id);
        print(" = new ");
        visit(ast.type);
        print("(");
        printArgs(ast.args);
        print(")");
    }

    override void visitVersionDeclaration(VersionDeclaration ast)
    {
        auto conds = ast.es;
        auto decls = ast.ds;
        Declaration[] delse;
        if (!conds[$-1])
        {
            delse = decls[$-1];
            conds = conds[0..$-1];
            decls = decls[0..$-1];
        }
        
        bool anytrue;
        foreach(i, c; conds)
        {
            bool r;
            if (eval(c))
            {
                anytrue = true;
                visit(decls[i]);
                break;
            } else {
            }
        }
        if (!anytrue && delse)
            visit(delse);
    }

    override void visitTypedefDeclaration(TypedefDeclaration ast)
    {
        print("alias ");
        visit(ast.t);
        print(" ");
        visitIdent(ast.id);
        println(";");
    }

    override void visitMacroDeclaration(MacroDeclaration ast)
    {
        auto tParams = ["T", "U", "V", "W", "X", "Y"];

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
        println(")");
        print("{ return ");
        visit(ast.e);
        println("; }");
        /+foreach(i; 0..ast.toks.length)
        {
            assert(ast.toks[i].text != "##");
            assert(ast.toks[i].text != "#");
            print(ast.toks[i].text);
            print(" ");
            /+if (ast.toks[i].text == "##")
            {
                i++;
                print("\"");
                print(ast.toks[i].text);
                print("\"");
            }
            else if (ast.toks[i].text == "#")
            {
                i++;
                print(`"\"`);
                print(ast.toks[i].text);
                print(`\" "`);
            }
            else if (ast.params.canFind(ast.toks[i].text))
            {
                print("\" \" ~ ");
                print(ast.toks[i].text);
            }
            else
            {
                print("\" ");
                print(ast.toks[i].text);
                print("\"");
            }
            if (i != ast.toks.length - 1)
                print(" ~ ");+/
        }
        println("; }");
        
        /+auto ident(T)(T arg)
        {
            return "tok1 tok2 tok3 tok4 " ~ arg ~ "tok5 tok6 tok7";
        }
        
        foreach(t; ast.toks)
            writeln(t);+/+/
    }

    override void visitMacroUnDeclaration(MacroUnDeclaration ast)
    {
    }

    override void visitMacroCallDeclaration(MacroCallDeclaration ast)
    {
        print("mixin(");
        visitIdent(ast.id);
        print("(");
        foreach(i, id; ast.args)
        {
            print(id);
            if (i != ast.args.length - 1)
                print(", ");
        }
        println("));");
    }

    override void visitStructDeclaration(StructDeclaration ast)
    {
        if (ast.superid || ast.id == "Scope" || ast.id == "Section" ||
            ast.id == "DocComment" || ast.id == "Global" || ast.id == "BaseClass" ||
            ast.id == "Condition")
            print("class");
        else
            print(ast.kind);
        print(" ");
        visitIdent(ast.id);
        if (ast.superid)
        {
            print(" : ");
            visitIdent(ast.superid);
        }
        println("");
        println("{");
        foreach(d; ast.decls)
            visit(d);
        println("};");
    }

    override void visitAnonStructDeclaration(AnonStructDeclaration ast)
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
            visit(d);
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

    override void visitExternCDeclaration(ExternCDeclaration ast)
    {
        println("extern(C) {");
        foreach(d; ast.decls)
            visit(d);
        println("}");
    }

    override void visitEnumDeclaration(EnumDeclaration ast)
    {
        println("enum");
        println("{");
        foreach(i; 0..ast.members.length)
        {
            visitIdent(ast.members[i]);
            if (ast.vals[i])
            {
                print(" = ");
                visit(ast.vals[i]);
            }
            println(",");
        }
        println("};");
        print("alias uint ");
        visitIdent(ast.id);
        if (!E)
            println(";");
    }

    override void visitDummyDeclaration(DummyDeclaration ast)
    {
    }

    override void visitBitfieldDeclaration(BitfieldDeclaration ast)
    {
        assert(0);
    }

    override void visitProtDeclaration(ProtDeclaration ast)
    {
        print(ast.id);
        println(":");
    }

    override void visitAlignDeclaration(AlignDeclaration ast)
    {
        print("align(");
        if (ast.id)
            print(to!string(ast.id));
        println(")");
    }

    override void visitLitExpr(LitExpr ast)
    {
        if (ast.val.length > 2 && ast.val[$-2..$] == "LL")
        {
            print(ast.val[0..$-1]);
        } else {
            print(ast.val);
        }
    }

    override void visitIdentExpr(IdentExpr ast)
    {
        visitIdent(ast.id);
    }

    override void visitDotIdExpr(DotIdExpr ast)
    {
        visit(ast.e);
        print(".");
        visitIdent(ast.id);
    }

    override void visitCallExpr(CallExpr ast)
    {
        visit(ast.func);
        print("(");
        printArgs(ast.args);
        print(")");
    }

    override void visitCmpExpr(CmpExpr ast)
    {
        print("(");
        visit(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visit(ast.e2);
        print(")");
    }

    override void visitMulExpr(MulExpr ast)
    {
        print("(");
        visit(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visit(ast.e2);
        print(")");
    }

    override void visitAddExpr(AddExpr ast)
    {
        print("(");
        visit(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visit(ast.e2);
        print(")");
    }

    override void visitOrOrExpr(OrOrExpr ast)
    {
        print("(");
        visit(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visit(ast.e2);
        print(")");
    }

    override void visitAndAndExpr(AndAndExpr ast)
    {
        print("(");
        visit(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visit(ast.e2);
        print(")");
    }

    override void visitOrExpr(OrExpr ast)
    {
        print("(");
        visit(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visit(ast.e2);
        print(")");
    }

    override void visitXorExpr(XorExpr ast)
    {
        print("(");
        visit(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visit(ast.e2);
        print(")");
    }

    override void visitAndExpr(AndExpr ast)
    {
        print("(");
        visit(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visit(ast.e2);
        print(")");
    }

    override void visitAssignExpr(AssignExpr ast)
    {
        print("(");
        visit(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visit(ast.e2);
        print(")");
    }

    override void visitDeclarationExpr(DeclarationExpr ast)
    {
        visit(ast.d);
    }

    override void visitPostExpr(PostExpr ast)
    {
        print("(");
        visit(ast.e);
        print(ast.op);
        print(")");
    }

    override void visitPreExpr(PreExpr ast)
    {
        print("(");
        print(ast.op);
        visit(ast.e);
        print(")");
    }

    override void visitPtrExpr(PtrExpr ast)
    {
        print("(*");
        visit(ast.e);
        print(")");
    }

    override void visitAddrExpr(AddrExpr ast)
    {
        print("(&");
        visit(ast.e);
        print(")");
    }

    override void visitNegExpr(NegExpr ast)
    {
        print("(-");
        visit(ast.e);
        print(")");
    }

    override void visitComExpr(ComExpr ast)
    {
        print("(~");
        visit(ast.e);
        print(")");
    }

    override void visitDeleteExpr(DeleteExpr ast)
    {
    }

    override void visitNotExpr(NotExpr ast)
    {
        print("(!");
        visit(ast.e);
        print(")");
    }

    override void visitIndexExpr(IndexExpr ast)
    {
        visit(ast.e);
        print("[");
        printArgs(ast.args);
        print("]");
    }

    override void visitCondExpr(CondExpr ast)
    {
        print("(");
        visit(ast.cond);
        print("?");
        visit(ast.e1);
        print(":");
        visit(ast.e2);
        print(")");
    }

    override void visitCastExpr(CastExpr ast)
    {
        print("(cast(");
        visit(ast.t);
        print(")");
        visit(ast.e);
        print(")");
    }

    override void visitNewExpr(NewExpr ast)
    {
        assert(!ast.dim);
        print("(new ");
        visit(ast.t);
        print("(");
        printArgs(ast.args);
        print("))");
    }

    override void visitOuterScopeExpr(OuterScopeExpr ast)
    {
        print(".");
        visit(ast.e);
    }

    override void visitCommaExpr(CommaExpr ast)
    {
        print("(");
        visit(ast.e1);
        print(", ");
        visit(ast.e2);
        print(")");
    }

    override void visitSizeofExpr(SizeofExpr ast)
    {
        print("(");
        if (ast.e)
            visit(ast.e);
        else
            visit(ast.t);
        print(").sizeof");
    }

    override void visitExprInit(ExprInit ast)
    {
        visit(ast.e);
    }

    override void visitArrayInit(ArrayInit ast)
    {
        print("[ ");
        foreach(i, v; ast.init)
        {
            if (i)
                print(", ");
            visit(v);
        }
        print("]");
    }

    static bool typeMatch(Type t1, Type t2)
    {
        if (t1 == t2)
            return true;
        if (typeid(t1) != typeid(t2))
            return false;
        if (t1.id != t2.id)
            return false;
        if (cast(PointerType)t1)
            return typeMatch((cast(PointerType)t1).next, (cast(PointerType)t2).next);
        if (cast(RefType)t1)
            return typeMatch((cast(RefType)t1).next, (cast(RefType)t2).next);
        if (cast(ArrayType)t1)
            return typeMatch((cast(ArrayType)t1).next, (cast(ArrayType)t2).next);
        if (cast(FunctionType)t1)
        {
            auto tf1 = cast(FunctionType)t1;
            auto tf2 = cast(FunctionType)t2;
            auto m = typeMatch(tf1.next, tf2.next);
            if (!m) return false;
            assert(tf1.cdecl == tf2.cdecl);
            m = tf1.params.length == tf2.params.length;
            if (!m) return false;
            foreach(i; 0..tf1.params.length)
            {
                m = typeMatch(tf1.params[i].t, tf2.params[i].t);
                if (!m) return false;
            }
            foreach(i; 0..tf1.params.length)
                assert(tf1.params[i].id == tf2.params[i].id, "Param name mismatch");
            return true;
        }
        assert(cast(ClassType)t1 || cast(BasicType)t1 || cast(EnumType)t1, typeid(t1).toString());
        return true;
    }

    override void visitBasicType(BasicType ast)
    {
        if (ast.isConst)
            print("const(");
        
        auto map =
        [
            "unsigned char" : "ubyte",
            "signed char" : "byte",
            "unsigned long long" : "ulong",
            "unsigned short" : "ushort",
            "unsigned" : "uint",
            "unsigned long" : "uint",
            "_Complex long double" : "creal",
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

    override void visitClassType(ClassType ast)
    {
        if (ast.isConst)
            print("const(");
        if (ast.id.length > 7 && ast.id[0..7] == "struct ")
        {
            visitIdent(ast.id[7..$]);
        } else {
            visitIdent(ast.id);
        }
        if (ast.isConst)
            print(")");
    }

    override void visitEnumType(EnumType ast)
    {
        assert(!ast.isConst);
        assert(ast.id[0..5] == "enum ");
        visitIdent(ast.id[5..$]);
    }

    override void visitPointerType(PointerType ast)
    {
        visit(ast.next);
        if (!isClass(ast.next))
            print("*");
    }

    override void visitRefType(RefType ast)
    {
        print("ref ");
        visit(ast.next);
    }

    override void visitArrayType(ArrayType ast)
    {
        visit(ast.next);
        print("*");
    }

    override void visitFunctionType(FunctionType ast)
    {
        visit(ast.next);
        print(" function(");
        printParams(ast.params);
        print(")");
    }

    override void visitTemplateType(TemplateType ast)
    {
        visit(ast.next);
        print("!(");
        visit(ast.param);
        print(")");
    }

    override void visitParam(Param ast)
    {
        if (ast.id == "...")
            print(ast.id);
        else
        {
            visit(ast.t);
            print(" ");
            if (ast.id)
                visitIdent(ast.id);
            else
                assert(!ast.def);
            if (ast.def)
            {
                print(" = ");
                visit(ast.def);
            }
        }
    }

    override void visitCompoundStatement(CompoundStatement ast)
    {
        println("{");
        visit(ast.s);
        println("}");
    }

    override void visitReturnStatement(ReturnStatement ast)
    {
        print("return ");
        if (ast.e)
            visit(ast.e);
        println(";");
    }

    override void visitExpressionStatement(ExpressionStatement ast)
    {
        if (ast.e)
        {
            visit(ast.e);
            println(";");
        } else {
            println("{}");
        }
    }

    bool eval(Expression e)
    {
        if (auto le = cast(LitExpr)e)
        {
            switch(le.val)
            {
            case "1":
                return true;
            case "0":
                return false;
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
                return false;
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
                return true;
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
        }
        assert(0, typeid(e).toString());
    }

    override void visitVersionStatement(VersionStatement ast)
    {
        auto conds = ast.cond;
        auto stats = ast.s;
        Statement[] selse;
        if (!conds[$-1])
        {
            selse = stats[$-1];
            conds = conds[0..$-1];
            stats = stats[0..$-1];
        }
        
        bool anytrue;
        foreach(i, c; conds)
        {
            bool r;
            if (eval(c))
            {
                anytrue = true;
                visit(stats[i]);
                break;
            } else {
            }
        }
        if (!anytrue && selse)
            visit(selse);
        if (ast.selse)
            visit(ast.selse);
    }

    override void visitIfStatement(IfStatement ast)
    {
        print("if (");
        visit(ast.e);
        println(")");
        visit(ast.sbody);
        if (ast.selse)
        {
            print(" else ");
            visit(ast.selse);
        }
    }

    override void visitForStatement(ForStatement ast)
    {
        print("for (");
        if (ast.init)
            visit(ast.init);
        print("; ");
        if (ast.cond)
            visit(ast.cond);
        print("; ");
        if (ast.inc)
            visit(ast.inc);
        println(")");
        visit(ast.sbody);
    }

    override void visitSwitchStatement(SwitchStatement ast)
    {
        print("switch (");
        visit(ast.e);
        println(")");
        visit(ast.sbody);
    }

    override void visitCaseStatement(CaseStatement ast)
    {
        print("case ");
        visit(ast.e);
        println(":");
    }

    override void visitBreakStatement(BreakStatement ast)
    {
        println("break;");
    }

    override void visitContinueStatement(ContinueStatement ast)
    {
        println("continue;");
    }

    override void visitDefaultStatement(DefaultStatement ast)
    {
        println("default:");
    }

    override void visitWhileStatement(WhileStatement ast)
    {
        print("while (");
        visit(ast.e);
        println(")");
        visit(ast.sbody);
    }

    override void visitDoWhileStatement(DoWhileStatement ast)
    {
        println("do");
        visit(ast.sbody);
        print("while (");
        visit(ast.e);
        println(");");
    }

    override void visitGotoStatement(GotoStatement ast)
    {
        print("goto ");
        visitIdent(ast.id);
        println(";");
    }

    override void visitLabelStatement(LabelStatement ast)
    {
        visitIdent(ast.id);
        println(":");
    }

    override void visitDanglingElseStatement(DanglingElseStatement ast)
    {
        print(" else ");
        visit(ast.sbody);
    }

};
