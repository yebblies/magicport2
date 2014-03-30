
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

    auto srcdir = args[1];
    auto destdir = args[2];

    auto settings = parseJSON(readText("settings.json")).object;
    auto src = settings["src"].array.map!"a.str"().array;
    auto mapping = settings["mapping"].array.loadMapping();
    foreach(t; settings["basicTypes"].array.map!"a.str")
        basicTypes[t] = false;
    foreach(t; settings["structTypes"].array.map!"a.str")
        structTypes[t] = false;
    foreach(t; settings["classTypes"].array.map!"a.str")
        classTypes[t] = false;

    auto scan = new Scanner();
    foreach(xfn; src)
    {
        auto fn = buildPath(srcdir, xfn);
        writeln("loading -- ", fn);
        assert(fn.exists(), fn ~ " does not exist");
        auto pp = cast(string)read(fn);
        pp = pp.replace("\"v\"\n#include \"verstr.h\"\n    ;", "__IMPORT__;");
        asts ~= parse(Lexer(pp, fn), fn);
        asts[$-1].visit(scan);
    }

    foreach(t, used; basicTypes)
        if (!used)
            writeln("type ", t, " not referenced");
    foreach(t, used; structTypes)
        if (!used)
            writeln("type ", t, " not referenced");
    foreach(t, used; classTypes)
        if (!used)
            writeln("type ", t, " not referenced");

    writeln("collapsing ast...");
    auto superast = collapse(asts, scan);
    auto map = buildMap(superast);
    auto longmap = buildLongMap(superast);

    bool failed;
    try { mkdir(destdir); } catch {}
    foreach(m; mapping)
    {
        auto dir = buildPath(destdir, m.p);
        if (m.p.length)
            try { mkdir(dir); } catch {}

        auto fn = buildPath(dir, m.m).setExtension(".d");
        auto f = File(fn, "wb");
        writeln("writing -- ", fn);

        f.writeln(
"// Compiler implementation of the D programming language
// Copyright (c) 1999-2014 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.");

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

        foreach(e; m.extra)
        {
            f.writeln(e);
        }
        if (m.extra.length)
            f.writeln();

        auto printer = new DPrinter((string s) { f.write(s); }, scan);
        foreach(d; m.members)
        {
            if (auto p = d in map)
            {
                if (!p.d)
                {
                    writeln(d, " needs mangled name");
                    foreach(id, x; longmap)
                    {
                        if (id.startsWith(d))
                        {
                            writeln(" - ", id);
                        }
                    }
                }
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
            assert(d.d, id);
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
    string[] extra;
}

auto loadMapping(JSONValue[] modules)
{
    M[] r;
    foreach(j; modules)
    {
        auto imports = j.object["imports"].array.map!"a.str"().array;
        sort(imports);
        string[] extra;
        if ("extra" in j.object)
            extra = j.object["extra"].array.map!"a.str"().array;
        r ~= M(
            j.object["module"].str,
            j.object["package"].str,
            imports,
            j.object["members"].array.map!"a.str"().array,
            extra
        );
    }
    return r;
}
