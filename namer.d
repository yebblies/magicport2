
import std.conv;
import std.path;

import ast;
import visitor;

class Namer : Visitor
{
    string name;
    this()
    {
    }

    alias super.visit visit;

    override void visit(FuncDeclaration ast)
    {
        name = "function " ~ ast.id;
    }

    override void visit(VarDeclaration ast)
    {
        name = "variable " ~ ast.id;
    }

    override void visit(VersionDeclaration ast)
    {
        name = "version " ~ baseName(ast.file) ~ ":" ~ to!string(ast.line);
    }

    override void visit(TypedefDeclaration ast)
    {
        name = "typedef " ~ ast.id;
    }

    override void visit(MacroDeclaration ast)
    {
        name = "macro " ~ ast.id;
    }

    override void visit(StructDeclaration ast)
    {
        name = "struct " ~ ast.id;
    }

    override void visit(ExternCDeclaration ast)
    {
        name = "externc " ~ baseName(ast.file) ~ ":" ~ to!string(ast.line);
    }

    override void visit(EnumDeclaration ast)
    {
        if (ast.id.length)
            name = "enum " ~ ast.id;
        else
            name = "enum " ~ baseName(ast.file) ~ ":" ~ to!string(ast.line);
    }
}

class LongNamer : Namer
{
    alias super.visit visit;

    override void visit(FuncDeclaration ast)
    {
        name = "function " ~ ast.id;
        foreach(p; ast.params)
        {
            name ~= p.t ? p.t.mangle : "??";
        }
    }

}

string getName(Declaration decl)
{
    assert(decl);
    auto v = new Namer();
    decl.visit(v);
    return v.name;
}

string getLongName(Declaration decl)
{
    auto v = new LongNamer();
    decl.visit(v);
    return v.name;
}
