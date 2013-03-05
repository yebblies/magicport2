
import tokens : Token;
import visitor;

/********************************************************/

enum
{
    STCstatic = 1,
    STCconst = 2,
    STCextern = 4,
    STCexternc = 8,
    STCvirtual = 16,
    STCcdecl = 32,
    STCabstract = 64,
    STCinline = 128,
    STCregister = 256,
};
alias uint STC;

enum visitor_str = `override void visit(Visitor v) { v.depth++; mixin("v.visit" ~ typeof(this).stringof ~ "(this);"); v.depth--; }`;

class Ast
{
    abstract void visit(Visitor v);
};

class Module : Ast
{
    string file;
    Declaration[] decls;
    this(string file, Declaration[] decls) { this.file = file; this.decls = decls; }
    mixin(visitor_str);
}

class Declaration : Ast
{
};

class ImportDeclaration : Declaration
{
    string fn;
    this(string fn) { this.fn = fn; }
    mixin(visitor_str);
};

class FuncDeclaration : Declaration
{
    Type type;
    string id;
    Param[] params;
    Statement fbody;
    STC stc;
    Type supertype;
    Expression[] superargs;
    string structid;
    this(Type type, string id, Param[] params, Statement fbody, STC stc, Type supertype, Expression[] superargs) { this.type = type; this.id = id; this.params = params; this.fbody = fbody; this.stc = stc; this.supertype = supertype; this.superargs = superargs; }
    mixin(visitor_str);
    bool skip;
}

class FuncBodyDeclaration : Declaration
{
    Type type;
    string id;
    string id2;
    Param[] params;
    Statement fbody;
    STC stc;
    Type supertype;
    Expression[] superargs;
    this(Type type, string id, string id2, Param[] params, Statement fbody, STC stc, Type supertype, Expression[] superargs)
    { this.type = type; this.id = id; this.id2 = id2; this.params = params; this.fbody = fbody; this.stc = stc; this.supertype = supertype; this.superargs = superargs; }
    mixin(visitor_str);
}

class StaticMemberVarDeclaration : Declaration
{
    Type type;
    string id;
    string id2;
    Init xinit;
    this(Type type, string id, string id2, Init xinit = null) { this.type = type; this.id = id; this.id2 = id2; this.xinit = xinit; }
    mixin(visitor_str);
}

class VarDeclaration : Declaration
{
    Type[] types;
    string[] ids;
    Init[] inits;
    STC stc;
    this(Type type, string id, Init xinit, STC stc) { this.types = [type]; this.ids = [id]; this.inits = [xinit]; this.stc = stc; }
    this(Type[] types, string[] ids, Init[] inits, STC stc) { this.types = types; this.ids = ids; this.inits = inits; this.stc = stc; }
    mixin(visitor_str);
}

class ConstructDeclaration : Declaration
{
    Type type;
    string id;
    Expression[] args;
    this(Type type, string id, Expression[] args) { this.type = type; this.id = id; this.args = args; }
    mixin(visitor_str);
}

class VersionDeclaration : Declaration
{
    Expression[] es;
    Declaration[][] ds;
    this(Expression[] es, Declaration[][] ds) { this.es = es; this.ds = ds; }
    mixin(visitor_str);
}

class TypedefDeclaration : Declaration
{
    Type t;
    string id;
    this(Type t, string id) { this.t = t; this.id = id; }
    mixin(visitor_str);
}

class MacroDeclaration : Declaration
{
    string id;
    string[] params;
    //Token[] toks;
    Expression e;
    this(string id, string[] params, Expression e) { this.id = id; this.params = params; this.e = e; }
    mixin(visitor_str);
}

class MacroUnDeclaration : Declaration
{
    string id;
    this(string id) { this.id = id; }
    mixin(visitor_str);
}

class MacroCallDeclaration : Declaration
{
    string id;
    string[] args;
    this(string id, string[] args) { this.id = id; this.args = args; }
    mixin(visitor_str);
}

class StructDeclaration : Declaration
{
    string kind;
    string id;
    string superid;
    Declaration[] decls;
    this(string kind, string id, Declaration[] decls, string superid) { this.kind = kind; this.id = id; this.decls = decls; this.superid = superid; }
    mixin(visitor_str);
}

class AnonStructDeclaration : Declaration
{
    string kind;
    string id;
    Declaration[] decls;
    this(string kind, string id, Declaration[] decls) { this.kind = kind; this.id = id; this.decls = decls; }
    mixin(visitor_str);
}

class ExternCDeclaration : Declaration
{
    bool block;
    Declaration[] decls;
    this(Declaration[] decls) { this.decls = decls; block = true; }
    this(Declaration decls) { this.decls = [decls]; block = false; }
    mixin(visitor_str);
}

class EnumDeclaration : Declaration
{
    string id;
    string[] members;
    Expression[] vals;
    this (string id, string[] members, Expression[] vals) { this.id = id; this.members = members; this.vals = vals; }
    mixin(visitor_str);
}

class DummyDeclaration : Declaration
{
    string s;
    this() { }
    this(string s) { this.s = s; }
    mixin(visitor_str);
}

class BitfieldDeclaration : Declaration
{
    Type type;
    string id;
    Expression width;
    this(Type type, string id, Expression width) { this.type = type; this.id = id; this.width = width; }
    mixin(visitor_str);
}

class ProtDeclaration : Declaration
{
    string id;
    this(string id) { this.id = id; }
    mixin(visitor_str);
}

class AlignDeclaration : Declaration
{
    int id;
    this(int id) { this.id = id; }
    mixin(visitor_str);
}

/********************************************************/

class Expression : Ast
{
};

class LitExpr : Expression
{
    string val;
    this(string val) { this.val = val; }
    mixin(visitor_str);
};

class IdentExpr : Expression
{
    string id;
    this(string id) { this.id = id; }
    mixin(visitor_str);
}

class DotIdExpr : Expression
{
    string op;
    Expression e;
    string id;
    this (string op, Expression e, string id) { this.op = op; this.e = e; this.id = id; }
    mixin(visitor_str);
}

class CallExpr : Expression
{
    Expression func;
    Expression[] args;
    this(Expression func, Expression[] args) { this.func = func; this.args = args; }
    mixin(visitor_str);
}

class BinaryExpr : Expression
{
    string op;
    Expression e1, e2;
    this(string op, Expression e1, Expression e2) { this.op = op; this.e1 = e1; this.e2 = e2; }
}

class CmpExpr : BinaryExpr
{
    this(string op, Expression e1, Expression e2) { super(op, e1, e2); }
    mixin(visitor_str);
}

class MulExpr : BinaryExpr
{
    this(string op, Expression e1, Expression e2) { super(op, e1, e2); }
    mixin(visitor_str);
}

class AddExpr : BinaryExpr
{
    this(string op, Expression e1, Expression e2) { super(op, e1, e2); }
    mixin(visitor_str);
}

class OrOrExpr : BinaryExpr
{
    this(Expression e1, Expression e2) { super("||", e1, e2); }
    mixin(visitor_str);
}

class AndAndExpr : BinaryExpr
{
    this(Expression e1, Expression e2) { super("&&", e1, e2); }
    mixin(visitor_str);
}

class OrExpr : BinaryExpr
{
    this(Expression e1, Expression e2) { super("|", e1, e2); }
    mixin(visitor_str);
}

class XorExpr : BinaryExpr
{
    this(Expression e1, Expression e2) { super("^", e1, e2); }
    mixin(visitor_str);
}

class AndExpr : BinaryExpr
{
    this(Expression e1, Expression e2) { super("&", e1, e2); }
    mixin(visitor_str);
}

class AssignExpr : BinaryExpr
{
    this(string op, Expression e1, Expression e2) { super(op, e1, e2); }
    mixin(visitor_str);
}

class DeclarationExpr : Expression
{
    Declaration d;
    this(Declaration d) { this.d = d; }
    mixin(visitor_str);
}

class UnaryExpr : Expression
{
    string op;
    Expression e;
    this(string op, Expression e) { this.op = op; this.e = e; }
}

class PostExpr : UnaryExpr
{
    this(string op, Expression e) { super(op, e); }
    mixin(visitor_str);
}

class PreExpr : UnaryExpr
{
    this(string op, Expression e) { super(op, e); }
    mixin(visitor_str);
}

class PtrExpr : UnaryExpr
{
    this(Expression e) { super("ptr", e); }
    mixin(visitor_str);
}

class AddrExpr : UnaryExpr
{
    this(Expression e) { super("&", e); }
    mixin(visitor_str);
}

class NegExpr : UnaryExpr
{
    this(Expression e) { super("-", e); }
    mixin(visitor_str);
}

class ComExpr : UnaryExpr
{
    this(Expression e) { super("~", e); }
    mixin(visitor_str);
}

class DeleteExpr : UnaryExpr
{
    this(Expression e) { super("delete", e); }
    mixin(visitor_str);
}

class NotExpr : UnaryExpr
{
    this(Expression e) { super("!", e); }
    mixin(visitor_str);
}

class StringofExpr : UnaryExpr
{
    this(Expression e) { super("#", e); }
    mixin(visitor_str);
}

class IndexExpr : Expression
{
    Expression e;
    Expression[] args;
    this(Expression e, Expression[] args) { this.e = e; this.args = args; }
    mixin(visitor_str);
}

class CondExpr : Expression
{
    Expression cond, e1, e2;
    this (Expression cond, Expression e1, Expression e2) { this.cond = cond; this.e1 = e1; this.e2 = e2; }
    mixin(visitor_str);
}

class CastExpr : Expression
{
    Type t;
    Expression e;
    this(Type t, Expression e) { this.t = t; this.e = e; }
    mixin(visitor_str);
}

class NewExpr : Expression
{
    Type t;
    Expression[] args;
    Expression dim;
    this(Type t, Expression[] args, Expression dim) { this.t = t; this.args = args; this.dim = dim; }
    mixin(visitor_str);
}

class OuterScopeExpr : UnaryExpr
{
    this(Expression e) { super("::", e); }
    mixin(visitor_str);
}

class CommaExpr : BinaryExpr
{
    this(Expression e1, Expression e2) { super(",", e1, e2); }
    mixin(visitor_str);
}

class SizeofExpr : Expression
{
    Type t;
    Expression e;
    this(Type t) { this.t = t; }
    this(Expression e) { this.e = e; }
    mixin(visitor_str);
}

/********************************************************/

class Init : Ast
{
}

class ExprInit : Init
{
    Expression e;
    this (Expression e) { this.e = e; }
    mixin(visitor_str);
}

class ArrayInit : Init
{
    Init[] xinit;
    this (Expression[] e) { foreach(v; e) this.xinit ~= new ExprInit(v); }
    this (Init[] xinit) { this.xinit = xinit; }
    mixin(visitor_str);
}

/********************************************************/

class Type : Ast
{
    string id;
    bool isConst;
};

class BasicType : Type
{
    this(string id) { this.id = id; }
    mixin(visitor_str);
}

class ClassType : Type
{
    this(string id) { this.id = id; }
    mixin(visitor_str);
}

class EnumType : Type
{
    this(string id) { this.id = id; }
    mixin(visitor_str);
}

class PointerType : Type
{
    Type next;
    this(Type next) { this.next = next; }
    mixin(visitor_str);
}

class RefType : Type
{
    Type next;
    this(Type next) { this.next = next; }
    mixin(visitor_str);
}

class ArrayType : Type
{
    Type next;
    Expression dim;
    this(Type next, Expression dim) { this.next = next; this.dim = dim; }
    mixin(visitor_str);
}

class FunctionType : Type
{
    Type next;
    Param[] params;
    bool cdecl;
    this(Type next, Param[] params) { this.next = next; this.params = params; }
    mixin(visitor_str);
}

class TemplateType : Type
{
    Type next;
    Type param;
    this(Type next, Type param) { this.next = next; this.param = param; }
    mixin(visitor_str);
}

class QualifiedType : Type
{
    Type next;
    string id;
    this(Type next, string id) { this.next = next; this.id = id; }
    mixin(visitor_str);
}

/********************************************************/

class Param : Ast
{
    Type t;
    string id;
    Expression def;
    this(Type t, string id, Expression def) { this.t = t; this.id = id; this.def = def; }
    mixin(visitor_str);
};

/********************************************************/

class Statement : Ast
{
};

class CompoundStatement : Statement
{
    Statement[] s;
    this(Statement[] s) { this.s = s; }
    mixin(visitor_str);
};

class ReturnStatement : Statement
{
    Expression e;
    this(Expression e) { this.e = e; }
    mixin(visitor_str);
}

class ExpressionStatement : Statement
{
    Expression e;
    this(Expression e) { this.e = e; }
    mixin(visitor_str);
}

class VersionStatement : Statement
{
    Expression[] cond;
    Statement[][] s;
    Statement selse;
    this(Expression[] cond, Statement[][] s, Statement selse) { this.cond = cond; this.s = s; this.selse = selse; }
    mixin(visitor_str);
}

class IfStatement : Statement
{
    Expression e;
    Statement sbody;
    Statement selse;
    this(Expression e, Statement sbody, Statement selse) { this.e = e; this.sbody = sbody; this.selse = selse; }
    mixin(visitor_str);
}

class ForStatement : Statement
{
    Expression xinit, cond, inc;
    Statement sbody;
    this(Expression xinit, Expression cond, Expression inc, Statement sbody) { this.xinit = xinit; this.cond = cond; this.inc = inc; this.sbody = sbody; }
    mixin(visitor_str);
}

class SwitchStatement : Statement
{
    Expression e;
    Statement sbody;
    this(Expression e, Statement sbody) { this.e = e; this.sbody = sbody; }
    mixin(visitor_str);
}

class CaseStatement : Statement
{
    Expression e;
    this(Expression e) { this.e = e; }
    mixin(visitor_str);
}

class BreakStatement : Statement
{
    this() {}
    mixin(visitor_str);
}

class ContinueStatement : Statement
{
    this() {}
    mixin(visitor_str);
}

class DefaultStatement : Statement
{
    this() {}
    mixin(visitor_str);
}

class WhileStatement : Statement
{
    Expression e;
    Statement sbody;
    this(Expression e, Statement sbody) { this.e = e; this.sbody = sbody; }
    mixin(visitor_str);
}

class DoWhileStatement : Statement
{
    Expression e;
    Statement sbody;
    this(Statement sbody, Expression e) { this.e = e; this.sbody = sbody; }
    mixin(visitor_str);
}

class GotoStatement : Statement
{
    string id;
    this(string id) { this.id = id; }
    mixin(visitor_str);
}

class LabelStatement : Statement
{
    string id;
    this(string id) { this.id = id; }
    mixin(visitor_str);
}

class DanglingElseStatement : Statement
{
    Statement sbody;
    this(Statement sbody) { this.sbody = sbody; }
    mixin(visitor_str);
}


bool typeMatch(Type t1, Type t2)
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
        return true;
    }
    assert(cast(ClassType)t1 || cast(BasicType)t1 || cast(EnumType)t1, typeid(t1).toString());
    return true;
}
