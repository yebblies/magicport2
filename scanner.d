
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
        funcDeclarations ~= ast;
        ast.structid = agg;
        visit(ast.type);
        if (ast.params.length && ast.params[0].t.id == "Loc")
            funcDeclarationsTakingLoc[ast.id] = ast;
        foreach(p; ast.params)
            visit(p);
        if (ast.fbody)
            visit(ast.fbody);
        if (ast.supertype)
            visit(ast.supertype);
        foreach(a; ast.superargs)
            visit(a);
    }

    override void visitFuncBodyDeclaration(FuncBodyDeclaration ast)
    {
        funcBodyDeclarations ~= ast;
        visit(ast.type);
        foreach(p; ast.params)
            visit(p);
        if (ast.fbody)
            visit(ast.fbody);
        if (ast.supertype)
            visit(ast.supertype);
        foreach(a; ast.superargs)
            visit(a);
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
        foreach(t; ast.types)
            if (t)
                visit(t);
        foreach(i; ast.inits)
            if (i)
                visit(i);
    }

    override void visitConstructDeclaration(ConstructDeclaration ast)
    {
        constructDeclarations ~= ast;
        visit(ast.type);
        foreach(a; ast.args)
            visit(a);
    }

    static bool eval(Expression e)
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
    override void visitVersionDeclaration(VersionDeclaration ast)
    {
        foreach(e; ast.es)
            if (e)
                visit(e);
        foreach(i, ds; ast.ds)
        {
            if (!ast.es[i] || eval(ast.es[i]))
            {
                foreach(d; ds)
                    visit(d);
                break;
            }
        }
    }

    override void visitTypedefDeclaration(TypedefDeclaration ast)
    {
        visit(ast.t);
    }

    override void visitMacroDeclaration(MacroDeclaration ast)
    {
    }

    override void visitMacroUnDeclaration(MacroUnDeclaration ast)
    {
    }

    override void visitMacroCallDeclaration(MacroCallDeclaration ast)
    {
    }

    override void visitStructDeclaration(StructDeclaration ast)
    {
        auto aggsave = agg;
        scope(exit) agg = aggsave;
        agg = ast.id;
        if (ast.superid)
            structsUsingInheritance ~= ast;
        foreach(d; ast.decls)
            visit(d);
    }

    override void visitAnonStructDeclaration(AnonStructDeclaration ast)
    {
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
        foreach(v; ast.vals)
            if (v)
                visit(v);
    }

    override void visitDummyDeclaration(DummyDeclaration ast)
    {
    }

    override void visitBitfieldDeclaration(BitfieldDeclaration ast)
    {
        visit(ast.type);
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
        foreach(ss; ast.s)
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
        visit(ast.sbody);
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

    override void visitDanglingElseStatement(DanglingElseStatement ast)
    {
        visit(ast.sbody);
    }
};


Module collapse(Module[] mods, Scanner scan)
{
    Declaration[] decls;

    foreach(mod; mods)
        decls ~= resolveVersions(mod.decls);
    
    decls = removeDuplicates(decls);
    findProto(decls, scan);
    
    fixMain(decls, scan);

    //zeroToLoc(scan);
    
    funcBodies(scan);

    bufAddr(scan);

    return new Module("dmd.d", decls);
}

void bufAddr(Scanner scan)
{
    auto buffuncs = ["json_generate", "MODtoBuffer", "toCBuffer2", "write", "toCBuffer", "ObjectToCBuffer", "argExpTypesToCBuffer",
        "toMangleBuffer", "writeFilename", "toDecoBuffer", "expand", "modToBuffer", "argsToDecoBuffer",
        "toDocBuffer", "buildArrayIdent", "MODMatchToBuffer", "highlightCode", "highlightCode2", "highlightCode3",
        "emitAnchor", "WriteLibToBuffer", "functionToCBuffer2"];
    auto buffers = ["buf", "argbuf", "bufa", "cmdbuf", "hdrbufr", "buf2", "b", "codebuf", "res", "ancbuf", "libbuf", "thisBuf", "funcBuf"];
    foreach(e; scan.callExprs)
    {
        auto fe = cast(IdentExpr)e.func;
        auto de = cast(DotIdExpr)e.func;
        if (fe || de)
        {
            auto id = fe ? fe.id : de.id;
            if (buffuncs.canFind(id))
            {
                foreach(ref a; e.args)
                {
                    if (auto ae = cast(AddrExpr)a)
                    {
                        if (auto ie = cast(IdentExpr)ae.e)
                        {
                            if (buffers.canFind(ie.id))
                            {
                                a = ie;
                            }
                        }
                    }
                }
            }
        }
    }
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
                    assert(!fd.fbody && fb.fbody);
                    fd.fbody = fb.fbody;
                    if (fb.superargs)
                        fd.superargs = fb.superargs;
                    foreach(i; 0..tf1.params.length)
                    {
                        if (tf2.params[i].id)
                            tf1.params[i].id = tf2.params[i].id;
                    }
                }
            }
        }
    }
}

void zeroToLoc(Scanner scan)
{
    foreach(e; scan.callExprs)
    {
        if (auto ie = cast(IdentExpr)e.func)
        {
            if (e.args.length && cast(LitExpr)e.args[0] && (cast(LitExpr)e.args[0]).val == "0")
            {
                if (auto p = ie.id in scan.funcDeclarationsTakingLoc)
                {
                    e.args[0] = new CallExpr(new IdentExpr("Loc"), null);
                }
            }
        }
    }
    foreach(e; scan.newExprs)
    {
        if (e.args.length && cast(LitExpr)e.args[0] && (cast(LitExpr)e.args[0]).val == "0")
        {
            if (auto p = e.t.id in scan.funcDeclarationsTakingLoc)
            {
                if (e.args.length == p.params.length)
                {
                    e.args[0] = new CallExpr(new IdentExpr("Loc"), null);
                }
            }
        }
    }
    foreach(e; scan.constructDeclarations)
    {
        if (e.args.length && cast(LitExpr)e.args[0] && (cast(LitExpr)e.args[0]).val == "0")
        {
            if (auto p = e.type.id in scan.funcDeclarationsTakingLoc)
            {
                if (e.args.length == p.params.length)
                {
                    e.args[0] = new CallExpr(new IdentExpr("Loc"), null);
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
            if (!f2.fbody && f1.id == f2.id)
            {
                auto tf1 = new FunctionType(f1.type, f1.params);
                auto tf2 = new FunctionType(f2.type, f2.params);
                assert(tf1 && tf2);
                if (typeMatch(tf1, tf2))
                {
                    f2.skip = true;
                    if (f1.fbody)
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
            r ~= resolveVersions(pickWinner(vd));
        }
        else
        {
            r ~= d;
        }
    }
    return r;
}

Declaration[] pickWinner(VersionDeclaration ast)
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
        if (Scanner.eval(c))
        {
            anytrue = true;
            return decls[i];
        } else {
        }
    }
    if (!anytrue && delse)
        return delse;
    return null;
}

void fixMain(Declaration[] decls, Scanner scan)
{
    bool found;
    foreach(fd; scan.funcDeclarations)
    {
        if (fd.id == "main")
        {
            assert(!found);
            fd.id = "xmain";
            found = true;
        }
    }
}
