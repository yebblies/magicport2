
import std.file;
import std.stdio;
import std.range;
import std.path;

import tokens;
import parser;
import printercpp;
import dprinter;
import printerast;
import scanner;
import ast;

//r"dmd\src\intrange.c", 
auto csrc = [
    /**/
    r"dmd\src\access.c", r"dmd\src\aliasthis.c", r"dmd\src\apply.c", r"dmd\src\argtypes.c",
    r"dmd\src\arrayop.c", r"dmd\src\attrib.c", r"dmd\src\builtin.c", r"dmd\src\canthrow.c",
    r"dmd\src\cast.c", r"dmd\src\class.c", r"dmd\src\clone.c", r"dmd\src\cond.c", r"dmd\src\constfold.c",
    r"dmd\src\cppmangle.c", r"dmd\src\declaration.c", r"dmd\src\delegatize.c", r"dmd\src\doc.c",
    r"dmd\src\dsymbol.c", r"dmd\src\dump.c", r"dmd\src\e2ir.c", r"dmd\src\eh.c", r"dmd\src\entity.c",
    r"dmd\src\enum.c", r"dmd\src\expression.c", r"dmd\src\func.c", r"dmd\src\glue.c", r"dmd\src\hdrgen.c",
    r"dmd\src\iasm.c", r"dmd\src\identifier.c",
    r"dmd\src\imphint.c", r"dmd\src\import.c", r"dmd\src\inifile.c", r"dmd\src\init.c", r"dmd\src\inline.c",
    r"dmd\src\interpret.c", r"dmd\src\irstate.c", r"dmd\src\json.c", r"dmd\src\lexer.c",
    r"dmd\src\libomf.c", r"dmd\src\link.c", r"dmd\src\macro.c",
    r"dmd\src\mangle.c", r"dmd\src\mars.c", r"dmd\src\module.c", r"dmd\src\msc.c", r"dmd\src\mtype.c",
    r"dmd\src\opover.c", r"dmd\src\optimize.c", r"dmd\src\parse.c", r"dmd\src\ph.c", r"dmd\src\s2ir.c",
    r"dmd\src\scope.c", r"dmd\src\sideeffect.c", r"dmd\src\statement.c", r"dmd\src\staticassert.c",
    r"dmd\src\struct.c", r"dmd\src\template.c", r"dmd\src\tk.c", r"dmd\src\tocsym.c", r"dmd\src\toctype.c",
    r"dmd\src\tocvdebug.c", r"dmd\src\todt.c", r"dmd\src\toir.c", r"dmd\src\toobj.c",
    r"dmd\src\traits.c", r"dmd\src\typinf.c", r"dmd\src\unialpha.c", r"dmd\src\utf.c",
    r"dmd\src\util.c", r"dmd\src\version.c",
    r"dmd\src\aggregate.h", r"dmd\src\aliasthis.h", r"dmd\src\arraytypes.h", r"dmd\src\attrib.h",
    r"dmd\src\cond.h", r"dmd\src\declaration.h", r"dmd\src\doc.h", r"dmd\src\dsymbol.h",
    r"dmd\src\enum.h", r"dmd\src\expression.h", r"dmd\src\hdrgen.h", r"dmd\src\id.h", r"dmd\src\identifier.h",
    r"dmd\src\import.h", r"dmd\src\init.h", r"dmd\src\irstate.h", r"dmd\src\json.h",
    r"dmd\src\lexer.h", r"dmd\src\lib.h", r"dmd\src\macro.h", r"dmd\src\mars.h", r"dmd\src\module.h",
    r"dmd\src\mtype.h", r"dmd\src\objfile.h", r"dmd\src\parse.h", r"dmd\src\scope.h", r"dmd\src\statement.h",
    r"dmd\src\staticassert.h", r"dmd\src\template.h", r"dmd\src\toir.h", r"dmd\src\total.h", r"dmd\src\utf.h",
    r"dmd\src\version.h",
];

void main()
{
/*    auto f = File("ast.txt", "w");
    foreach(fn; chain(csrc, hsrc))
    {
        writeln("-- ", fn);
        auto ast = parse(Lexer(readText(fn), fn));
        ast.visit(new AstPrinter(f));
    }*/
/*    foreach(fn; chain(csrc, hsrc))
    {
        writeln("-- ", fn);
        auto ast = parse(Lexer(readText(fn), fn));
        
        auto f = File("port\\" ~ ast.file, "w");
        ast.visit(new CppPrinter(f));
        f.close();
    }*/
/*    foreach(fn; chain(csrc, hsrc))
    {
        writeln("-- ", fn);
        auto ast = parse(Lexer(readText("port\\" ~ fn), fn));
        
        auto f = File("port2\\" ~ ast.file, "w");
        ast.visit(new CppPrinter(f));
        f.close();
    }*/
    
    Module[] asts;
    
    writeln("-- ");
    writeln("-- first pass");
    writeln("-- ");

    auto scan = new Scanner();
    foreach(fn; csrc)
    {
        writeln("-- ", fn);
        asts ~= parse(Lexer(readText(fn), fn));
        asts[$-1].visit(scan);
    }
    writeln("-- ");
    writeln("-- second pass");
    writeln("-- ");
    
    auto superast = collapse(asts, scan);
    
    auto f = File("port\\dmd.d", "w");
    f.writeln(r"
import defs;
    ");
    superast.visit(new DPrinter((string s) { f.write(s); }, scan));
}