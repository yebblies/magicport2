
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

auto parentlessclasses = ["Section", "Condition", "TemplateParameter", "Lexer", "RootObject", "Library", "Visitor"];

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
    bool align1;
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
    /*void visit(int line = __LINE__)(string ast)
    {
        if (!ast)
            writeln(line);
        assert(ast);
        print(ast);
    }*/
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
        case "I": print("1i"); return;
        case "NULL": print("null"); return;
        case "__IMPORT__": print("\"v\" ~ import(\"VERSION\")[0..$-1]"); return;
        case "import", "module", "version", "align", "dchar", "ref", "scope", "wchar", "pragma",
            "body", "real", "alias", "is", "invariant", "TypeInfo", "in", "byte", "debug", "inout",
            "override", "final", "toString", "delegate", "cast", "mangleof", "stringof",
            "enum", "foreach", "finally", "super", "unittest", "init", "tupleof",
            "Throwable", "typeinfo":
            print("_");
            print(s);
            return;
        default:
            print(s);
            return;
        }
    }
    
    override void visit(Module ast)
    {
        visitX(ast.decls);
    }

    override void visit(ImportDeclaration ast)
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
            print("; ");
            println(ast.fn);
        } else
            assert(v[0].extension() == ".c");
    }

    static overriddenfuncs =
    [
        ["AggregateDeclaration", "mangle"],
        ["AggregateDeclaration", "toDocBuffer"],
        ["AssignExp", "clone"],
        ["AttribDeclaration", "addComment"],
        ["AttribDeclaration", "addMember"],
        ["AttribDeclaration", "emitComment"],
        ["AttribDeclaration", "kind"],
        ["AttribDeclaration", "oneMember"],
        ["AttribDeclaration", "semantic"],
        ["AttribDeclaration", "semantic3"],
        ["AttribDeclaration", "setFieldOffset"],
        ["AttribDeclaration", "toCBuffer"],
        ["AttribDeclaration", "toJson"],
        ["AttribDeclaration", "toObjFile"],
        ["BinAssignExp", "semantic"],
        ["BinExp", "apply"],
        ["BinExp", "buildArrayIdent"],
        ["BinExp", "buildArrayLoop"],
        ["BinExp", "doInline"],
        ["BinExp", "inlineScan"],
        ["BinExp", "interpret"],
        ["BinExp", "op_overload"],
        ["BinExp", "optimize"],
        ["BinExp", "semantic"],
        ["BinExp", "syntaxCopy"],
        ["BinExp", "toCBuffer"],
        ["ClassDeclaration", "kind"],
        ["ClassDeclaration", "semantic"],
        ["ClassDeclaration", "syntaxCopy"],
        ["ClassDeclaration", "toObjFile"],
        ["ClassDeclaration", "toSymbol"],
        ["CompoundStatement", "syntaxCopy"],
        ["CompoundStatement", "toCBuffer"],
        ["ConditionalDeclaration", "importAll"],
        ["ConditionalDeclaration", "include"],
        ["ConditionalDeclaration", "setScope"],
        ["ConditionalDeclaration", "syntaxCopy"],
        ["Declaration", "emitComment"],
        ["Declaration", "kind"],
        ["Declaration", "mangle"],
        ["Declaration", "semantic"],
        ["Declaration", "toDocBuffer"],
        ["Declaration", "toJson"],
        ["Dsymbol", "defineRef"],
        ["Dsymbol", "emitComment"],
        ["Dsymbol", "equals"],
        ["Dsymbol", "hasStaticCtorOrDtor"],
        ["Dsymbol", "inlineScan"],
        ["Dsymbol", "isforwardRef"],
        ["Dsymbol", "isOverloadable"],
        ["Dsymbol", "isScopeDsymbol"],
        ["Dsymbol", "isTemplateDeclaration"],
        ["Dsymbol", "jsonProperties"],
        ["Dsymbol", "kind"],
        ["Dsymbol", "overloadInsert"],
        ["Dsymbol", "prot"],
        ["Dsymbol", "search"],
        ["Dsymbol", "semantic"],
        ["Dsymbol", "semantic2"],
        ["Dsymbol", "semantic3"],
        ["Dsymbol", "syntaxCopy"],
        ["Dsymbol", "toCBuffer"],
        ["Dsymbol", "toChars"],
        ["Dsymbol", "toJson"],
        ["Expression", "toChars"],
        ["ExpStatement", "syntaxCopy"],
        ["ExpStatement", "toIR"],
        ["FuncDeclaration", "inlineScan"],
        ["FuncDeclaration", "isThis"],
        ["FuncDeclaration", "kind"],
        ["FuncDeclaration", "mangle"],
        ["FuncDeclaration", "overloadInsert"],
        ["FuncDeclaration", "semantic"],
        ["FuncDeclaration", "syntaxCopy"],
        ["FuncDeclaration", "toCBuffer"],
        ["FuncDeclaration", "toJson"],
        ["FuncDeclaration", "toPrettyChars"],
        ["FuncDeclaration", "toSymbol"],
        ["IdentifierExp", "clone"],
        ["IntegerExp", "clone"],
        ["IntegerExp", "implicitConvTo"],
        ["IntegerExp", "toCBuffer"],
        ["IntegerExp", "toLvalue"],
        ["Package", "kind"],
        ["Package", "search"],
        ["ScopeDsymbol", "hasStaticCtorOrDtor"],
        ["ScopeDsymbol", "kind"],
        ["ScopeDsymbol", "search"],
        ["ScopeDsymbol", "syntaxCopy"],
        ["StaticCtorDeclaration", "syntaxCopy"],
        ["StaticCtorDeclaration", "toCBuffer"],
        ["StaticDtorDeclaration", "syntaxCopy"],
        ["StaticDtorDeclaration", "toCBuffer"],
        ["StorageClassDeclaration", "setScope"],
        ["StorageClassDeclaration", "syntaxCopy"],
        ["StorageClassDeclaration", "toCBuffer"],
        ["StructDeclaration", "kind"],
        ["StructDeclaration", "syntaxCopy"],
        ["SymbolExp", "clone"],
        ["TemplateInstance", "findTemplateDeclaration"],
        ["TemplateInstance", "inlineScan"],
        ["TemplateInstance", "kind"],
        ["TemplateInstance", "oneMember"],
        ["TemplateInstance", "semantic"],
        ["TemplateInstance", "semantic2"],
        ["TemplateInstance", "semantic3"],
        ["TemplateInstance", "syntaxCopy"],
        ["TemplateInstance", "toCBuffer"],
        ["TemplateInstance", "toChars"],
        ["TemplateInstance", "toObjFile"],
        ["TemplateTypeParameter", "syntaxCopy"],
        ["TemplateTypeParameter", "toCBuffer"],
        ["ThisExp", "clone"],
        ["ThisExp", "doInline"],
        ["ThisExp", "semantic"],
        ["ThisExp", "toCBuffer"],
        ["TypeArray", "dotExp"],
        ["Type", "equals"],
        ["TypeInfoDeclaration", "toSymbol"],
        ["TypeNext", "constConv"],
        ["TypeNext", "reliesOnTident"],
        ["TypeNext", "toDecoBuffer"],
        ["TypeQualified", "size"],
        ["TypeQualified", "toJson"],
        ["Type", "toChars"],
        ["UnaExp", "apply"],
        ["UnaExp", "doInline"],
        ["UnaExp", "dump"],
        ["UnaExp", "inlineScan"],
        ["UnaExp", "interpret"],
        ["UnaExp", "optimize"],
        ["UnaExp", "semantic"],
        ["UnaExp", "syntaxCopy"],
        ["UnaExp", "toCBuffer"],
        ["VarDeclaration", "semantic"],
        ["VarDeclaration", "syntaxCopy"],
        ["VarDeclaration", "toJson"],
        ["VarDeclaration", "toObjFile"],
        ["VarDeclaration", "toSymbol"],
        [null, "accept"],
    ];

    auto nonfinalclasses =
    [
        "AggregateDeclaration",
        "AssignExp",
        "AttribDeclaration",
        "BinAssignExp",
        "BinExp",
        "ClassDeclaration",
        "CompoundStatement",
        "Condition",
        "ConditionalDeclaration",
        "Declaration",
        "DefaultInitExp",
        "Dsymbol",
        "DVCondition",
        "Expression",
        "ExpStatement",
        "FuncDeclaration",
        "IdentifierExp",
        "Initializer",
        "IntegerExp",
        "Lexer",
        "Library",
        "Package",
        "ScopeDsymbol",
        "Section",
        "Statement",
        "StaticCtorDeclaration",
        "StaticDtorDeclaration",
        "StorageClassDeclaration",
        "StructDeclaration",
        "SymbolExp",
        "TemplateInstance",
        "TemplateTypeParameter",
        "TemplateParameter",
        "ThisExp",
        "TypeArray",
        "Type",
        "TypeInfoDeclaration",
        "TypeNext",
        "TypeQualified",
        "Type",
        "UnaExp",
        "VarDeclaration",
        "Visitor",
    ];

    override void visit(FuncDeclaration ast)
    {
        auto stackclassessave = stackclasses;
        scope(exit) stackclasses = stackclassessave;
        auto fdsave = fd;
        scope(exit) fd = fdsave;
        fd = ast;
        buffers = null;
        if (ast.id == "operator new") return;
        if (ast.id == "main") return;
        if (!P && !ast.hasbody && ast.skip) return;
        auto dropdefaultctor = ["Loc", "Token", "HdrGenState", "CtfeStack", "InterState", "BaseClass", "Mem", "StringValue", "OutBuffer", "Scope", "DocComment"];
        if (ast.type.id == ast.id && ast.params.length == 0 && dropdefaultctor.canFind(ast.id))
            return; // Can't have no-args ctor, and Loc/Token doesn't need one
        if (ast.comment)
            printComment(ast.comment);
        bool virtual = (ast.stc & STCvirtual) != 0;
        foreach(m; overriddenfuncs)
        {
            if (m[0] == "Type" && m[1] == "size" && ast.params.length != 0)
            {
            }
            else if ((m[0] is null || P && m[0] == P.id) &&
                     (m[1] is null || m[1] == ast.id))
            {
                virtual = true;
                break;
            }
        }
        auto nonfinalclass = P && nonfinalclasses.canFind(P.id);
        if (!virtual && !(ast.stc & STCabstract) && nonfinalclass)
            print("final ");
        if (!inexternc && (!P || !classTypes.canFind(P.id)) && ast.type.id != ast.id)
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
            println("mixin(dmd_trace_code);");
            if (ast.initlist.length == 1 && classTypes.canFind((cast(IdentExpr)ast.initlist[0].func).id))
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
            println("mixin(dmd_trace_code);");
            foreach(s; ast.fbody)
                visitX(s);
            indent--;
            println("}");
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
            //if (ast.stc & STCabstract)
                println(";");
            /*else
            {
                println("{ assert(0); }");
                if (P)
                    writeln("Missing body - ", P.id, "::", ast.id);
                else
                    writeln("Missing body - ", ast.id);
            }*/
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
        if (at)
        {
            if (auto tc = cast(ClassType)at.next)
            {
                if (tc.id == "NameId")
                {
                    manifest = true;
                }
            }
        }
        if (!ast.type)
            manifest = true;
        bool realarray;
        if (ast.type && !ast.xinit && at && at.dim)
            realarray = true;
        if (fd && !(ast.stc & STCstatic) && !cast(AnonStructDeclaration)D2)
            realarray = false;
        if (!ast.xinit && at && at.dim && !realarray && !cast(StructDeclaration)D2 && !cast(AnonStructDeclaration)D2)
        {
            visitX((ast.stc & STCstatic) | STCvirtual);
            visitX(at.next);
            print("[");
            visitX(at.dim);
            print("] ");
            print(ast.id);
            if (!E)
                println(";");
            buffers ~= ast.id;
            return;
        }
        bool gshared;
        if ((ast.stc & STCstatic) && !cast(FuncDeclaration)D2 && P)
        {
            foreach(vd; scan.staticMemberVarDeclarations)
            {
                if (P.id == vd.id && ast.id == vd.id2)
                {
                    //writeln("found value for ", vd.id, "::", vd.id2);
                    ast.xinit = vd.xinit;
                }
            }
            if (!manifest) print("extern(C++) ");
            if (!manifest) gshared = true;
        }
        else if (!(ast.stc & STCconst) && !D2 && !fd && P)
        {
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
                if (auto at2 = cast(ArrayType)at.next)
                {
                    visitX(at2.next);
                    print("[");
                    visitX(at2.dim);
                    print("]");
                }
                else
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
            foreach(sd; scan.structsUsingInheritance)
            {
                if (sd.id == id)
                {
                    return true;
                }
            }
            if (parentlessclasses.canFind(id))
                return true;
        }
        return false;
    }

    override void visit(ConstructDeclaration ast)
    {
        stackclasses ~= ast.id;
        visitX(ast.type);
        if (!isClass(ast.type))
            print("*");
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
                auto ce = cast(CallExpr)c;
                auto ie = cast(IdentExpr)c;
                auto le = cast(LitExpr)c;
                if (ce)
                {
                    auto fie = cast(IdentExpr)ce.func;
                    if (fie && fie.id == "defined")
                    {
                        assert(ce.args.length == 1);
                        ie = cast(IdentExpr)ce.args[0];
                        assert(ie);
                    }
                }
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

                    case "__DMC__":        println("version(DigitalMars)"); break;
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
                    default:            println("static if (" ~ ie.id ~ ")"); break;
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
        versionCommon(ast);
    }

    override void visit(TypedefDeclaration ast)
    {
        if (auto st = cast(ClassType)ast.t)
        {
            if (st.id == "union tree_node")
                return;
            if (st.id == "struct TYPE")
                return;
        }
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
        if (!ast.e)
        {
            assert(0);
            write(ast.id);
        }
        visitX(ast.e);
        println("; }");
    }

    override void visit(MacroUnDeclaration ast)
    {
    }

    override void visit(StructDeclaration ast)
    {
        bool isclass;
        if (ast.superid || parentlessclasses.canFind(ast.id))
            isclass = true;
        if (isclass)
        {
            print("extern(C++) ");
            if (!nonfinalclasses.canFind(ast.id))
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
        if (ast.superid == "Visitor")
        {
            // base class aliasing rules are different in C++
            println("alias visit = super.visit;");
        }
        if (align1)
            println("align(1):");
        indent++;
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
        println("extern(C) {");
        inexternc++;
        foreach(d; ast.decls)
            visitX(d);
        inexternc--;
        println("}");
    }

    // override void visit(EnumDeclaration ast)
    // {
        // println("enum");
        // println("{");
        // foreach(i; 0..ast.members.length)
        // {
            // visitIdent(ast.members[i]);
            // if (ast.vals[i])
            // {
                // print(" = ");
                // visit(ast.vals[i]);
            // }
            // println(",");
        // }
        // println("};");
        // print("alias uint ");
        // visitIdent(ast.id);
        // if (!E)
            // println(";");
    // }

    override void visit(EnumDeclaration ast)
    {
        print("enum ");
        visitIdent(ast.id);
        println(" : int");
        println("{");
        indent++;
        foreach(i; 0..ast.members.length)
        {
            visitIdent(ast.members[i]);
            if (ast.vals[i])
            {
                print(" = ");
                visitX(ast.vals[i]);
            }
            println(",");
        }
        indent--;
        println("}");
        if (ast.id)
        {
            foreach(i; 0..ast.members.length)
            {
                print("alias ");
                visitIdent(ast.members[i]);
                print(" = ");
                visitIdent(ast.id);
                print(".");
                visitIdent(ast.members[i]);
                println(";");
            }
        }
        println("");
    }

    override void visit(DummyDeclaration ast)
    {
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

    override void visit(AlignDeclaration ast)
    {
        auto align1save = align1;
        scope(exit) align1 = align1save;
        if (ast.id == 1)
            align1 = true;
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
            if (P && structTypes.canFind(P.id))
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
        }
        else if (ie && ie.id == "va_start")
        {
            assert(ast.args.length == 2);
            print("version(X86_64) va_start(");
            visitX(ast.args[0]);
            print(", __va_argsave); else va_start(");
            printArgs(ast.args);
            print(")");
        }
        else
        {
            visitX(ast.func);
            print("(");
            printArgs(ast.args);
            print(")");
        }
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
            print("[ ");
            foreach(i, v; ast.xinit)
            {
                if (i)
                    print(", ");
                visitX(v);
            }
            print("]");
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

    override void visit(EnumType ast)
    {
        assert(!ast.isConst);
        assert(ast.id[0..5] == "enum ");
        visitIdent(ast.id[5..$]);
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
        println(";");
    }

    override void visit(ExpressionStatement ast)
    {
        if (ast.e)
        {
            visitX(ast.e);
            println(";");
        } else {
            println("{}");
        }
    }

    override void visit(VersionStatement ast)
    {
        versionCommon(ast);
    }

    override void visit(IfStatement ast)
    {
        print("if (");
        visitX(ast.e);
        println(")");
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
