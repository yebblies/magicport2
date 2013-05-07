
import std.conv;
import std.algorithm;
import std.stdio;

import tokens;
import ast;
import visitor;

class CppPrinter : Visitor
{
    File target;
    this(File target)
    {
        this.target = target;
    }
    
    Expression E;

    void print(T...)(T args)
    {
        target.write(args);
    }
    void println(T...)(T args)
    {
        target.writeln(args);
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
        static immutable names = ["static", "const", "extern", "extern \"C\"", "virtual", "__cdecl", "abstract", "__inline", "register"];
        bool one;
        assert(!(stc & STCabstract));
        foreach(i, n; names)
        {
            if (stc & (1 << i))
            {
                print(names[i], ' ');
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
        if (cast(Expression)ast) E = cast(Expression)ast;
        if (cast(StructDeclaration)ast) E = null;
        if (cast(AnonStructDeclaration)ast) E = null;

        ast.visit(this);
        
        E = saveE;
    }
    void visit(int line = __LINE__)(string ast)
    {
        if (!ast)
            writeln(line);
        assert(ast);
        print(ast);
    }
    void visit(T)(T[] arr) if (is(typeof(visit(arr[0]))) && !is(T[] : string))
    {
        foreach(v; arr)
            visit(v);
    }

    /////////////////////////////////////////////////////////////////////

    override void visitModule(Module ast)
    {
        visit(ast.decls);
    }

    override void visitImportDeclaration(ImportDeclaration ast)
    {
        print("#include \"");
        visit(ast.fn);
        println("\"");
    }

    override void visitFuncDeclaration(FuncDeclaration ast)
    {
        visit(ast.stc & ~(STCabstract | STCcdecl));
        if (ast.type.id == ast.id || ast.id[0] == '~')
        {
        } else {
            visit(ast.type);
            print(' ');
        }
        if (ast.stc & STCcdecl)
            print("__cdecl ");
        visit(ast.id);
        print('(');
        printParams(ast.params);
        print(')');
        if (ast.superargs)
        {
            print(" : ");
            visit(ast.supertype);
            print("(");
            printArgs(ast.superargs);
            print(")");
        }
        if (ast.stc & STCabstract)
        {
            print(" = 0");
            assert(!ast.fbody && !ast.superargs);
        }
        if (ast.fbody)
        {
            println("");
            visit(ast.fbody);
        } else {
            println(";");
        }
    }

    override void visitFuncBodyDeclaration(FuncBodyDeclaration ast)
    {
        visit(ast.stc);
        if (ast.type.id == ast.id2 || ast.id2[0] == '~')
        {
        } else {
            visit(ast.type);
            print(' ');
        }
        visit(ast.id ? ast.id : (ast.id2[0] == '~' ? ast.id2[1..$] : ast.id2));
        print("::");
        visit(ast.id2);
        print('(');
        printParams(ast.params);
        print(')');
        if (ast.superargs)
        {
            print(" : ");
            visit(ast.supertype);
            print("(");
            printArgs(ast.superargs);
            print(")");
        }
        if (ast.fbody)
        {
            println("");
            visit(ast.fbody);
        } else {
            println(";");
        }
    }

    override void visitStaticMemberVarDeclaration(StaticMemberVarDeclaration ast)
    {
        if (auto at = cast(ArrayType)ast.type)
        {
            visit(at.next);
            print(' ');
            visit(ast.id);
            print("::");
            visit(ast.id2);
            print('[');
            if (at.dim)
                visit(at.dim);
            print(']');
        } else {
            visit(ast.type);
            print(' ');
            visit(ast.id);
            print("::");
            visit(ast.id2);
        }
        if (ast.xinit)
        {
            print(" = ");
            visit(ast.xinit);
        }
        println(";");
    }

    override void visitVarDeclaration(VarDeclaration ast)
    {
        foreach(i; 0..ast.types.length)
        {
            if (ast.types[i])
            {
                visit(ast.stc & ~STCcdecl);
                if (auto at = cast(ArrayType)ast.types[i])
                {
                    if (auto at2 = cast(ArrayType)at.next)
                    {
                        visit(at2.next);
                        print(' ');
                        visit(ast.ids[i]);
                        print('[');
                        if (at2.dim)
                            visit(at2.dim);
                        print(']');
                    }
                    else 
                    {
                        visit(at.next);
                        print(' ');
                        visit(ast.ids[i]);
                    }
                    print('[');
                    if (at.dim)
                        visit(at.dim);
                    print(']');
                } else {
                    visit(ast.types[i]);
                    print(' ');
                    if (ast.stc & STCcdecl)
                        print("__cdecl ");
                    visit(ast.ids[i]);
                }
                if (ast.inits[i])
                {
                    print(" = ");
                    visit(ast.inits[i]);
                }
                if (!E || i != ast.types.length - 1)
                    println(";");
            } else {
                assert(ast.stc & STCconst);
                print("#define");
                print(' ');
                visit(ast.ids[i]);
                if (ast.inits[i])
                {
                    print(' ');
                    visit(ast.inits[i]);
                }
                println();
            }
        }
    }

    override void visitConstructDeclaration(ConstructDeclaration ast)
    {
        visit(ast.type);
        print(" ");
        visit(ast.id);
        print("(");
        printArgs(ast.args);
        print(")");
        if (!E)
            println(";");
    }

    override void visitVersionDeclaration(VersionDeclaration ast)
    {
        foreach(i; 0..ast.es.length)
        {
            if (i == 0)
                print("#if ");
            else if (ast.es[i])
                print("#elif ");
            else
                print("#else");
            if (ast.es[i])
                visit(ast.es[i]);
            println();
            visit(ast.ds[i]);
        }
        println("#endif");
    }

    override void visitTypedefDeclaration(TypedefDeclaration ast)
    {
        print("typedef ");
        if (auto tf = cast(FunctionType)ast.t)
        {
            visit(tf.next);
            print("(*");
            visit(ast.id);
            print(")(");
            printParams(tf.params);
            print(")");
        } else {
            visit(ast.t);
            print(" ");
            visit(ast.id);
        }
        println(";");
    }

    override void visitMacroDeclaration(MacroDeclaration ast)
    {
        print("#define ");
        visit(ast.id);
        print("(");
        foreach(i, s; ast.params)
        {
            print(s);
            if (i != ast.params.length - 1)
                print(", ");
        }
        print(")");
        print(" ");
        visit(ast.e);
        /*foreach(t; ast.toks)
        {
            print(t.text);
            print(' ');
            if (t.text == "\\")
                println();
        }
        println();*/
    }

    override void visitMacroUnDeclaration(MacroUnDeclaration ast)
    {
        print("#undef ");
        visit(ast.id);
        println();
    }

    override void visitMacroCallDeclaration(MacroCallDeclaration ast)
    {
        visit(ast.id);
        print("(");
        foreach(i, s; ast.args)
        {
            visit(s);
            if (i != ast.args.length - 1)
                print(", ");
        }
        print(")\n");
    }

    override void visitStructDeclaration(StructDeclaration ast)
    {
        print(ast.kind);
        print(' ');
        visit(ast.id);
        if (ast.superid)
        {
            print(" : ");
            visit(ast.superid);
        }
        println();
        println("{");
        foreach(d; ast.decls)
            visit(d);
        println("};");
    }

    override void visitAnonStructDeclaration(AnonStructDeclaration ast)
    {
        print(ast.kind);
        println();
        println("{");
        foreach(d; ast.decls)
            visit(d);
        print("} ");
        if (ast.id)
            visit(ast.id);
        if (!E)
            println(";");
    }

    override void visitExternCDeclaration(ExternCDeclaration ast)
    {
        if (ast.block)
        {
            println("extern \"C\" {");
            foreach(d; ast.decls)
                visit(d);
            println("}");
        } else {
            print("extern \"C\" ");
            assert(ast.decls.length == 1);
            visit(ast.decls[0]);
        }
    }

    override void visitEnumDeclaration(EnumDeclaration ast)
    {
        print("enum ");
        visit(ast.id);
        println("{");
        foreach(i; 0..ast.members.length)
        {
            visit(ast.members[i]);
            if (ast.vals[i])
            {
                print(" = ");
                visit(ast.vals[i]);
            }
            println(",");
        }
        println("}");
        if (!E)
            println(";");
    }

    override void visitDummyDeclaration(DummyDeclaration ast)
    {
        if (ast.s)
            visit(ast.s);
    }

    override void visitBitfieldDeclaration(BitfieldDeclaration ast)
    {
        visit(ast.type);
        print(" ");
        visit(ast.id);
        print(" : ");
        visit(ast.width);
        println(";");
    }

    override void visitProtDeclaration(ProtDeclaration ast)
    {
        visit(ast.id);
        println(":");
    }

    override void visitAlignDeclaration(AlignDeclaration ast)
    {
        print("#pragma pack(");
        if (ast.id)
            print(ast.id);
        println(")");
    }

    override void visitLitExpr(LitExpr ast)
    {
        visit(ast.val);
    }

    override void visitIdentExpr(IdentExpr ast)
    {
        visit(ast.id);
    }

    override void visitDotIdExpr(DotIdExpr ast)
    {
        visit(ast.e);
        print(ast.op);
        visit(ast.id);
    }

    override void visitCallExpr(CallExpr ast)
    {
        auto id = cast(IdentExpr)ast.func;
        if (id && id.id == "operatornew")
        {
            print("operator new");
        }
        else
            visit(ast.func);
        print("(");
        printArgs(ast.args);
        print(")");
    }

    override void visitCmpExpr(CmpExpr ast)
    {
        print("(");
        visit(ast.e1);
        print(" ", ast.op, " ");
        visit(ast.e2);
        print(")");
    }

    override void visitMulExpr(MulExpr ast)
    {
        print("(");
        visit(ast.e1);
        print(" ", ast.op, " ");
        visit(ast.e2);
        print(")");
    }

    override void visitAddExpr(AddExpr ast)
    {
        print("(");
        visit(ast.e1);
        print(" ", ast.op, " ");
        visit(ast.e2);
        print(")");
    }

    override void visitOrOrExpr(OrOrExpr ast)
    {
        print("(");
        visit(ast.e1);
        print(" ", ast.op, " ");
        visit(ast.e2);
        print(")");
    }

    override void visitAndAndExpr(AndAndExpr ast)
    {
        print("(");
        visit(ast.e1);
        print(" ", ast.op, " ");
        visit(ast.e2);
        print(")");
    }

    override void visitOrExpr(OrExpr ast)
    {
        print("(");
        visit(ast.e1);
        print(" ", ast.op, " ");
        visit(ast.e2);
        print(")");
    }

    override void visitXorExpr(XorExpr ast)
    {
        print("(");
        visit(ast.e1);
        print(" ", ast.op, " ");
        visit(ast.e2);
        print(")");
    }

    override void visitAndExpr(AndExpr ast)
    {
        print("(");
        visit(ast.e1);
        print(" ", ast.op, " ");
        visit(ast.e2);
        print(")");
    }

    override void visitAssignExpr(AssignExpr ast)
    {
        print("(");
        visit(ast.e1);
        print(" ", ast.op, " ");
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
        print(ast.op, ")");
    }

    override void visitPreExpr(PreExpr ast)
    {
        print("(");
        visit(ast.op);
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
        print("(delete ");
        visit(ast.e);
        print(")");
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
        print("((");
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
        print("::");
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
        print("sizeof(");
        if (ast.e)
            visit(ast.e);
        else
            visit(ast.t);
        print(")");
    }

    override void visitExprInit(ExprInit ast)
    {
        visit(ast.e);
    }

    override void visitArrayInit(ArrayInit ast)
    {
        println("{");
        foreach(v; ast.xinit)
        {
            visit(v);
            println(",");
        }
        println("}");
    }

    override void visitBasicType(BasicType ast)
    {
        if (ast.isConst)
            print("const ");
        visit(ast.id);
    }

    override void visitClassType(ClassType ast)
    {
        if (ast.isConst)
            print("const ");
        visit(ast.id);
    }

    override void visitEnumType(EnumType ast)
    {
        visit(ast.id);
    }

    override void visitPointerType(PointerType ast)
    {
        visit(ast.next);
        print('*');
    }

    override void visitRefType(RefType ast)
    {
        visit(ast.next);
        print('&');
    }

    override void visitArrayType(ArrayType ast)
    {
        visit(ast.next);
        print("[");
        if (ast.dim)
            visit(ast.dim);
        print("]");
    }

    override void visitFunctionType(FunctionType ast)
    {
        assert(0);
    }

    override void visitTemplateType(TemplateType ast)
    {
        visit(ast.next);
        print("<");
        visit(ast.param);
        print(">");
    }

    override void visitParam(Param ast)
    {
        if (ast.id == "...")
            visit(ast.id);
        else
        {
            if (auto at = cast(ArrayType)ast.t)
            {
                assert(ast.id);
                visit(at.next);
                print(' ');
                visit(ast.id);
                print('[');
                if (at.dim)
                    visit(at.dim);
                print(']');
            } else {
                visit(ast.t);
                print(' ');
                if (ast.id)
                    visit(ast.id);
                else
                    assert(!ast.def);
            }
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
            visit(ast.e);
        println(";");
    }

    override void visitVersionStatement(VersionStatement ast)
    {
        foreach(i; 0..ast.cond.length)
        {
            if (i == 0)
                print("#if ");
            else if (ast.cond[i])
                print("#elif ");
            else
                print("#else");
            if (ast.cond[i])
                visit(ast.cond[i]);
            println();
            visit(ast.s[i]);
        }
        assert(ast.s.length == ast.cond.length);
        println("#endif");
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
        if (ast.xinit)
            visit(ast.xinit);
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
        println();
        print("while (");
        visit(ast.e);
        println(")");
    }

    override void visitGotoStatement(GotoStatement ast)
    {
        print("goto ");
        visit(ast.id);
        println(";");
    }

    override void visitLabelStatement(LabelStatement ast)
    {
        visit(ast.id);
        println(":");
    }

};
