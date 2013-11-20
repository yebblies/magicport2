
import std.conv;
import std.algorithm;
import std.stdio;
import std.string;
import std.path;

import tokens;
import ast;
import visitor;
import dprinter;


class Scanner : Visitor
{
    FuncDeclaration[] funcDeclarations;
    FuncDeclaration[string] funcDeclarationsTakingLoc;
    FuncBodyDeclaration[] funcBodyDeclarations;
    StructDeclaration[] structsUsingInheritance;
    StaticMemberVarDeclaration[] staticMemberVarDeclarations;
    CallExpr[] callExprs;
    NewExpr[] newExprs;
    ConstructDeclaration[] constructDeclarations;
    string agg;
    StructDeclaration scopedecl;
    int realdecls;

    this()
    {
    }

    void visit(int line = __LINE__)(Ast ast)
    {
        if (!ast)
            writeln(line);
        assert(ast);
        ast.visit(this);
    }
    
    ////////////////////////////////////

    override void visitModule(Module ast)
    {
        foreach(d; ast.decls)
            visit(d);
    }

    override void visitImportDeclaration(ImportDeclaration ast)
    {
    }

    override void visitFuncDeclaration(FuncDeclaration ast)
    {
        realdecls++;
        funcDeclarations ~= ast;
        ast.structid = agg;
        visit(ast.type);
        if (ast.params.length && ast.params[0].t.id == "Loc")
            funcDeclarationsTakingLoc[ast.id] = ast;
        foreach(p; ast.params)
            visit(p);
        foreach(s; ast.fbody)
            visit(s);
        foreach(i; ast.initlist)
        {
            visit(i.func);
            foreach(a; i.args)
                visit(a);
        }
    }

    override void visitFuncBodyDeclaration(FuncBodyDeclaration ast)
    {
        funcBodyDeclarations ~= ast;
        visit(ast.type);
        foreach(p; ast.params)
            visit(p);
        foreach(s; ast.fbody)
            visit(s);
        foreach(i; ast.initlist)
        {
            visit(i.func);
            foreach(a; i.args)
                visit(a);
        }
    }

    override void visitStaticMemberVarDeclaration(StaticMemberVarDeclaration ast)
    {
        staticMemberVarDeclarations ~= ast;
        visit(ast.type);
        if (ast.xinit)
            visit(ast.xinit);
    }

    override void visitVarDeclaration(VarDeclaration ast)
    {
        realdecls++;
        foreach(t; ast.types)
            if (t)
                visit(t);
        foreach(i; ast.inits)
            if (i)
                visit(i);
    }

    override void visitConstructDeclaration(ConstructDeclaration ast)
    {
        realdecls++;
        constructDeclarations ~= ast;
        visit(ast.type);
        foreach(a; ast.args)
            visit(a);
    }

    override void visitVersionDeclaration(VersionDeclaration ast)
    {
        auto rd = realdecls;
        ast.realdecls.length = ast.cond.length;
        foreach(e; ast.cond)
            if (e)
                visit(e);
        foreach(i, ds; ast.members)
        {
            realdecls = 0;
            foreach(d; ds)
                visit(d);
            ast.realdecls[i] = realdecls;
            rd += realdecls;
            break;
        }
        realdecls = rd;
    }

    override void visitTypedefDeclaration(TypedefDeclaration ast)
    {
        realdecls++;
        visit(ast.t);
    }

    override void visitMacroDeclaration(MacroDeclaration ast)
    {
        realdecls++;
    }

    override void visitMacroUnDeclaration(MacroUnDeclaration ast)
    {
    }

    override void visitStructDeclaration(StructDeclaration ast)
    {
        realdecls++;
        auto aggsave = agg;
        scope(exit) agg = aggsave;
        agg = ast.id;
        if (ast.superid)
            structsUsingInheritance ~= ast;
        if (ast.id == "Scope")
            scopedecl = ast;
        foreach(d; ast.decls)
            visit(d);
    }

    override void visitAnonStructDeclaration(AnonStructDeclaration ast)
    {
        realdecls++;
        foreach(d; ast.decls)
            visit(d);
    }

    override void visitExternCDeclaration(ExternCDeclaration ast)
    {
        foreach(d; ast.decls)
            visit(d);
    }

    override void visitEnumDeclaration(EnumDeclaration ast)
    {
        realdecls++;
        foreach(v; ast.vals)
            if (v)
                visit(v);
    }

    override void visitDummyDeclaration(DummyDeclaration ast)
    {
    }

    override void visitErrorDeclaration(ErrorDeclaration ast)
    {
        realdecls++;
    }

    override void visitProtDeclaration(ProtDeclaration ast)
    {
    }

    override void visitAlignDeclaration(AlignDeclaration ast)
    {
    }

    override void visitLitExpr(LitExpr ast)
    {
    }

    override void visitIdentExpr(IdentExpr ast)
    {
    }

    override void visitDotIdExpr(DotIdExpr ast)
    {
        visit(ast.e);
    }

    override void visitCallExpr(CallExpr ast)
    {
        callExprs ~= ast;
        visit(ast.func);
        foreach(a; ast.args)
            visit(a);
    }

    override void visitCmpExpr(CmpExpr ast)
    {
        visit(ast.e1);
        visit(ast.e2);
    }

    override void visitMulExpr(MulExpr ast)
    {
        visit(ast.e1);
        visit(ast.e2);
    }

    override void visitAddExpr(AddExpr ast)
    {
        visit(ast.e1);
        visit(ast.e2);
    }

    override void visitOrOrExpr(OrOrExpr ast)
    {
        visit(ast.e1);
        visit(ast.e2);
    }

    override void visitAndAndExpr(AndAndExpr ast)
    {
        visit(ast.e1);
        visit(ast.e2);
    }

    override void visitOrExpr(OrExpr ast)
    {
        visit(ast.e1);
        visit(ast.e2);
    }

    override void visitXorExpr(XorExpr ast)
    {
        visit(ast.e1);
        visit(ast.e2);
    }

    override void visitAndExpr(AndExpr ast)
    {
        visit(ast.e1);
        visit(ast.e2);
    }

    override void visitAssignExpr(AssignExpr ast)
    {
        visit(ast.e1);
        visit(ast.e2);
    }

    override void visitDeclarationExpr(DeclarationExpr ast)
    {
        visit(ast.d);
    }

    override void visitPostExpr(PostExpr ast)
    {
        visit(ast.e);
    }

    override void visitPreExpr(PreExpr ast)
    {
        visit(ast.e);
    }

    override void visitPtrExpr(PtrExpr ast)
    {
        visit(ast.e);
    }

    override void visitAddrExpr(AddrExpr ast)
    {
        visit(ast.e);
    }

    override void visitNegExpr(NegExpr ast)
    {
        visit(ast.e);
    }

    override void visitComExpr(ComExpr ast)
    {
        visit(ast.e);
    }

    override void visitDeleteExpr(DeleteExpr ast)
    {
        visit(ast.e);
    }

    override void visitNotExpr(NotExpr ast)
    {
        visit(ast.e);
    }

    override void visitIndexExpr(IndexExpr ast)
    {
        visit(ast.e);
        foreach(a; ast.args)
            visit(a);
    }

    override void visitCondExpr(CondExpr ast)
    {
        visit(ast.cond);
        visit(ast.e1);
        visit(ast.e2);
    }

    override void visitCastExpr(CastExpr ast)
    {
        visit(ast.t);
        visit(ast.e);
    }

    override void visitNewExpr(NewExpr ast)
    {
        newExprs ~= ast;
        if (ast.dim)
            visit(ast.dim);
        visit(ast.t);
        foreach(a; ast.args)
            visit(a);
    }

    override void visitOuterScopeExpr(OuterScopeExpr ast)
    {
        visit(ast.e);
    }

    override void visitCommaExpr(CommaExpr ast)
    {
        visit(ast.e1);
        visit(ast.e2);
    }

    override void visitSizeofExpr(SizeofExpr ast)
    {
        if (ast.e)
            visit(ast.e);
        else
            visit(ast.t);
    }

    override void visitExprInit(ExprInit ast)
    {
        visit(ast.e);
    }

    override void visitArrayInit(ArrayInit ast)
    {
        foreach(i; ast.xinit)
            visit(i);
    }

    override void visitBasicType(BasicType ast)
    {
    }

    override void visitClassType(ClassType ast)
    {
    }

    override void visitEnumType(EnumType ast)
    {
    }

    override void visitPointerType(PointerType ast)
    {
        visit(ast.next);
    }

    override void visitRefType(RefType ast)
    {
        visit(ast.next);
    }

    override void visitArrayType(ArrayType ast)
    {
        visit(ast.next);
        if (ast.dim)
            visit(ast.dim);
    }

    override void visitFunctionType(FunctionType ast)
    {
        visit(ast.next);
        foreach(p; ast.params)
            visit(p);
    }

    override void visitTemplateType(TemplateType ast)
    {
        visit(ast.next);
        visit(ast.param);
    }

    override void visitQualifiedType(QualifiedType ast)
    {
        visit(ast.next);
    }

    override void visitParam(Param ast)
    {
        if (ast.t)
            visit(ast.t);
        if (ast.def)
            visit(ast.def);
    }

    override void visitCompoundStatement(CompoundStatement ast)
    {
        foreach(s; ast.s)
            visit(s);
    }

    override void visitReturnStatement(ReturnStatement ast)
    {
        if (ast.e)
            visit(ast.e);
    }

    override void visitExpressionStatement(ExpressionStatement ast)
    {
        if (ast.e)
            visit(ast.e);
    }

    override void visitVersionStatement(VersionStatement ast)
    {
        foreach(e; ast.cond)
            if (e)
                visit(e);
        foreach(ss; ast.members)
            foreach(s; ss)
                visit(s);
    }

    override void visitIfStatement(IfStatement ast)
    {
        visit(ast.e);
        visit(ast.sbody);
        if (ast.selse)
            visit(ast.selse);
    }

    override void visitForStatement(ForStatement ast)
    {
        if (ast.xinit)
            visit(ast.xinit);
        if (ast.cond)
            visit(ast.cond);
        if (ast.inc)
            visit(ast.inc);
        visit(ast.sbody);
    }

    override void visitSwitchStatement(SwitchStatement ast)
    {
        visit(ast.e);
        foreach(s; ast.sbody)
            visit(s);
    }

    override void visitCaseStatement(CaseStatement ast)
    {
        visit(ast.e);
    }

    override void visitBreakStatement(BreakStatement ast)
    {
    }

    override void visitContinueStatement(ContinueStatement ast)
    {
    }

    override void visitDefaultStatement(DefaultStatement ast)
    {
    }

    override void visitWhileStatement(WhileStatement ast)
    {
        visit(ast.e);
        visit(ast.sbody);
    }

    override void visitDoWhileStatement(DoWhileStatement ast)
    {
        visit(ast.e);
        visit(ast.sbody);
    }

    override void visitGotoStatement(GotoStatement ast)
    {
    }

    override void visitLabelStatement(LabelStatement ast)
    {
    }

};


Module collapse(Module[] mods, Scanner scan)
{
    Declaration[] decls;

    foreach(mod; mods)
        decls ~= resolveVersions(mod.decls);
    
    decls = removeDuplicates(decls);
    findProto(decls, scan);
    
    funcBodies(scan);

    scopeCtor(scan);

    return new Module("dmd.d", decls);
}

void funcBodies(Scanner scan)
{
    foreach(fd; scan.funcDeclarations)
    {
        foreach(fb; scan.funcBodyDeclarations)
        {
            if (fd.structid == fb.id && fd.id == fb.id2)
            {
                auto tf1 = new FunctionType(fd.type, fd.params);
                auto tf2 = new FunctionType(fb.type, fb.params);
                if (typeMatch(tf1, tf2))
                {
                    assert(!fd.hasbody && fb.hasbody, fd.id);
                    fd.fbody = fb.fbody;
                    fd.hasbody = true;
                    if (fb.initlist)
                        fd.initlist = fb.initlist;
                    foreach(i; 0..tf1.params.length)
                    {
                        //if (tf2.params[i].id)
                            tf1.params[i].id = tf2.params[i].id;
                    }
                }
            }
        }
    }
}

void findProto(Declaration[] decls, Scanner scan)
{
    foreach(f1; scan.funcDeclarations)
    {
        foreach(f2; scan.funcDeclarations)
        {
            if (!f2.hasbody && f1.id == f2.id)
            {
                auto tf1 = new FunctionType(f1.type, f1.params);
                auto tf2 = new FunctionType(f2.type, f2.params);
                assert(tf1 && tf2);
                if (typeMatch(tf1, tf2))
                {
                    f2.skip = true;
                    if (f1.hasbody)
                    {
                        foreach(i; 0..tf1.params.length)
                        {
                            if (tf1.params[i].def && tf2.params[i].def)
                            {
                                assert(typeid(tf1.params[i].def) == typeid(tf2.params[i].def)); // Good enough for now
                            }
                            tf1.params[i].def = tf2.params[i].def;
                        }
                    }
                }
            }
        }
    }
}

Declaration[] removeDuplicates(Declaration[] decls)
{
    Declaration[] r;
    foreach(d; decls)
    {
        auto exists = false;
        foreach(x; r)
        {
            if (typeid(x) == typeid(d))
            {
                if (auto tdd = cast(TypedefDeclaration)d)
                {
                    auto d2 = cast(TypedefDeclaration)x;
                    if (tdd.id == d2.id)
                        exists = true;
                }
            }
        }
        if (!exists)
        {
            r ~= d;
        }
    }
    return r;
}

Declaration[] resolveVersions(Declaration[] decls)
{
    Declaration[] r;
    foreach(d; decls)
    {
        if (auto vd = cast(VersionDeclaration)d)
        {
            // Do not emit static ifs for include guards
            if (vd.cond.length == 1)
            {
                auto ne = cast(NotExpr)vd.cond[0];
                if (ne)
                {
                    auto ie = cast(IdentExpr)ne.e;
                    if (ie.id.endsWith("_H"))
                    {
                        r ~= resolveVersions(vd.members[0]);
                        continue;
                    }
                }
                if (vd.realdecls[0] == 0)
                    continue;
            }
        }
        r ~= d;
    }
    return r;
}

// Generate initializers for all of Scope's variables from its default ctor
// And generate copy ctor
void scopeCtor(Scanner scan)
{
    foreach(f; scan.funcDeclarations)
    {
        if (f.type.id == f.id && f.id == "Scope" && f.params.length == 0)
        {
            Init[string] inits;
            Statement[] cbody;
            foreach(s; f.fbody)
            {
                auto es = cast(ExpressionStatement)s;
                assert(es);
                auto ae = cast(AssignExpr)es.e;
                assert(ae);
                auto de = cast(DotIdExpr)ae.e1;
                assert(de);
                auto te = cast(IdentExpr)de.e;
                assert(te);
                assert(te.id == "this");
                inits[de.id] = new ExprInit(ae.e2);
                cbody ~= new ExpressionStatement(new AssignExpr("=", de, new DotIdExpr(".", new IdentExpr("sc"), de.id)));
            }
            foreach(m; scan.scopedecl.decls)
            {
                auto vd = cast(VarDeclaration)m;
                if (vd)
                {
                    assert(vd.types.length == 1);
                    assert(!vd.inits[0]);
                    auto p = vd.ids[0] in inits;
                    if (p)
                    {
                        vd.inits[0] = *p;
                    }
                }
            }
            auto p = [new Param(new RefType(new ClassType("Scope")), "sc", null)];
            scan.scopedecl.decls ~= new FuncDeclaration(new ClassType("Scope"), "Scope", p, cbody, 0, null, true);
            return;
        }
    }
}
