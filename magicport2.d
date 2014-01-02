
import std.file;
import std.stdio;
import std.range;
import std.path;
import std.algorithm;
import std.json;

import tokens;
import parser;
import dprinter;
import scanner;
import ast;
import namer;
import typenames;

void main(string[] args)
{
    Module[] asts;

    auto settings = parseJSON(readText("settings.json")).object;
    auto src = settings["src"].array.map!"a.str"().array;
    auto mapping = settings["mapping"].array.loadMapping();
    basicTypes = settings["basicTypes"].array.map!"a.str".array();
    structTypes = settings["structTypes"].array.map!"a.str".array();
    classTypes = settings["classTypes"].array.map!"a.str".array();

    auto scan = new Scanner();
    foreach(xfn; src)
    {
        auto fn = buildPath(args[1], xfn);
        writeln("loading -- ", fn);
        assert(fn.exists(), fn ~ " does not exist");
        auto pp = cast(string)read(fn);
        pp = pp.replace("\"v\"\n#include \"verstr.h\"\n    ;", "__IMPORT__;");
        asts ~= parse(Lexer(pp, fn), fn);
        asts[$-1].visit(scan);
    }

    writeln("collapsing ast...");
    auto superast = collapse(asts, scan);
    auto map = buildMap(superast);
    auto longmap = buildLongMap(superast);

    bool failed;
    try { mkdir("port"); } catch {}
    foreach(m; mapping)
    {
        auto dir = buildPath("port", m.p);
        if (m.p.length)
            try { mkdir(dir); } catch {}

        auto fn = buildPath(dir, m.m).setExtension(".d");
        auto f = File(fn, "wb");
        writeln("writing -- ", fn);

        f.writeln();
        if (m.p.length)
            f.writefln("module %s.%s;", m.p, m.m);
        else
            f.writefln("module %s;", m.m);
        f.writeln();

        {
            bool found;
            foreach(i; m.imports)
            {
                if (i.startsWith("root."))
                {
                    if (!found)
                        f.writef("import %s", i);
                    else
                        f.writef(", %s", i);
                    found = true;
                }
            }
            if (found)
                f.writeln(";");
        }
        {
            bool found;
            foreach(i; m.imports)
            {
                if (!i.startsWith("root."))
                {
                    if (!found)
                        f.writef("import %s", i);
                    else
                        f.writef(", %s", i);
                    found = true;
                }
            }
            if (found)
                f.writeln(";");
        }
        if (m.imports.length)
            f.writeln();

        auto printer = new DPrinter((string s) { f.write(s); }, scan);
        foreach(d; m.members)
        {
            if (auto p = d in map)
            {
                if (!p.d)
                    writeln(d, " needs mangled name");
                else
                {
                    printer.visitX(p.d);
                    p.count++;
                }
            }
            else if (auto p = d in longmap)
            {
                assert(p.d);
                map[p.d.getName].count++;
                printer.visitX(p.d);
                p.count++;
            }
            else
            {
                writeln("Not found: ", d);
                failed = true;
            }
        }
    }
    foreach(id, d; map)
    {
        if (d.count == 0)
        {
            assert(d.d);
            writeln("unreferenced: ", d.d.getName);
            failed = true;
        }
        if (d.count > 1 && d.d)
        {
            writeln("duplicate: ", d.d.getName);
        }
    }
    foreach(id, d; longmap)
    {
        if (d.count > 1)
        {
            assert(d.d);
            writeln("duplicate: ", d.d.getName);
        }
    }
    auto manualsrc =
    [
        "intrange.d", "complex.d", "longdouble.d",
        "lib.d",
        "libomf.d", "scanomf.d",
        "libmscoff.d", "scanmscoff.d",
        "libelf.d", "scanelf.d",
    ];
    foreach(fn; manualsrc)
        std.file.write(buildPath("port", fn), buildPath("manual", fn).read());
    foreach(fn; ["aav.d", "array.d", "man.d", "rootobject.d", "outbuffer.d", "port.d", "response.d", "rmem.d", "stringtable.d"])
        std.file.write(buildPath("port", "root", fn), buildPath("manual", "root", fn).read());
    if (failed)
        assert(0);
}

struct D
{
    Declaration d;
    int count;
}

D[string] buildMap(Module m)
{
    D[string] map;
    foreach(d; m.decls)
    {
        auto s = d.getName();
        if (s in map)
            map[s] = D(null, 0);
        else
            map[s] = D(d, 0);
    }
    return map;
}

D[string] buildLongMap(Module m)
{
    D[string] map;
    foreach(d; m.decls)
    {
        auto s = d.getLongName();
        assert(s !in map, s);
        map[s] = D(d, 0);
    }
    return map;
}

struct M
{
    string m;
    string p;
    string[] imports;
    string[] members;
}

auto loadMapping(JSONValue[] modules)
{
    M[] r;
    foreach(j; modules)
    {
        auto imports = j.object["imports"].array.map!"a.str"().array;
        sort(imports);
        r ~= M(
            j.object["module"].str,
            j.object["package"].str,
            imports,
            j.object["members"].array.map!"a.str"().array
        );
    }
    return r;
}
