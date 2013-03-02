
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
import preprocess;

// "complex_t.h", "intrange.h", "intrange.c", "toelfdebug.c", "libelf.c", "libmach.c", "idgen.c", "libmscoff.c", "scanmscoff.c",
// "iasm.c",
// "eh.c",
// "tocsym.c", "s2ir.c", "todt.c", "e2ir.c", "toobj.c", "glue.c", "toctype.c", "msc.c", "typinf.c", "tocvdebug.c", "irstate.c", "irstate.h", "toir.h", "toir.c",

auto frontsrc = [
    "mars.c", "enum.c", "struct.c", "dsymbol.c", "import.c", "utf.h",
    "utf.c", "entity.c", "identifier.c", "mtype.c", "expression.c", "optimize.c", "template.h",
    "template.c", "lexer.c", "declaration.c", "cast.c", "cond.h", "cond.c", "link.c",
    "aggregate.h", "staticassert.h", "parse.c", "statement.c", "constfold.c", "version.h",
    "version.c", "inifile.c", "staticassert.c", "module.c", "scope.c", "dump.c",
    "init.h", "init.c", "attrib.h", "attrib.c", "opover.c", "class.c",
    "mangle.c", "func.c", "inline.c", "access.c",
    "tk.c",
    "cppmangle.c", "identifier.h", "parse.h", "scope.h", "enum.h", "import.h",
    "mars.h", "module.h", "mtype.h", "dsymbol.h",
    "declaration.h", "lexer.h", "expression.h", "statement.h", "doc.h", "doc.c", "macro.h",
    "macro.c", "hdrgen.h", "hdrgen.c", "arraytypes.h", "delegatize.c",
    "interpret.c", "ctfeexpr.c", "traits.c", "builtin.c", "clone.c", "lib.h", "libomf.c",
    "arrayop.c", "aliasthis.h", "aliasthis.c", "json.h", "json.c",
    "unittests.c", "imphint.c", "argtypes.c", "apply.c", "sideeffect.c",
    "ctfe.h", "canthrow.c", "target.c", "target.h", "id.c", "id.h"
];

auto backsrc = [
    "cdef.h", "cc.h", "oper.h", "ty.h", "optabgen.c", "global.h", "code.h", "code_x86.h",
    "code_stub.h", "platform_stub.c", "type.h", "dt.h", "cgcv.h", "el.h", "iasm.h", "rtlsym.h",
    "bcomplex.c", "blockopt.c", "cg.c", "cg87.c", "cgxmm.c", "cgcod.c", "cgcs.c", "cgcv.c",
    "cgelem.c", "cgen.c", "cgobj.c", "cgreg.c", "var.c", "cgsched.c", "cod1.c", "cod2.c",
    "cod3.c", "cod4.c", "cod5.c", "code.c", "symbol.c", "debug.c", "dt.c", "ee.c", "el.c",
    "evalu8.c", "go.c", "gflow.c", "gdag.c", "gother.c", "glocal.c", "gloop.c", "newman.c",
    "nteh.c", "os.c", "out.c", "outbuf.c", "ptrntab.c", "rtlsym.c", "type.c", "melf.h",
    "mach.h", "mscoff.h", "bcomplex.h", "cdeflnx.h", "outbuf.h", "token.h", "tassert.h",
    "elfobj.c", "cv4.h", "dwarf2.h", "exh.h", "go.h", "dwarf.c", "dwarf.h", "cppman.c",
    "machobj.c", "strtold.c", "aa.h", "aa.c", "tinfo.h", "ti_achar.c", "md5.h", "md5.c",
    "ti_pvoid.c", "xmm.h", "ph2.c", "util2.c", "mscoffobj.c", "obj.h", "pdata.c", "cv8.c",
    "backconfig.c"
];

enum frontpath = r"..\dmdgit\src\";
enum backpath = frontpath ~ r"backend\";

void main()
{
    Module[] asts;
    
    writeln("-- ");
    writeln("-- first pass");
    writeln("-- ");

    auto scan = new Scanner();
    foreach(fn; frontsrc.map!(b => frontpath ~ b)())
    {
        writeln("-- ", fn);
        assert(fn.exists(), fn);
        auto pp = cast(string)read(fn);
        pp = preprocess.preprocess(Lexer(pp, fn), fn);
        std.file.write("pre.txt", pp);
        asts ~= parse(Lexer(pp, fn), fn);
        asts[$-1].visit(scan);
    }
    writeln("-- ");
    writeln("-- second pass");
    writeln("-- ");
    
    auto superast = collapse(asts, scan);
    
    auto f = File("port\\dmd.d", "w");
    f.writeln("\nimport defs;\n");
    superast.visit(new DPrinter((string s) { f.write(s); }, scan));
}
