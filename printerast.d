
import std.conv;
import std.algorithm;
import std.stdio;

import tokens;
import ast;
import visitor;

class AstPrinter : Visitor
{
    File target;
    this(File target)
    {
        this.target = target;
    }

    void indent()
    {
        foreach(i; 0..depth)
            target.write('\t');
    }
    void indent2()
    {
        foreach(i; 0..depth+1)
            target.write('\t');
    }
    void print(string s)
    {
        indent();
        target.writeln(s);
    }
    void print2(string s)
    {
        indent2();
        target.writeln(s);
    }
    void visit()(int stc)
    {
        indent2();
        static immutable names = ["static", "extern", "externc", "virtual", "cdecl", "abstract", "inline", "register"];
        bool one;
        foreach(i, n; names)
        {
            if (stc & (1 << i))
            {
                target.write(one ? " | " : "", "STC", n);
                one = true;
            }
        }
        if (!one)
            target.write("STCdefault");
        target.writeln();
    }
    void visit()(Ast ast)
    {
        if (ast)
        {
            ast.visit(this);
        } else {
            print2("null");
        }
    }
    void visit()(string ast)
    {
        if (ast)
        {
            print2(ast);
        } else {
            print2("null");
        }
    }
    void visit(T)(T[] arr) if (is(typeof(visit(arr[0]))) && !is(T[] : string))
    {
        depth++;
        print(T.stringof ~ "s(");
        foreach(v; arr)
            visit(v);
        print(")");
        depth--;
    }
    
    ///////////////////////////////////////

    void visitModule(Module ast)
    {
        print("Module(");
        visit(ast.file);
        visit(ast.decls);
        print(")");
    }

    override void visitImportDeclaration(ImportDeclaration ast)
    {
        print("ImportDeclaration(");
        visit(ast.fn);
        print(")");
    }

    override void visitFuncDeclaration(FuncDeclaration ast)
    {
        print("FuncDeclaration(");
        visit(ast.type);
        visit(ast.id);
        visit(ast.params);
        visit(ast.fbody);
        visit(ast.stc);
        visit(ast.superargs);
        print(")");
    }

    override void visitFuncBodyDeclaration(FuncBodyDeclaration ast)
    {
        print("FuncBodyDeclaration(");
        visit(ast.type);
        visit(ast.id);
        visit(ast.id2);
        visit(ast.params);
        visit(ast.fbody);
        visit(ast.stc);
        visit(ast.superargs);
        print(")");
    }

    override void visitStaticMemberVarDeclaration(StaticMemberVarDeclaration ast)
    {
        print("StaticMemberVarDeclaration(");
        visit(ast.type);
        visit(ast.id);
        visit(ast.id2);
        visit(ast.init);
        print(")");
    }

    override void visitVarDeclaration(VarDeclaration ast)
    {
        foreach(i; 0..ast.types.length)
        {
            print("VarDeclaration(");
            visit(ast.stc);
            visit(ast.types[i]);
            visit(ast.ids[i]);
            visit(ast.inits[i]);
            print(")");
        }
    }

    override void visitConstructDeclaration(ConstructDeclaration ast)
    {
        print("ConstructDeclaration(");
        visit(ast.type);
        visit(ast.id);
        visit(ast.args);
        print(")");
    }

    override void visitVersionDeclaration(VersionDeclaration ast)
    {
        print("VersionDeclataion(");
        assert(ast.es.length == ast.ds.length);
        depth++;
        foreach(i; 0..ast.es.length)
        {
            print("Body(");
            visit(ast.es[i]);
            visit(ast.ds[i]);
            print(")");
        }
        depth--;
        print(")");
    }

    override void visitTypedefDeclaration(TypedefDeclaration ast)
    {
        print("TypedefDeclaration(");
        visit(ast.t);
        visit(ast.id);
        print(")");
    }

    override void visitMacroDeclaration(MacroDeclaration ast)
    {
        print("MacroDeclaration(");
        visit(ast.id);
        visit(ast.params);
        print2("<tokens>");
        print(")");
    }

    override void visitMacroUnDeclaration(MacroUnDeclaration ast)
    {
        print("MacroUnDeclaration(");
        visit(ast.id);
        print(")");
    }

    override void visitMacroCallDeclaration(MacroCallDeclaration ast)
    {
        print("MacroDeclaration(");
        visit(ast.id);
        print(")");
    }

    override void visitStructDeclaration(StructDeclaration ast)
    {
        print("StructDeclaration(");
        visit(ast.id);
        visit(ast.superid);
        visit(ast.decls);
        print(")");
    }

    override void visitAnonStructDeclaration(AnonStructDeclaration ast)
    {
        print("AnonStructDeclaration(");
        visit(ast.id);
        visit(ast.decls);
        print(")");
    }

    override void visitExternCDeclaration(ExternCDeclaration ast)
    {
        print("ExternCDeclaration(");
        visit(ast.decls);
        print(")");
    }

    override void visitEnumDeclaration(EnumDeclaration ast)
    {
        print("EnumDeclaration(");
        visit(ast.id);
        visit(ast.members);
        visit(ast.vals);
        print(")");
    }

    override void visitDummyDeclaration(DummyDeclaration ast)
    {
        print("DummyDeclaration(");
        print(")");
    }

    override void visitBitfieldDeclaration(BitfieldDeclaration ast)
    {
        print("BitfieldDeclaration(");
        visit(ast.type);
        visit(ast.id);
        visit(ast.width);
        print(")");
    }

    override void visitProtDeclaration(ProtDeclaration ast)
    {
        print("ProtDeclaration(");
        visit(ast.id);
        print(")");
    }

    override void visitAlignDeclaration(AlignDeclaration ast)
    {
        print("AlignDeclaration(");
        visit(ast.id);
        print(")");
    }

    override void visitLitExpr(LitExpr ast)
    {
        print("LitExpr(");
        visit(ast.val);
        print(")");
    }

    override void visitIdentExpr(IdentExpr ast)
    {
        print("IdentExpr(");
        visit(ast.id);
        print(")");
    }

    override void visitDotIdExpr(DotIdExpr ast)
    {
        print("DotIdExpr(");
        visit(ast.op);
        visit(ast.e);
        visit(ast.id);
        print(")");
    }

    override void visitCallExpr(CallExpr ast)
    {
        print("CallExpr(");
        visit(ast.func);
        visit(ast.args);
        print(")");
    }

    override void visitCmpExpr(CmpExpr ast)
    {
        print("CmpExpr(");
        visit(ast.op);
        visit(ast.e1);
        visit(ast.e2);
        print(")");
    }

    override void visitMulExpr(MulExpr ast)
    {
        print("MulExpr(");
        visit(ast.op);
        visit(ast.e1);
        visit(ast.e2);
        print(")");
    }

    override void visitAddExpr(AddExpr ast)
    {
        print("AddExpr(");
        visit(ast.op);
        visit(ast.e1);
        visit(ast.e2);
        print(")");
    }

    override void visitOrOrExpr(OrOrExpr ast)
    {
        print("OrOrExpr(");
        visit(ast.e1);
        visit(ast.e2);
        print(")");
    }

    override void visitAndAndExpr(AndAndExpr ast)
    {
        print("AndAndExpr(");
        visit(ast.e1);
        visit(ast.e2);
        print(")");
    }

    override void visitOrExpr(OrExpr ast)
    {
        print("OrExpr(");
        visit(ast.e1);
        visit(ast.e2);
        print(")");
    }

    override void visitXorExpr(XorExpr ast)
    {
        print("XorExpr(");
        visit(ast.e1);
        visit(ast.e2);
        print(")");
    }

    override void visitAndExpr(AndExpr ast)
    {
        print("AndExpr(");
        visit(ast.e1);
        visit(ast.e2);
        print(")");
    }

    override void visitAssignExpr(AssignExpr ast)
    {
        print("AssignExpr(");
        visit(ast.e1);
        visit(ast.e2);
        print(")");
    }

    override void visitDeclarationExpr(DeclarationExpr ast)
    {
        print("DeclarationExpr(");
        visit(ast.d);
        print(")");
    }

    override void visitPostExpr(PostExpr ast)
    {
        print("PostExpr(");
        visit(ast.op);
        visit(ast.e);
        print(")");
    }

    override void visitPreExpr(PreExpr ast)
    {
        print("PreExpr(");
        visit(ast.op);
        visit(ast.e);
        print(")");
    }

    override void visitPtrExpr(PtrExpr ast)
    {
        print("PtrExpr(");
        visit(ast.e);
        print(")");
    }

    override void visitAddrExpr(AddrExpr ast)
    {
        print("AddrExpr(");
        visit(ast.e);
        print(")");
    }

    override void visitNegExpr(NegExpr ast)
    {
        print("NegExpr(");
        visit(ast.e);
        print(")");
    }

    override void visitComExpr(ComExpr ast)
    {
        print("ComExpr(");
        visit(ast.e);
        print(")");
    }

    override void visitDeleteExpr(DeleteExpr ast)
    {
        print("DeleteExpr(");
        visit(ast.e);
        print(")");
    }

    override void visitNotExpr(NotExpr ast)
    {
        print("NotExpr(");
        visit(ast.e);
        print(")");
    }

    override void visitIndexExpr(IndexExpr ast)
    {
        print("IndexExpr(");
        visit(ast.e);
        visit(ast.args);
        print(")");
    }

    override void visitCondExpr(CondExpr ast)
    {
        print("CondExpr(");
        visit(ast.cond);
        visit(ast.e1);
        visit(ast.e2);
        print(")");
    }

    override void visitCastExpr(CastExpr ast)
    {
        print("CastExpr(");
        visit(ast.t);
        visit(ast.e);
        print(")");
    }

    override void visitNewExpr(NewExpr ast)
    {
        print("NewExpr(");
        visit(ast.t);
        visit(ast.args);
        visit(ast.dim);
        print(")");
    }

    override void visitOuterScopeExpr(OuterScopeExpr ast)
    {
        print("OuterScopeExpr(");
        visit(ast.e);
        print(")");
    }

    override void visitCommaExpr(CommaExpr ast)
    {
        print("CommaExpr(");
        visit(ast.e1);
        visit(ast.e2);
        print(")");
    }

    override void visitSizeofExpr(SizeofExpr ast)
    {
        print("SizeofExpr(");
        visit(ast.e);
        visit(ast.t);
        print(")");
    }

    override void visitExprInit(ExprInit ast)
    {
        print("ExprInit(");
        visit(ast.e);
        print(")");
    }

    override void visitArrayInit(ArrayInit ast)
    {
        print("ArrayInit(");
        visit(ast.init);
        print(")");
    }

    override void visitBasicType(BasicType ast)
    {
        print("BasicType(");
        visit(ast.id);
        print(")");
    }

    override void visitClassType(ClassType ast)
    {
        print("PointerType(");
        visit(ast.id);
        print(")");
    }

    override void visitEnumType(EnumType ast)
    {
        print("EnumType(");
        visit(ast.id);
        print(")");
    }

    override void visitPointerType(PointerType ast)
    {
        print("PointerType(");
        visit(ast.next);
        print(")");
    }

    override void visitRefType(RefType ast)
    {
        print("RefType(");
        visit(ast.next);
        print(")");
    }

    override void visitArrayType(ArrayType ast)
    {
        print("ArrayType(");
        visit(ast.next);
        visit(ast.dim);
        print(")");
    }

    override void visitFunctionType(FunctionType ast)
    {
        print("PointerType(");
        visit(ast.next);
        visit(ast.params);
        print(")");
    }

    override void visitTemplateType(TemplateType ast)
    {
        print("TemplateType(");
        visit(ast.next);
        visit(ast.param);
        print(")");
    }

    override void visitParam(Param ast)
    {
        print("Param(");
        visit(ast.t);
        visit(ast.id);
        visit(ast.def);
        print(")");
    }

    override void visitCompoundStatement(CompoundStatement ast)
    {
        print("CompoundStatement(");
        visit(ast.s);
        print(")");
    }

    override void visitReturnStatement(ReturnStatement ast)
    {
        print("ReturnStatement(");
        visit(ast.e);
        print(")");
    }

    override void visitExpressionStatement(ExpressionStatement ast)
    {
        print("ExpressionStatement(");
        visit(ast.e);
        print(")");
    }

    override void visitVersionStatement(VersionStatement ast)
    {
        print("VersionStatement(");
        assert(ast.cond.length == ast.s.length);
        depth++;
        foreach(i; 0..ast.cond.length)
        {
            print("Body(");
            visit(ast.cond[i]);
            visit(ast.s[i]);
            print(")");
        }
        depth--;
        print(")");
    }

    override void visitIfStatement(IfStatement ast)
    {
        print("IfStatement(");
        visit(ast.e);
        visit(ast.sbody);
        visit(ast.selse);
        print(")");
    }

    override void visitForStatement(ForStatement ast)
    {
        print("ForStatement(");
        visit(ast.init);
        visit(ast.cond);
        visit(ast.inc);
        visit(ast.sbody);
        print(")");
    }

    override void visitSwitchStatement(SwitchStatement ast)
    {
        print("SwitchStatement(");
        visit(ast.e);
        visit(ast.sbody);
        print(")");
    }

    override void visitCaseStatement(CaseStatement ast)
    {
        print("CaseStatement(");
        visit(ast.e);
        print(")");
    }

    override void visitBreakStatement(BreakStatement ast)
    {
        print("BreakStatement(");
        print(")");
    }

    override void visitContinueStatement(ContinueStatement ast)
    {
        print("ContinueStatement(");
        print(")");
    }

    override void visitDefaultStatement(DefaultStatement ast)
    {
        print("DefaultStatement(");
        print(")");
    }

    override void visitWhileStatement(WhileStatement ast)
    {
        print("WhileStatement(");
        visit(ast.e);
        visit(ast.sbody);
        print(")");
    }

    override void visitDoWhileStatement(DoWhileStatement ast)
    {
        print("DoWhileStatement(");
        visit(ast.e);
        visit(ast.sbody);
        print(")");
    }

    override void visitGotoStatement(GotoStatement ast)
    {
        print("GotoStatement(");
        visit(ast.id);
        print(")");
    }

    override void visitLabelStatement(LabelStatement ast)
    {
        print("LabelStatement(");
        visit(ast.id);
        print(")");
    }

    override void visitDanglingElseStatement(DanglingElseStatement ast)
    {
        print("DanglingElseStatement(");
        visit(ast.sbody);
        print(")");
    }

}