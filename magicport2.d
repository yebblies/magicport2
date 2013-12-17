
import std.file;
import std.stdio;
import std.range;
import std.path;
import std.algorithm;

import tokens;
import parser;
import printercpp;
import dprinter;
import printerast;
import scanner;
import ast;

// "complex_t.h", "intrange.h", "intrange.c", "toelfdebug.c", "libelf.c", "libmach.c", "idgen.c", "libmscoff.c", "scanmscoff.c",
// "iasm.c",
// "eh.c",
// "tocsym.c", "s2ir.c", "todt.c", "e2ir.c", "toobj.c", "glue.c", "toctype.c", "msc.c", "typinf.c", "tocvdebug.c", "irstate.c", "irstate.h", "toir.h", "toir.c",
// "libomf.c", "scanomf.c",

auto frontsrc = [
    "mars.c", "enum.c", "struct.c", "dsymbol.c", "import.c", "utf.h",
    "utf.c", "entity.c", "identifier.c", "mtype.c", "expression.c", "optimize.c", "template.h",
    "template.c", "lexer.c", "declaration.c", "cast.c", "cond.h", "cond.c", "link.c",
    "aggregate.h", "staticassert.h", "parse.c", "statement.c", "constfold.c", "version.h",
    "version.c", "inifile.c", "staticassert.c", "module.c", "scope.c", "dump.c",
    "init.h", "init.c", "attrib.h", "attrib.c", "opover.c", "class.c",
    "mangle.c", "func.c", "inline.c", "access.c",
    "cppmangle.c", "identifier.h", "parse.h", "scope.h", "enum.h", "import.h",
    "mars.h", "module.h", "mtype.h", "dsymbol.h",
    "declaration.h", "lexer.h", "expression.h", "statement.h", "doc.h", "doc.c", "macro.h",
    "macro.c", "hdrgen.h", "hdrgen.c", "arraytypes.h", "delegatize.c",
    "interpret.c", "ctfeexpr.c", "traits.c", "builtin.c", "clone.c", "lib.h",
    "arrayop.c", "aliasthis.h", "aliasthis.c", "json.h", "json.c",
    "unittests.c", "imphint.c", "argtypes.c", "apply.c", "sapply.c", "sideeffect.c",
    "ctfe.h", "canthrow.c", "target.c", "target.h", "id.c", "id.h",
    "impcnvtab.c",
    //"gluestub.c"
];

// "aav.c", "aav.h", "array.c", "async.c", "async.h", "man.c", "response.c",
// "speller.c", "speller.h", "thread.h", "stringtable.h", "stringtable.c"

auto rootsrc = [
    "filename.h", "filename.c",
    "file.h", "file.c",
    "speller.h", "speller.c",
];

void main(string[] args)
{
    Module[] asts;

    writeln("-- ");
    writeln("-- first pass");
    writeln("-- ");

    auto scan = new Scanner();
    foreach(fn; chain(rootsrc.map!(b => buildPath(args[1], "root", b))(), frontsrc.map!(b => buildPath(args[1], b))()))
    {
        writeln("-- ", fn);
        assert(fn.exists(), fn ~ " does not exist");
        auto pp = cast(string)read(fn);
        pp = pp.replace("\"v\"\n#include \"verstr.h\"\n    ;", "__IMPORT__;");
        asts ~= parse(Lexer(pp, fn), fn);
        asts[$-1].visit(scan);
    }
    writeln("-- ");
    writeln("-- second pass");
    writeln("-- ");
    
    auto superast = collapse(asts, scan);
    
    //auto g = File("port\\dmd.ast", "wb");
    //superast.visit(new AstPrinter(g));

    auto f = File(buildPath("port", "dmd.d"), "wb");
    f.writeln("\nimport defs;\n");
    superast.visit(new DPrinter((string s) { f.write(s); }, scan));
}
