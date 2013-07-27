
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

auto parentlessclasses = ["Section", "Condition", "TemplateParameter", "Lexer", "RootObject", "Library"];

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

    int indent;
    bool wasnl;
    int inexternc;

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
        static immutable names = ["static __gshared", "enum", "extern", "extern(C)", "virtual", "__cdecl", "abstract", "__inline", "register"];
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
    void visit(T)(T[] arr) if (is(typeof(visit(arr[0]))) && !is(T[] : string))
    {
        foreach(v; arr)
            visit(v);
    }

    /////////////////////////////////////////////////////////////////////
    
    void visitIdent(string s)
    {
        switch(s)
        {
        case "I": print("1i"); return;
        case "NULL": print("null"); return;
        case "__IMPORT__": print("\"v\" ~ import(\"VERSION\")"); return;
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
        auto stackclassessave = stackclasses;
        scope(exit) stackclasses = stackclassessave;
        auto fdsave = fd;
        scope(exit) fd = fdsave;
        fd = ast;
        if (ast.id == "operator new") return;
        if (!P && !ast.hasbody && ast.skip) return;
        auto dropdefaultctor = ["Loc", "Token", "HdrGenState", "CtfeStack", "InterState", "BaseClass", "Mem", "StringValue", "OutBuffer", "Scope", "DocComment"];
        if (ast.type.id == ast.id && ast.params.length == 0 && dropdefaultctor.canFind(ast.id))
            return; // Can't have no-args ctor, and Loc/Token doesn't need one
        auto matchlist =
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
            ["Declaration", "isFinal"],
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
            ["FuncDeclaration", "isThis"],
            ["FuncDeclaration", "kind"],
            ["FuncDeclaration", "mangle"],
            ["FuncDeclaration", "overloadInsert"],
            ["FuncDeclaration", "semantic"],
            ["FuncDeclaration", "syntaxCopy"],
            ["FuncDeclaration", "toCBuffer"],
            ["FuncDeclaration", "toJson"],
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
        ];
        bool virtual = (ast.stc & STCvirtual) != 0;
        foreach(m; matchlist)
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
        if (!virtual && !(ast.stc & STCabstract))
            print("final ");
        if (!inexternc && (!P || !classTypes.canFind(P.id)))
            print("extern(C++) ");
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
                    print("this.");
                    visit(i.func);
                    print(" = ");
                    assert(i.args.length == 1);
                    visit(i.args);
                    println(";");
                }
            }
            foreach(s; ast.fbody)
                visit(s);
            indent--;
            println("}");
        } else if (ast.hasbody)
        {
            println("");
            println("{");
            indent++;
            println("mixin(dmd_trace_code);");
            foreach(s; ast.fbody)
                visit(s);
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

    override void visitFuncBodyDeclaration(FuncBodyDeclaration ast)
    {
    }

    override void visitStaticMemberVarDeclaration(StaticMemberVarDeclaration ast)
    {
    }

    override void visitVarDeclaration(VarDeclaration ast)
    {
        if (ast.stc & STCextern) return;
        if (ast.ids[0] == "ASYNCREAD") return;
        auto t0 = ast.types[0];
        bool allsame = t0 !is null;
        foreach(t; ast.types[1..$])
            if (!typeMatch(t, t0))
                allsame = false;
        bool manifest;
        if (auto tp = cast(ArrayType)t0)
        {
            if (auto tc = cast(ClassType)tp.next)
            {
                if (tc.id == "NameId")
                {
                    ast.stc &= ~STCstatic;
                    manifest = true;
                }
            }
        }
        bool realarray;
        if (ast.types.length == 1 && ast.types[0] && !ast.inits[0])
            if (auto at = cast(ArrayType)ast.types[0])
                if (at.dim)
                    realarray = true;
        if (fd && !(ast.stc & STCstatic) && !cast(AnonStructDeclaration)D2)
            realarray = false;
        if (ast.types.length == 1 && !ast.inits[0] && cast(ArrayType)ast.types[0] && (cast(ArrayType)ast.types[0]).dim && !realarray && !cast(StructDeclaration)D2 && !cast(AnonStructDeclaration)D2)
        {
            auto at = cast(ArrayType)ast.types[0];
            visit((ast.stc & STCstatic) | STCvirtual);
            visit(at.next);
            print("[");
            visit(at.dim);
            print("] ");
            print(ast.ids[0]);
            print("__array_storage");
            println(";");
        }
        if (ast.types.length == 1 && (ast.stc & STCstatic) && !cast(FuncDeclaration)D2 && P)
        {
            foreach(vd; scan.staticMemberVarDeclarations)
            {
                if (P.id == vd.id && ast.ids[0] == vd.id2)
                {
                    //writeln("found value for ", vd.id, "::", vd.id2);
                    ast.inits[0] = vd.xinit;
                }
            }
            print("extern(C++) __gshared ");
        }
        else if (ast.types.length == 1 && !(ast.stc & STCconst) && !D2 && !fd)
        {
            print("extern(C++) __gshared ");
        }
        foreach(i; 0..ast.types.length)
        {
            if (ast.types[i])
            {
                if (ast.ids[i] == "__locale_decpoint") return;
                if (ast.ids[i] == "__file__") return;
                if (!allsame || !i)
                {
                    if (manifest)
                        print("enum ");
                    visit(ast.stc | STCvirtual);
                    if (realarray)
                    {
                        auto at = cast(ArrayType)ast.types[i];
                        if (auto at2 = cast(ArrayType)at.next)
                        {
                            visit(at2.next);
                            print("[");
                            visit(at2.dim);
                            print("]");
                        }
                        else
                            visit(at.next);
                        print("[");
                        visit(at.dim);
                        print("]");
                    }
                    else
                        visit(ast.types[i]);
                    print(" ");
                }
                visitIdent(ast.ids[i]);
                if (ast.inits[i])
                {
                    print(" = ");
                    this.inittype = ast.types[i];
                    visit(ast.inits[i]);
                    inittype = null;
                }
                else if (cast(ArrayType)ast.types[i] && (cast(ArrayType)ast.types[i]).dim && !realarray && !cast(StructDeclaration)D2 && !cast(AnonStructDeclaration)D2)
                {
                    assert(ast.types.length == 1);
                    auto at = cast(ArrayType)ast.types[i];
                    print(" = ");
                    print(ast.ids[i]);
                    print("__array_storage.ptr");
                }
                if (allsame && i != ast.types.length - 1)
                    println(", ");
                else if (!E || i != ast.types.length - 1)
                    println(";");
            } else {
                if (ast.ids[i] == "LOG" || ast.ids[i] == "LOGSEMANTIC") return;
                if (ast.ids[i].endsWith("_H")) return;
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
        if (ast.types.length == 1)
        {
            if (auto at = cast(ArrayType)ast.types[0])
            {
                if (at.dim)
                {
                    if (E)
                        println(";");
                    visit((ast.stc & STCstatic) | STCvirtual);
                    print("enum ");
                    print(ast.ids[0]);
                    print("__array_length = ");
                    visit(at.dim);
                    if (!E)
                        println(";");
                    return;
                }
            }
        }
        if (ast.types.length == 1 && ast.inits[0])
        {
            if (auto ai = cast(ArrayInit)ast.inits[0])
            {
                if (E)
                    println(";");
                visit((ast.stc & STCstatic) | STCvirtual);
                print("enum ");
                print(ast.ids[0]);
                print("__array_length = ");
                print(to!string(ai.xinit.length));
                if (!E)
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
            if (parentlessclasses.canFind(ct.id))
                return true;
        }
        return false;
    }

    override void visitConstructDeclaration(ConstructDeclaration ast)
    {
        stackclasses ~= ast.id;
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
                    case "linux":          println("version(linux)"); break;
                    case "__APPLE__":
                    case "MACINTOSH":      println("version(OSX)"); break;
                    case "__FreeBSD__":    println("version(FreeBSD)"); break;
                    case "__OpenBSD__":    println("version(OpenBSD)"); break;
                    case "__sun":          println("version(Solaris)"); break;

                    case "__DMC__":        println("version(DigitalMars)"); break;
                    case "IN_GCC":         println("version(GNU)"); break;

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
                    visit(c);
                    println(")");
                }
            }
            else
            {
                println("else");
            }
            println("{");
            indent++;
            visit(ast.members[i]);
            indent--;
            println("}");
        }
    }

    override void visitVersionDeclaration(VersionDeclaration ast)
    {
        versionCommon(ast);
    }

    override void visitTypedefDeclaration(TypedefDeclaration ast)
    {
        if (auto ft = cast(FunctionType)ast.t)
        {
            if (ft.cdecl)
                print("extern(C) ");
            else
                print("extern(C++) ");
        }
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
        print(") { return ");
        if (!ast.e)
        {
            assert(0);
            write(ast.id);
        }
        visit(ast.e);
        println("; }");
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
        bool isclass;
        if (ast.superid || parentlessclasses.canFind(ast.id))
            isclass = true;
        if (isclass)
            print("extern(C++) class");
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
        if (align1)
            println("align(1):");
        indent++;
        foreach(d; ast.decls)
            visit(d);
        indent--;
        println("}");
        println("");
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
        inexternc++;
        foreach(d; ast.decls)
            visit(d);
        inexternc--;
        println("}");
    }

    // override void visitEnumDeclaration(EnumDeclaration ast)
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

    override void visitEnumDeclaration(EnumDeclaration ast)
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
                visit(ast.vals[i]);
            }
            println(",");
        }
        indent--;
        println("}");
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

    override void visitDummyDeclaration(DummyDeclaration ast)
    {
        print("/* ");
        print(ast.s);
        println(" */");
    }

    override void visitErrorDeclaration(ErrorDeclaration ast)
    {
        print("static assert(0, ");
        visit(ast.e);
        print(")");
        if (!E)
            println(";");
    }

    override void visitBitfieldDeclaration(BitfieldDeclaration ast)
    {
        assert(0);
    }

    override void visitProtDeclaration(ProtDeclaration ast)
    {
        indent--;
        print(ast.id);
        println(":");
        indent++;
    }

    override void visitAlignDeclaration(AlignDeclaration ast)
    {
        auto align1save = align1;
        scope(exit) align1 = align1save;
        if (ast.id == 1)
            align1 = true;
    }

    override void visitLitExpr(LitExpr ast)
    {
        if (ast.val.endsWith("LL", "ll"))
        {
            print(ast.val[0..$-1]);
        }
        else if (ast.val.endsWith("L", "l"))
        {
            print(ast.val[0..$-1]);
        } else {
            print(ast.val);
        }
    }

    override void visitIdentExpr(IdentExpr ast)
    {
        if (ast.id == "this" && P)
        {
            if (P && structTypes.canFind(P.id))
            {
                print("(&this)");
                return;
            }
        }
        visitIdent(ast.id);
    }

    override void visitDotIdExpr(DotIdExpr ast)
    {
        // bypass this -> &this for lhs
        auto ie = cast(IdentExpr)ast.e;
        if (ie && ie.id == "this")
            print("this");
        else
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
        auto ie1 = cast(IdentExpr)ast.e1;
        auto ie2 = cast(IdentExpr)ast.e2;
        auto n1 = ie1 && ie1.id == "NULL";
        auto n2 = ie2 && ie2.id == "NULL";

        lparen(ast);
        visit(ast.e1);
        print(" ");
        if ((n1 || n2) && ast.op == "==")
            print("is");
        else if ((n1 || n2) && ast.op == "!=")
            print("!is");
        else
            print(ast.op);
        print(" ");
        visit(ast.e2);
        rparen(ast);
    }

    override void visitMulExpr(MulExpr ast)
    {
        if (ast.op == "/")
        {
            if (auto se1 = cast(SizeofExpr)ast.e1)
            {
                if (auto se2 = cast(SizeofExpr)ast.e2)
                {
                    if (auto id1 = cast(IdentExpr)se1.e)
                    {
                        if (auto ie2 = cast(IndexExpr)se2.e)
                        {
                            if (auto id2 = cast(IdentExpr)ie2.e)
                            {
                                if (id1.id == id2.id && ie2.args.length == 1)
                                {
                                    if (auto le = cast(LitExpr)ie2.args[0])
                                    {
                                        if (le.val == "0")
                                        {
                                            print(id1.id);
                                            print("__array_length");
                                            return;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        lparen(ast);
        visit(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visit(ast.e2);
        rparen(ast);
    }

    override void visitAddExpr(AddExpr ast)
    {
        lparen(ast);
        visit(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visit(ast.e2);
        rparen(ast);
    }

    override void visitOrOrExpr(OrOrExpr ast)
    {
        lparen(ast);
        visit(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visit(ast.e2);
        rparen(ast);
    }

    override void visitAndAndExpr(AndAndExpr ast)
    {
        lparen(ast);
        visit(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visit(ast.e2);
        rparen(ast);
    }

    override void visitOrExpr(OrExpr ast)
    {
        lparen(ast);
        visit(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visit(ast.e2);
        rparen(ast);
    }

    override void visitXorExpr(XorExpr ast)
    {
        lparen(ast);
        visit(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visit(ast.e2);
        rparen(ast);
    }

    override void visitAndExpr(AndExpr ast)
    {
        lparen(ast);
        visit(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visit(ast.e2);
        rparen(ast);
    }

    override void visitAssignExpr(AssignExpr ast)
    {
        lparen(ast);
        visit(ast.e1);
        print(" ");
        print(ast.op);
        print(" ");
        visit(ast.e2);
        rparen(ast);
    }

    override void visitDeclarationExpr(DeclarationExpr ast)
    {
        visit(ast.d);
    }

    override void visitPostExpr(PostExpr ast)
    {
        lparen(ast);
        visit(ast.e);
        print(ast.op);
        rparen(ast);
    }

    override void visitPreExpr(PreExpr ast)
    {
        lparen(ast);
        print(ast.op);
        visit(ast.e);
        rparen(ast);
    }

    override void visitPtrExpr(PtrExpr ast)
    {
        lparen(ast);
        print("*");
        visit(ast.e);
        rparen(ast);
    }

    override void visitAddrExpr(AddrExpr ast)
    {
        if (auto ie = cast(IdentExpr)ast.e)
        {
            if (stackclasses.canFind(ie.id))
            {
                visit(ast.e);
                return;
            }
        }
        lparen(ast);
        print("&");
        visit(ast.e);
        rparen(ast);
    }

    override void visitNegExpr(NegExpr ast)
    {
        lparen(ast);
        print("-");
        visit(ast.e);
        rparen(ast);
    }

    override void visitComExpr(ComExpr ast)
    {
        lparen(ast);
        print("~");
        visit(ast.e);
        rparen(ast);
    }

    override void visitDeleteExpr(DeleteExpr ast)
    {
        print("do {/*delete*/} while(0)");
    }

    override void visitNotExpr(NotExpr ast)
    {
        lparen(ast);
        print("!");
        visit(ast.e);
        rparen(ast);
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
        lparen(ast);
        visit(ast.cond);
        print(" ? ");
        visit(ast.e1);
        print(" : ");
        visit(ast.e2);
        rparen(ast);
    }

    override void visitCastExpr(CastExpr ast)
    {
        lparen(ast);
        print("cast(");
        visit(ast.t);
        print(")");
        visit(ast.e);
        rparen(ast);
    }

    override void visitNewExpr(NewExpr ast)
    {
        assert(!ast.dim);
        lparen(ast);
        print("new ");
        visit(ast.t);
        print("(");
        printArgs(ast.args);
        print(")");
        rparen(ast);
    }

    override void visitOuterScopeExpr(OuterScopeExpr ast)
    {
        print(".");
        visit(ast.e);
    }

    override void visitCommaExpr(CommaExpr ast)
    {
        lparen(ast);
        visit(ast.e1);
        print(", ");
        visit(ast.e2);
        rparen(ast);
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
        if (auto ts = cast(ClassType)inittype)
        {
            print(ts.id);
            print("(");
            foreach(i, v; ast.xinit)
            {
                if (i)
                    print(", ");
                visit(v);
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
                visit(v);
            }
            print("]");
        }
    }

    override void visitBasicType(BasicType ast)
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
        }
        else if (ast.id.length > 6 && ast.id[0..6] == "class ")
        {
            visitIdent(ast.id[6..$]);
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
        if (ast.isConst)
            print("const(");
        visit(ast.next);
        if (!isClass(ast.next))
            print("*");
        if (ast.isConst)
            print(")");
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
            if (ast.def && ast.t.id == "Loc" && cast(LitExpr)ast.def && (cast(LitExpr)ast.def).val == "0")
                print(" = Loc()");
            else if (ast.def)
            {
                print(" = ");
                visit(ast.def);
            }
        }
    }

    override void visitCompoundStatement(CompoundStatement ast)
    {
        auto stackclassessave = stackclasses;
        scope(exit) stackclasses = stackclassessave;
        println("{");
        indent++;
        visit(ast.s);
        indent--;
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

    override void visitVersionStatement(VersionStatement ast)
    {
        versionCommon(ast);
    }

    override void visitIfStatement(IfStatement ast)
    {
        print("if (");
        visit(ast.e);
        println(")");
        if (!cast(CompoundStatement)ast.sbody)
            indent++;
        visit(ast.sbody);
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
            visit(ast.selse);
            if (!cast(CompoundStatement)ast.selse && !elseisif)
                indent--;
        }
    }

    override void visitForStatement(ForStatement ast)
    {
        print("for (");
        if (ast.xinit)
            visit(ast.xinit);
        print(";");
        if (ast.cond)
        {
            print(" ");
            visit(ast.cond);
        }
        print(";");
        if (ast.inc)
        {
            print(" ");
            visit(ast.inc);
        }
        println(")");
        if (!cast(CompoundStatement)ast.sbody)
            indent++;
        visit(ast.sbody);
        if (!cast(CompoundStatement)ast.sbody)
            indent--;
    }

    override void visitSwitchStatement(SwitchStatement ast)
    {
        auto sswitchsave = sswitch;
        scope(exit) sswitch = sswitchsave;
        sswitch = ast;
        print("switch (");
        visit(ast.e);
        println(")");
        println("{");
        indent++;
        foreach(s; ast.sbody)
            visit(s);
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

    override void visitCaseStatement(CaseStatement ast)
    {
        indent--;
        print("case ");
        visit(ast.e);
        println(":");
        indent++;
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
        assert(sswitch);
        sswitch.hasdefault = true;
        indent--;
        println("default:");
        indent++;
    }

    override void visitWhileStatement(WhileStatement ast)
    {
        print("while (");
        visit(ast.e);
        println(")");
        if (!cast(CompoundStatement)ast.sbody)
            indent++;
        visit(ast.sbody);
        if (!cast(CompoundStatement)ast.sbody)
            indent--;
    }

    override void visitDoWhileStatement(DoWhileStatement ast)
    {
        println("do");
        if (!cast(CompoundStatement)ast.sbody)
            indent++;
        visit(ast.sbody);
        if (!cast(CompoundStatement)ast.sbody)
            indent--;
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
        indent--;
        visitIdent(ast.id);
        println(": {}");
        indent++;
    }

};
