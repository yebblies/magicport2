
import std.file;
import std.stdio;
import std.range;
import std.path;
import std.algorithm;

import tokens;
import parser;
import dprinter;
import scanner;
import ast;
import namer;

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
    "impcnvtab.c", "visitor.h"
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
    auto map = buildMap(superast);
    auto longmap = buildLongMap(superast);
    auto list = getList();

    try { mkdir("port"); } catch {}
    foreach(m, decls; list)
    {
        auto dir = buildPath("port", m.p);
        if (m.p)
            try { mkdir(dir); } catch {}

        auto f = File(buildPath(dir, m.m).setExtension(".d"), "wb");
        f.writeln();
        if (m.p)
            f.writefln("module %s.%s;", m.p, m.m);
        else
            f.writefln("module %s;", m.m);
        f.writeln();

        foreach(i; m.imports)
        {
            f.writefln("import %s;", i);
        }
        f.writeln();

        auto printer = new DPrinter((string s) { f.write(s); }, scan);
        foreach(d; decls)
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
            }
        }
    }
    foreach(id, d; map)
    {
        if (d.count == 0)
        {
            assert(d.d);
            writeln("unreferenced: ", d.d.getName);
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
    foreach(fn; ["intrange.d", "complex.d", "longdouble.d"])
        std.file.write(buildPath("port", fn), buildPath("manual", fn).read());
    foreach(fn; ["aav.d", "array.d", "man.d", "rootobject.d", "outbuffer.d", "port.d", "response.d", "rmem.d", "stringtable.d"])
        std.file.write(buildPath("port", "root", fn), buildPath("manual", "root", fn).read());
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
}

auto getList()
{
    return
    [
        M("filename", "root", ["root.rootobject", "root.array", "root.file", "defs", "root.rmem", "root.outbuffer"]) :
        [
            "typedef Strings",
            "typedef Files",
            "struct FileName",
        ],
        M("file", "root", ["root.filename", "root.array", "defs", "root.rmem"]) :
        [
            "struct File",
        ],
        M("speller", "root", ["defs"]) :
        [
            "typedef fp_speller_t",
            "variable idchars",
            "function spellerY",
            "function spellerX",
            "function speller",
            "version speller.c:265",
        ],

        M("arraytypes", null, ["root.array", "root.file", "identifier", "dtemplate", "expression", "statement", "dclass", "root.rootobject",
                               "mtype", "dsymbol", "aggregate", "mars", "declaration", "init", "func", "defs", "dmodule"]) :
        [
            "typedef Strings",
            "typedef Identifiers",
            "typedef TemplateParameters",
            "typedef Expressions",
            "typedef Statements",
            "typedef BaseClasses",
            "typedef ClassDeclarations",
            "typedef Dsymbols",
            "typedef Objects",
            "typedef FuncDeclarations",
            "typedef Parameters",
            "typedef Initializers",
            "typedef VarDeclarations",
            "typedef Types",
            "typedef ScopeDsymbols",
            "typedef Catches",
            "typedef StaticDtorDeclarations",
            "typedef SharedStaticDtorDeclarations",
            "typedef AliasDeclarations",
            "typedef Modules",
            "typedef CaseStatements",
            "typedef ScopeStatements",
            "typedef GotoCaseStatements",
            "typedef GotoStatements",
            "typedef ReturnStatements",
            "typedef TemplateInstances",
            "typedef Blocks",
            "typedef Symbols",
            "typedef Dts",
       ],
        M("mars", null, ["arraytypes", "defs", "dmodule", "root.outbuffer", "root.file", "dscope", "root.rmem", "root.filename",
                         "identifier", "id", "parse", "lexer", "dunittest", "root.response", "cond", "dinifile", "root.man",
                         "mtype", "target", "expression", "interpret", "lib", "json", "link"]) :
        [
            "function toWinPath",
            "variable global",
            "function errorLocchar*??",
            "function errorchar*unsignedchar*??",
            "function warning",
            "function errorSupplemental",
            "function deprecation",
            "function verrorPrint",
            "externc mars.c:286",
            "function verrorSupplemental",
            "function vwarning",
            "function vdeprecation",
            "function readFile",
            "function writeFile",
            "function ensurePathToNameExists",
            "function fatal",
            "function halt",
            "function usage",
            "variable entrypoint",
            "function genCmain",
            "function tryMain",
            "function main",
            "function getenv_setargv",
            "function escapePath",
            "function parse_arch",
            "function Dsymbols__factory",
            "function Parameters__factory",
            "function Symbols__factory",
            "function VarDeclarations__factory",
            "function Blocks__factory",
            "function Expressions__factory",
            "version mars.h:77",
            "version mars.h:80",
            "variable DMDV1",
            "variable DMDV2",
            "variable SNAN_DEFAULT_INIT",
            "variable MODULEINFO_IS_STRUCT",
            "variable PULL93",
            "variable CPP_MANGLE",
            "version mars.h:105",
            "version mars.h:111",
            "version mars.h:118",
            "struct Param",
            "struct Compiler",
            "typedef structalign_t",
            "variable STRUCTALIGN_DEFAULT",
            "struct Ungag",
            "struct Global",
            "typedef dinteger_t",
            "typedef sinteger_t",
            "typedef uinteger_t",
            "typedef d_int8",
            "typedef d_uns8",
            "typedef d_int16",
            "typedef d_uns16",
            "typedef d_int32",
            "typedef d_uns32",
            "typedef d_int64",
            "typedef d_uns64",
            "typedef d_float32",
            "typedef d_float64",
            "typedef d_float80",
            "typedef d_char",
            "typedef d_wchar",
            "typedef d_dchar",
            "typedef real_t",
            "struct Loc",
            "variable INTERFACE_OFFSET",
            "variable INTERFACE_VIRTUAL",
            "enum LINK",
            "enum DYNCAST",
            "enum MATCH",
            "typedef StorageClass",
            "externc mars.h:411",
            "version mars.h:426",
        ],
        M("dstruct", null, ["dsymbol", "func", "aggregate", "arraytypes", "mars", "mtype", "identifier", "dscope",
                            "root.outbuffer", "hdrgen", "visitor", "defs", "dtemplate", "dmodule", "opover", "id",
                            "declaration", "expression", "lexer", "init", "clone", "statement", "doc"]) :
        [
            "function inNonRoot",
            "function search_toHash",
            "function search_toString",
            "struct StructFlags",
            "struct StructDeclaration",
            "struct UnionDeclaration",
        ],
        M("dsymbol", null, ["root.rootobject", "identifier", "defs", "mars", "dscope", "arraytypes", "declaration",
                            "dmodule", "dtemplate", "root.outbuffer", "hdrgen", "aggregate", "statement", "mtype",
                            "denum", "dimport", "attrib", "visitor", "func", "dclass", "dstruct", "expression",
                            "root.aav", "root.stringtable", "lexer", "id", "root.rmem", "opover", "root.speller",
                            "doc", "aliasthis", "init", "declaration"]) :
        [
            "variable Pprotectionnames",
            "function symbol_search_fp",
            "function dimDgvoid*size_tDsymbol*",
            "struct GetNthSymbolCtx",
            "function getNthSymbolDg",
            "version dsymbol.h:82",
            "enum PROT",
            "enum PASS",
            "typedef Dsymbol_apply_ft_t",
            "struct Dsymbol",
            "struct ScopeDsymbol",
            "struct WithScopeSymbol",
            "struct ArrayScopeSymbol",
            "struct OverloadSet",
            "struct DsymbolTable",
        ],
        M("utf", null, ["defs"]) :
        [
            "typedef utf8_t",
            "typedef utf16_t",
            "typedef utf32_t",
            "typedef dchar_t",
            "variable ALPHA_TABLE",
            "variable UTF8_DECODE_OK",
            "variable UTF16_DECODE_OK",
            "variable UTF8_STRIDE",
            "variable UTF8_DECODE_OUTSIDE_CODE_SPACE",
            "variable UTF8_DECODE_TRUNCATED_SEQUENCE",
            "variable UTF8_DECODE_OVERLONG",
            "variable UTF8_DECODE_INVALID_TRAILER",
            "variable UTF8_DECODE_INVALID_CODE_POINT",
            "variable UTF16_DECODE_TRUNCATED_SEQUENCE",
            "variable UTF16_DECODE_INVALID_SURROGATE",
            "variable UTF16_DECODE_UNPAIRED_SURROGATE",
            "variable UTF16_DECODE_INVALID_CODE_POINT",
            "function utf_isValidDchar",
            "function isUniAlpha",
            "function utf_codeLengthChar",
            "function utf_codeLengthWchar",
            "function utf_codeLength",
            "function utf_encodeChar",
            "function utf_encodeWchar",
            "function utf_encode",
            "function utf_decodeChar",
            "function utf_decodeWchar",
        ],
        M("entity", null, ["defs"]) :
        [
            "struct NameId",
            "variable namesA",
            "variable namesB",
            "variable namesC",
            "variable namesD",
            "variable namesE",
            "variable namesF",
            "variable namesG",
            "variable namesH",
            "variable namesI",
            "variable namesJ",
            "variable namesK",
            "variable namesL",
            "variable namesM",
            "variable namesN",
            "variable namesO",
            "variable namesP",
            "variable namesQ",
            "variable namesR",
            "variable namesS",
            "variable namesT",
            "variable namesU",
            "variable namesV",
            "variable namesW",
            "variable namesX",
            "variable namesY",
            "variable namesZ",
            "variable namesTable",
            "function HtmlNamedEntity",
        ],
        M("mtype", null, ["defs", "root.outbuffer", "expression", "dscope", "declaration", "root.rootobject", "dclass",
                          "hdrgen", "aggregate", "dtemplate", "root.stringtable", "mars", "identifier", "dsymbol", "arraytypes",
                          "visitor", "denum", "dstruct", "lexer", "root.rmem", "opover", "func", "id", "aliasthis", "init",
                          "target", "root.port", "complex", "ctfeexpr", "longdouble", "dimport", "argtypes", "imphint",
                          "access", "attrib"]) :
        [
            "version mtype.c:25",
            "variable LOGDOTEXP",
            "variable LOGDEFAULTINIT",
            "variable IMPLICIT_ARRAY_TO_PTR",
            "variable Tsize_t",
            "variable Tptrdiff_t",
            "function MODimplicitConv",
            "function MODmethodConv",
            "function MODmerge",
            "function MODtoDecoBuffer",
            "function MODtoBuffer",
            "function MODtoChars",
            "function stripDefaultArgs",
            "variable TFLAGSintegral",
            "variable TFLAGSfloating",
            "variable TFLAGSunsigned",
            "variable TFLAGSreal",
            "variable TFLAGSimaginary",
            "variable TFLAGScomplex",
            "variable TFLAGSvector",
            "function semanticLengthScope*TupleDeclaration*Expression*",
            "function semanticLengthScope*Type*Expression*",
            "function functionToCBuffer2",
            "version mtype.c:9447",
            "function argsToDecoBufferDg",
            "function isTPLDg",
            "function dimDgvoid*size_tParameter*",
            "struct GetNthParamCtx",
            "function getNthParamDg",
            "version mtype.h:49",
            "enum ENUMTY",
            "typedef TY",
            "variable MODconst",
            "variable MODimmutable",
            "variable MODshared",
            "variable MODwild",
            "variable MODwildconst",
            "variable MODmutable",
            "struct Type",
            "struct TypeError",
            "struct TypeNext",
            "struct TypeBasic",
            "struct TypeVector",
            "struct TypeArray",
            "struct TypeSArray",
            "struct TypeDArray",
            "struct TypeAArray",
            "struct TypePointer",
            "struct TypeReference",
            "enum RET",
            "enum TRUST",
            "enum PURE",
            "struct TypeFunction",
            "struct TypeDelegate",
            "struct TypeQualified",
            "struct TypeIdentifier",
            "struct TypeInstance",
            "struct TypeTypeof",
            "struct TypeReturn",
            "enum AliasThisRec",
            "struct TypeStruct",
            "struct TypeEnum",
            "struct TypeTypedef",
            "struct TypeClass",
            "struct TypeTuple",
            "struct TypeSlice",
            "struct TypeNull",
            "struct Parameter",
        ],
        M("expression", null, ["mars", "dscope", "aggregate", "declaration", "func", "identifier", "arraytypes", "root.rootobject",
                               "lexer", "mtype", "complex", "root.outbuffer", "hdrgen", "intrange", "dsymbol", "interpret", "inline",
                               "visitor", "dtemplate", "parse", "dstruct", "defs", "dclass", "id", "init", "declaration", "target",
                               "root.port", "longdouble", "root.rmem", "dump", "aliasthis", "opover", "delegatize", "canthrow",
                               "doc", "imphint", "denum", "dimport", "statement", "sideeffect", "dmodule", "utf", "apply", "ctfeexpr",
                               "optimize", "attrib", "traits", "root.aav", "constfold", "dcast", "arrayop", "root.filename", "root.file",
                               "access"]) :
        [
            "function getRightThis",
            "function hasThis",
            "function isNeedThisScope",
            "function checkRightThis",
            "function resolvePropertiesX",
            "function resolveProperties",
            "function checkPropertyCall",
            "function resolvePropertiesOnly",
            "function searchUFCS",
            "function isDotOpDispatch",
            "function resolveUFCS",
            "function resolveUFCSProperties",
            "function arrayExpressionSemantic",
            "function arrayExpressionCanThrow",
            "function expandTuples",
            "function isAliasThisTuple",
            "function expandAliasThisTuples",
            "function arrayExpressionToCommonType",
            "function getFuncTemplateDecl",
            "function preFunctionParameters",
            "function valueNoDtor",
            "function checkDefCtor",
            "function callCpCtor",
            "function functionParameters",
            "function expToCBuffer",
            "function sizeToCBuffer",
            "function argsToCBuffer",
            "function argExpTypesToCBuffer",
            "variable EXP_CANT_INTERPRET",
            "variable EXP_CONTINUE_INTERPRET",
            "variable EXP_BREAK_INTERPRET",
            "variable EXP_GOTO_INTERPRET",
            "variable EXP_VOID_INTERPRET",
            "function RealEquals",
            "function floatToBuffer",
            "function realToMangleBuffer",
            "function typeDotIdExp",
            "function modifyFieldVar",
            "function opAssignToOp",
            "function needDirectEq",
            "function extractOpDollarSideEffect",
            "function resolveOpDollarScope*ArrayExp*",
            "function resolveOpDollarScope*SliceExp*",
            "version expression.h:66",
            "typedef apply_fp_t",
            "enum CtfeGoal",
            "variable WANTflags",
            "variable WANTvalue",
            "variable WANTexpand",
            "struct Expression",
            "struct IntegerExp",
            "struct ErrorExp",
            "struct RealExp",
            "struct ComplexExp",
            "struct IdentifierExp",
            "struct DollarExp",
            "struct DsymbolExp",
            "struct ThisExp",
            "struct SuperExp",
            "struct NullExp",
            "struct StringExp",
            "struct TupleExp",
            "struct ArrayLiteralExp",
            "struct AssocArrayLiteralExp",
            "variable stageScrub",
            "variable stageSearchPointers",
            "variable stageOptimize",
            "variable stageApply",
            "variable stageInlineScan",
            "variable stageToCBuffer",
            "struct StructLiteralExp",
            "struct TypeExp",
            "struct ScopeExp",
            "struct TemplateExp",
            "struct NewExp",
            "struct NewAnonClassExp",
            "struct SymbolExp",
            "struct SymOffExp",
            "struct VarExp",
            "struct OverExp",
            "struct FuncExp",
            "struct DeclarationExp",
            "struct TypeidExp",
            "struct TraitsExp",
            "struct HaltExp",
            "struct IsExp",
            "struct UnaExp",
            "typedef fp_t",
            "typedef fp2_t",
            "struct BinExp",
            "struct BinAssignExp",
            "struct CompileExp",
            "struct FileExp",
            "struct AssertExp",
            "struct DotIdExp",
            "struct DotTemplateExp",
            "struct DotVarExp",
            "struct DotTemplateInstanceExp",
            "struct DelegateExp",
            "struct DotTypeExp",
            "struct CallExp",
            "struct AddrExp",
            "struct PtrExp",
            "struct NegExp",
            "struct UAddExp",
            "struct ComExp",
            "struct NotExp",
            "struct BoolExp",
            "struct DeleteExp",
            "struct CastExp",
            "struct VectorExp",
            "struct SliceExp",
            "struct ArrayLengthExp",
            "struct ArrayExp",
            "struct DotExp",
            "struct CommaExp",
            "struct IndexExp",
            "struct PostExp",
            "struct PreExp",
            "struct AssignExp",
            "struct ConstructExp",
            "struct AddAssignExp",
            "struct MinAssignExp",
            "struct MulAssignExp",
            "struct DivAssignExp",
            "struct ModAssignExp",
            "struct AndAssignExp",
            "struct OrAssignExp",
            "struct XorAssignExp",
            "struct PowAssignExp",
            "struct ShlAssignExp",
            "struct ShrAssignExp",
            "struct UshrAssignExp",
            "struct CatAssignExp",
            "struct AddExp",
            "struct MinExp",
            "struct CatExp",
            "struct MulExp",
            "struct DivExp",
            "struct ModExp",
            "struct PowExp",
            "struct ShlExp",
            "struct ShrExp",
            "struct UshrExp",
            "struct AndExp",
            "struct OrExp",
            "struct XorExp",
            "struct OrOrExp",
            "struct AndAndExp",
            "struct CmpExp",
            "struct InExp",
            "struct RemoveExp",
            "struct EqualExp",
            "struct IdentityExp",
            "struct CondExp",
            "struct DefaultInitExp",
            "struct FileInitExp",
            "struct LineInitExp",
            "struct ModuleInitExp",
            "struct FuncInitExp",
            "struct PrettyFuncInitExp",
        ],
        M("optimize", null, ["expression", "declaration", "mtype", "defs", "lexer", "mars", "init"]) :
        [
            "function expandVar",
            "function fromConstInitializer",
            "function shift_optimize",
            "function setLengthVarIfKnown",
        ],
        M("dtemplate", null, ["root.rootobject", "arraytypes", "dsymbol", "expression", "root.array", "func", "dscope", "mars",
                              "identifier", "root.outbuffer", "hdrgen", "mtype", "visitor", "declaration", "root.aav",
                              "dmodule", "defs", "aggregate", "dclass", "id", "lexer", "doc", "opover", "aliasthis", "init",
                              "attrib"]) :
        [
            "version template.h:49",
            "struct Tuple",
            "struct TemplateDeclaration",
            "struct TemplateParameter",
            "struct TemplateTypeParameter",
            "struct TemplateThisParameter",
            "struct TemplateValueParameter",
            "struct TemplateAliasParameter",
            "struct TemplateTupleParameter",
            "struct TemplateInstance",
            "struct TemplateMixin",
            "variable IDX_NOTFOUND",
            "function isExpression",
            "function isDsymbol",
            "function isType",
            "function isTuple",
            "function isParameter",
            "function isError",
            "function arrayObjectIsError",
            "function getType",
            "function getDsymbol",
            "function getValueDsymbol*&",
            "function getValueExpression*",
            "function match",
            "function arrayObjectMatch",
            "function arrayObjectHash",
            "function ObjectToCBuffer",
            "function objectSyntaxCopy",
            "function isVariadic",
            "function functionResolve",
            "function templateIdentifierLookup",
            "function templateParameterLookup",
            "function deduceBaseClassParameters",
            "function aliasParameterSemantic",
            "function isPseudoDsymbol",
            "function definitelyValueParameter",
        ],
        M("lexer", null, ["mars", "identifier", "root.stringtable", "root.outbuffer", "dmodule", "defs", "longdouble",
                          "utf", "root.rmem", "id", "entity", "root.port"]) :
        [
            "variable LS",
            "variable PS",
            "variable cmtable",
            "variable CMoctal",
            "variable CMhex",
            "variable CMidchar",
            "function isoctal",
            "function ishex",
            "function isidchar",
            "function cmtable_init",
            "struct Keyword",
            "variable keywords",
            "version lexer.c:2944",
            "enum TOK",
            "variable TOKwild",
            "struct Token",
            "struct Lexer",
        ],
        M("declaration", null, ["mars", "dscope", "aggregate", "identifier", "declaration", "dsymbol", "mtype", "expression",
                                "root.outbuffer", "visitor", "arraytypes", "init", "hdrgen", "defs", "statement", "interpret",
                                "root.rootobject", "dtemplate", "inline", "lexer", "func", "dclass", "dstruct", "opover", "id",
                                "doc", "dmangle", "ctfeexpr", "attrib", "target"]) :
        [
            "function checkFrameAccess",
            "function ObjectNotFound",
            "variable DUMP",
            "variable STCundefined",
            "variable STCstatic",
            "variable STCextern",
            "variable STCconst",
            "variable STCfinal",
            "variable STCabstract",
            "variable STCparameter",
            "variable STCfield",
            "variable STCoverride",
            "variable STCauto",
            "variable STCsynchronized",
            "variable STCdeprecated",
            "variable STCin",
            "variable STCout",
            "variable STClazy",
            "variable STCforeach",
            "variable STCcomdat",
            "variable STCvariadic",
            "variable STCctorinit",
            "variable STCtemplateparameter",
            "variable STCscope",
            "variable STCimmutable",
            "variable STCref",
            "variable STCinit",
            "variable STCmanifest",
            "variable STCnodtor",
            "variable STCnothrow",
            "variable STCpure",
            "variable STCtls",
            "variable STCalias",
            "variable STCshared",
            "variable STCgshared",
            "variable STCwild",
            "variable STC_TYPECTOR",
            "variable STC_FUNCATTR",
            "variable STCproperty",
            "variable STCsafe",
            "variable STCtrusted",
            "variable STCsystem",
            "variable STCctfe",
            "variable STCdisable",
            "variable STCresult",
            "variable STCnodefaultctor",
            "variable STCtemp",
            "variable STCrvalue",
            "variable STCStorageClass",
            "struct Match",
            "enum Semantic",
            "struct Declaration",
            "struct TupleDeclaration",
            "struct TypedefDeclaration",
            "struct AliasDeclaration",
            "struct VarDeclaration",
            "struct SymbolDeclaration",
            "struct ClassInfoDeclaration",
            "struct TypeInfoDeclaration",
            "struct TypeInfoStructDeclaration",
            "struct TypeInfoClassDeclaration",
            "struct TypeInfoInterfaceDeclaration",
            "struct TypeInfoTypedefDeclaration",
            "struct TypeInfoPointerDeclaration",
            "struct TypeInfoArrayDeclaration",
            "struct TypeInfoStaticArrayDeclaration",
            "struct TypeInfoAssociativeArrayDeclaration",
            "struct TypeInfoEnumDeclaration",
            "struct TypeInfoFunctionDeclaration",
            "struct TypeInfoDelegateDeclaration",
            "struct TypeInfoTupleDeclaration",
            "struct TypeInfoConstDeclaration",
            "struct TypeInfoInvariantDeclaration",
            "struct TypeInfoSharedDeclaration",
            "struct TypeInfoWildDeclaration",
            "struct TypeInfoVectorDeclaration",
            "struct ThisDeclaration",
        ],
        M("dcast", null, ["expression", "mtype", "dscope", "mars", "intrange", "defs", "lexer", "dclass", "aliasthis", "root.rootobject", "root.rmem"]) :
        [
            "function isVoidArrayLiteral",
            "function typeMerge",
            "function arrayTypeCompatible",
            "function arrayTypeCompatibleWithoutCasting",
            "function getMask",
            "function unsignedBitwiseAnd",
            "function unsignedBitwiseOr",
            "function unsignedBitwiseXor",
        ],
        M("cond", null, ["mars", "identifier", "dmodule", "dscope", "dsymbol", "root.outbuffer", "hdrgen", "dmodule",
                         "expression", "arraytypes", "defs", "lexer", "mtype"]) :
        [
            "struct Condition",
            "struct DVCondition",
            "struct DebugCondition",
            "struct VersionCondition",
            "struct StaticIfCondition",
            "function findCondition",
            "function printDepsConditional",
        ],
        M("link", null, ["defs", "root.outbuffer", "mars", "root.filename", "root.file", "root.rmem"]) :
        [
            "version link.c:41",
            "function writeFilenameOutBuffer*char*size_t",
            "function writeFilenameOutBuffer*char*",
            "version link.c:143",
            "function runLINK",
            "function deleteExeFile",
            "version link.c:794",
            "version link.c:819",
            "function runProgram",
        ],
        M("aggregate", null, ["dsymbol", "mtype", "arraytypes", "declaration", "func", "mars", "expression", "identifier", "dscope",
                              "root.outbuffer", "visitor", "hdrgen", "defs", "dstruct", "dtemplate", "clone", "id", "lexer",
                              "statement", "doc", "opover", "access"]) :
        [
            "enum Sizeok",
            "struct AggregateDeclaration",
        ],
        M("staticassert", null, ["dsymbol", "expression", "mars", "dscope", "identifier", "root.outbuffer", "hdrgen", "visitor",
                                 "defs", "id", "mtype"]) :
        [
            "struct StaticAssert",
        ],
        M("parse", null, ["lexer", "dmodule", "mars", "arraytypes", "dsymbol", "expression", "dtemplate", "staticassert", "mtype",
                          "cond", "func", "denum", "dimport", "identifier", "statement", "init", "defs", "root.rmem", "declaration",
                          "attrib", "dversion", "id", "root.rootobject", "dtemplate", "dclass", "aliasthis", "aggregate", "dstruct"]) :
        [
            "variable CDECLSYNTAX",
            "variable CCASTSYNTAX",
            "variable CARRAYDECL",
            "variable D1INOUT",
            "variable precedence",
            "function initPrecedence",
            "enum ParseStatementFlags",
            "struct Parser",
            "enum PREC",
        ],
        M("statement", null, ["identifier", "dscope", "root.rootobject", "mars", "root.outbuffer", "hdrgen", "arraytypes", "expression",
                              "interpret", "inline", "visitor", "dsymbol", "declaration", "lexer", "func", "mtype", "cond", "staticassert",
                              "defs", "parse", "sapply", "attrib", "init", "ctfeexpr", "intrange", "id", "aggregate", "target", "opover",
                              "dtemplate", "denum", "dclass", "dimport", "mtype"]) :
        [
            "function fixupLabelName",
            "function checkLabeledLoop",
            "typedef sapply_fp_t",
            "version statement.h:70",
            "enum BE",
            "struct Statement",
            "struct ErrorStatement",
            "struct PeelStatement",
            "struct ExpStatement",
            "struct DtorExpStatement",
            "struct CompileStatement",
            "struct CompoundStatement",
            "struct CompoundDeclarationStatement",
            "struct UnrolledLoopStatement",
            "struct ScopeStatement",
            "struct WhileStatement",
            "struct DoStatement",
            "struct ForStatement",
            "struct ForeachStatement",
            "struct ForeachRangeStatement",
            "struct IfStatement",
            "struct ConditionalStatement",
            "struct PragmaStatement",
            "struct StaticAssertStatement",
            "struct SwitchStatement",
            "struct CaseStatement",
            "struct CaseRangeStatement",
            "struct DefaultStatement",
            "struct GotoDefaultStatement",
            "struct GotoCaseStatement",
            "struct SwitchErrorStatement",
            "struct ReturnStatement",
            "struct BreakStatement",
            "struct ContinueStatement",
            "struct SynchronizedStatement",
            "struct WithStatement",
            "struct TryCatchStatement",
            "struct Catch",
            "struct TryFinallyStatement",
            "struct OnScopeStatement",
            "struct ThrowStatement",
            "struct DebugStatement",
            "struct GotoStatement",
            "struct LabelStatement",
            "struct LabelDsymbol",
            "struct AsmStatement",
            "struct ImportStatement",
        ],
        M("constfold", null, ["expression", "mtype", "lexer", "defs", "mars", "complex", "root.port", "longdouble", "arraytypes",
                              "dstruct", "declaration", "builtin", "root.rmem", "utf", "func"]) :
        [
            "function expType",
            "function Neg",
            "function Com",
            "function Not",
            "function Bool",
            "function Add",
            "function Min",
            "function Mul",
            "function Div",
            "function Mod",
            "function Pow",
            "function Shl",
            "function Shr",
            "function Ushr",
            "function And",
            "function Or",
            "function Xor",
            "function Equal",
            "function Identity",
            "function Cmp",
            "function Cast",
            "function ArrayLength",
            "function Index",
            "function Slice",
            "function sliceAssignArrayLiteralFromString",
            "function sliceAssignStringFromArrayLiteral",
            "function sliceAssignStringFromString",
            "function sliceCmpStringWithString",
            "function sliceCmpStringWithArray",
            "function Cat",
            "function Ptr",
        ],
        M("dversion", null, ["dsymbol", "mars", "identifier", "dscope", "root.outbuffer", "hdrgen", "visitor", "defs", "dmodule",
                             "cond", "dmodule", "arraytypes"]) :
        [
            "struct DebugSymbol",
            "struct VersionSymbol",
        ],
        M("dinifile", null, ["defs", "root.outbuffer", "root.filename", "root.file", "root.port"]) :
        [
            "function inifile",
            "function skipspace",
        ],
        M("dmodule", null, ["dsymbol", "identifier", "dscope", "mars", "visitor", "arraytypes", "aggregate", "root.file",
                            "dmacro", "doc", "root.outbuffer", "hdrgen", "defs", "root.filename", "parse", "lexer",
                            "id", "dimport", "root.rmem"]) :
        [
            "function readwordLE",
            "function readwordBE",
            "function readlongLE",
            "function readlongBE",
            "function lookForSourceFile",
            "version module.h:34",
            "enum PKG",
            "struct Package",
            "struct Module",
            "struct ModuleDeclaration",
        ],
        M("dscope", null, ["mars", "defs", "dmodule", "dsymbol", "func", "statement", "dtemplate", "declaration", "arraytypes", "doc",
                           "root.outbuffer", "identifier", "dclass", "aggregate", "mars", "mtype", "root.stringtable", "lexer",
                           "root.rmem", "id", "root.speller"]) :
        [
            "function mergeFieldInit",
            "function scope_search_fp",
            "version scope.h:40",
            "variable CSXthis_ctor",
            "variable CSXsuper_ctor",
            "variable CSXthis",
            "variable CSXsuper",
            "variable CSXlabel",
            "variable CSXreturn",
            "variable CSXany_ctor",
            "variable SCOPEctor",
            "variable SCOPEstaticif",
            "variable SCOPEfree",
            "variable SCOPEstaticassert",
            "variable SCOPEdebug",
            "variable SCOPEinvariant",
            "variable SCOPErequire",
            "variable SCOPEensure",
            "variable SCOPEcontract",
            "variable SCOPEctfe",
            "variable SCOPEnoaccesscheck",
            "variable SCOPEcompile",
            "struct Scope",
        ],
        M("dump", null, ["mtype", "expression", "arraytypes", "defs"]) :
        [
            "function indent",
            "function type_print",
            "function dumpExpressions",
        ],
        M("init", null, ["root.rootobject", "mars", "dscope", "mtype", "arraytypes", "visitor", "expression", "root.outbuffer", "hdrgen",
                         "identifier", "defs", "dstruct", "aggregate", "dsymbol", "declaration", "lexer", "func", "id", "dtemplate",
                         "statement"]) :
        [
            "enum NeedInterpret",
            "struct Initializer",
            "struct VoidInitializer",
            "struct ErrorInitializer",
            "struct StructInitializer",
            "struct ArrayInitializer",
            "struct ExpInitializer",
            "function hasNonConstPointers",
            "function arrayHasNonConstPointers",
        ],
        M("attrib", null, ["dsymbol", "arraytypes", "dscope", "mars", "identifier", "aggregate", "root.outbuffer", "hdrgen", "visitor",
                           "expression", "cond", "dtemplate", "dmodule", "dstruct", "dclass", "defs", "declaration", "func", "lexer",
                           "id", "interpret", "root.rmem", "utf", "parse"]) :
        [
            "struct AttribDeclaration",
            "struct StorageClassDeclaration",
            "struct DeprecatedDeclaration",
            "struct LinkDeclaration",
            "struct ProtDeclaration",
            "struct AlignDeclaration",
            "struct AnonDeclaration",
            "struct PragmaDeclaration",
            "struct ConditionalDeclaration",
            "struct StaticIfDeclaration",
            "struct CompileDeclaration",
            "struct UserAttributeDeclaration",
            "function setMangleOverride",
        ],
        M("opover", null, ["aggregate", "mtype", "arraytypes", "dscope", "lexer", "expression", "mars", "dsymbol", "identifier",
                           "func", "defs", "declaration", "dtemplate"]) :
        [
            "version opover.c:20",
            "function isAggregate",
            "function opToArg",
            "function build_overload",
            "function search_function",
            "function inferApplyArgTypesX",
            "function inferApplyArgTypesY",
            "version opover.c:1595",
        ],
        M("dclass", null, ["dsymbol", "mtype", "arraytypes", "aggregate", "func", "declaration", "mars", "identifier",
                           "dscope", "root.outbuffer", "hdrgen", "defs", "visitor", "root.rootobject", "root.rmem", "id",
                           "dmodule", "target", "statement", "dtemplate", "doc"]) :
        [
            "version class.c:857",
            "function isf",
            "struct BaseClass",
            "variable CLASSINFO_SIZE_64",
            "variable CLASSINFO_SIZE",
            "struct ClassFlags",
            "struct ClassDeclaration",
            "struct InterfaceDeclaration",
        ],
        M("dmangle", null, ["mars", "declaration", "defs", "root.outbuffer", "dsymbol", "func", "dtemplate", "mtype",
                            "expression"]) :
        [
            "version mangle.c:37",
            "function mangle",
        ],
        M("func", null, ["dsymbol", "root.outbuffer", "declaration", "mars", "dscope", "arraytypes", "mtype", "identifier",
                         "statement", "interpret", "defs", "aggregate", "root.rootobject", "hdrgen", "dtemplate",
                         "expression", "inline", "lexer", "visitor", "dclass", "dmodule", "dstruct", "opover",
                         "id", "root.filename", "root.rmem", "init", "target", "attrib", "ctfeexpr", "doc"]) :
        [
            "function overloadApply",
            "function MODMatchToBuffer",
            "function resolveFuncCall",
            "function getIndirection",
            "function traverseIndirections",
            "function markAsNeedingClosure",
            "function checkEscapingSiblings",
            "function unitTestId",
            "enum ILS",
            "enum BUILTIN",
            "struct FuncDeclaration",
            "struct FuncAliasDeclaration",
            "struct FuncLiteralDeclaration",
            "struct CtorDeclaration",
            "struct PostBlitDeclaration",
            "struct DtorDeclaration",
            "struct StaticCtorDeclaration",
            "struct SharedStaticCtorDeclaration",
            "struct StaticDtorDeclaration",
            "struct SharedStaticDtorDeclaration",
            "struct InvariantDeclaration",
            "struct UnitTestDeclaration",
            "struct NewDeclaration",
            "struct DeleteDeclaration",
        ],
        M("inline", null, ["func", "expression", "declaration", "arraytypes", "mars", "dsymbol", "defs", "lexer", "init"]) :
        [
            "struct InlineCostState",
            "variable COST_MAX",
            "variable STATEMENT_COST",
            "variable STATEMENT_COST_MAX",
            "function tooCostly",
            "struct ICS2",
            "function lambdaInlineCost",
            "function expressionInlineCost",
            "struct InlineDoState",
            "function arrayExpressiondoInline",
            "struct InlineScanState",
            "function arrayInlineScan",
            "function scanVar",
        ],
        M("access", null, ["dsymbol", "aggregate", "dscope", "mars", "expression", "declaration", "defs", "dclass", "dmodule", "mtype", "lexer",
                           "dstruct"]) :
        [
            "function accessCheckX",
            "function hasPackageAccess",
            "function accessCheck",
        ],
        M("cppmangle", null, ["mars"]) :
        [
            "version cppmangle.c:474",
        ],
        M("identifier", null, ["root.rootobject", "defs", "id", "mars", "root.outbuffer", "lexer"]) :
        [
            "struct Identifier",
        ],
        M("denum", null, ["dsymbol", "mtype", "expression", "mars", "identifier", "dscope", "root.outbuffer",
                          "hdrgen", "defs", "visitor", "declaration", "dmodule", "id", "lexer", "doc", "init", "declaration"]) :
        [
            "struct EnumDeclaration",
            "struct EnumMember",
        ],
        M("dimport", null, ["dsymbol", "arraytypes", "identifier", "mars", "dmodule", "dscope", "root.outbuffer", "hdrgen", "visitor",
                            "defs", "declaration", "id", "attrib", "mtype"]) :
        [
            "struct Import",
        ],
        M("doc", null, ["dscope", "dsymbol", "root.outbuffer", "root.array", "dmacro", "declaration", "dtemplate", "mtype", "defs",
                        "hdrgen", "mars", "root.rmem", "dmodule", "func", "id", "root.port", "utf", "lexer"]) :
        [
            "struct Escape",
            "struct Section",
            "struct ParamSection",
            "struct MacroSection",
            "typedef Sections",
            "struct DocComment",
            "variable ddoc_default",
            "variable ddoc_decl_s",
            "variable ddoc_decl_e",
            "variable ddoc_decl_dd_s",
            "variable ddoc_decl_dd_e",
            "function escapeDdocString",
            "function escapeStrayParenthesis",
            "function emitAnchorName",
            "function emitAnchor",
            "function getCodeIndent",
            "function emitUnittestComment",
            "function emitProtection",
            "function prefix",
            "function declarationToDocBuffer",
            "function parentToBuffer",
            "function inSameModule",
            "function prettyPrintDsymbol",
            "function cmp",
            "function icmp",
            "function isDitto",
            "function skipwhitespace",
            "function skiptoident",
            "function skippastident",
            "function skippastURL",
            "function isKeyword",
            "function isTypeFunction",
            "function isFunctionParameter",
            "function isTemplateParameter",
            "function highlightText",
            "function highlightCode",
            "function highlightCode3",
            "function highlightCode2",
            "function isIdStart",
            "function isIdTail",
            "function isIndentWS",
            "function utfStride",
        ],
        M("dmacro", null, ["root.outbuffer", "defs", "utf", "doc", "root.rmem"]) :
        [
            "struct Macro",
            "function memdup",
            "function extractArgN",
        ],
        M("hdrgen", null, ["dscope"]) :
        [
            "struct HdrGenState",
            "variable PRETTY_PRINT",
            "variable TEST_EMIT_ALL",
        ],
        M("delegatize", null, ["expression", "defs", "dscope", "lexer", "declaration", "mars"]) :
        [
            "function lambdaSetParent",
            "function lambdaCheckForNestedRef",
        ],
        M("interpret", null, ["arraytypes", "expression", "declaration", "statement", "root.array", "mars", "func",
                              "dclass", "ctfeexpr", "mtype", "lexer", "defs", "root.rootobject", "dtemplate", "dsymbol",
                              "init", "id", "constfold", "utf", "builtin"]) :
        [
            "variable LOGASSIGN",
            "variable LOGCOMPILE",
            "variable SHOWPERFORMANCE",
            "variable CTFE_RECURSION_LIMIT",
            "struct CtfeStack",
            "struct InterState",
            "variable ctfeStack",
            "function printCtfePerformanceStats",
            "struct CompiledCtfeFunction",
            "function ctfeInterpretForPragmaMsg",
            "function stopPointersEscaping",
            "function stopPointersEscapingFromArray",
            "function scrubReturnValue",
            "function isEntirelyVoid",
            "function scrubArray",
            "function isAnErrorException",
            "function chainExceptions",
            "function resolveReferences",
            "function getVarExp",
            "function recursivelyCreateArrayLiteral",
            "function findParentVar",
            "function interpretAssignToIndex",
            "function interpretAssignToSlice",
            "function isPointerCmpExp",
            "function reverseRelation",
            "function showCtfeBackTrace",
            "function interpret_length",
            "function interpret_keys",
            "function interpret_values",
            "function interpret_aaApply",
            "function returnedArrayType",
            "function foreachApplyUtf",
            "function evaluateIfBuiltin",
        ],
        M("ctfeexpr", null, ["dstruct", "declaration", "expression", "arraytypes", "mtype", "mars", "lexer", "func", "interpret",
                             "root.outbuffer", "hdrgen", "dclass", "visitor", "defs", "root.rmem", "aggregate", "constfold",
                             "id", "longdouble", "dtemplate", "root.port", "complex"]) :
        [
            "function findFieldIndexByName",
            "function exceptionOrCantInterpret",
            "function needToCopyLiteral",
            "function copyLiteralArray",
            "function copyLiteral",
            "function paintTypeOntoLiteral",
            "function resolveSlice",
            "function resolveArrayLength",
            "function createBlockDuplicatedArrayLiteral",
            "function createBlockDuplicatedStringLiteral",
            "function isAssocArray",
            "function toBuiltinAAType",
            "function isTypeInfo_Class",
            "function isPointer",
            "function isTrueBool",
            "function isSafePointerCast",
            "function getAggregateFromPointer",
            "function pointToSameMemoryBlock",
            "function pointerDifference",
            "function pointerArithmetic",
            "function comparePointers",
            "struct UnionFloatInt",
            "struct UnionDoubleLong",
            "function isFloatIntPaint",
            "function paintFloatInt",
            "function intUnary",
            "function intBinary",
            "function isCtfeComparable",
            "function intUnsignedCmp",
            "function intSignedCmp",
            "function realCmp",
            "function ctfeCmpArrays",
            "function funcptrOf",
            "function isArray",
            "function ctfeRawCmp",
            "function ctfeEqual",
            "function ctfeIdentity",
            "function ctfeCmp",
            "function ctfeCat",
            "function findKeyInAA",
            "function ctfeIndex",
            "function ctfeCast",
            "function assignInPlace",
            "function recursiveBlockAssign",
            "function changeOneElement",
            "function modifyStructField",
            "function assignAssocArrayElement",
            "function changeArrayLiteralLength",
            "function isCtfeValueValid",
            "function showCtfeExpr",
            "struct CtfeStatus",
            "struct ClassReferenceExp",
            "struct VoidInitExp",
            "struct ThrownExceptionExp",
        ],
        M("traits", null, ["expression", "identifier", "dsymbol", "arraytypes", "root.aav", "mtype", "func", "declaration", "defs",
                           "id", "mars", "attrib"]) :
        [
            "struct Ptrait",
            "function fptraits",
            "function collectUnitTests",
            "function isTypeArithmetic",
            "function isTypeFloating",
            "function isTypeIntegral",
            "function isTypeScalar",
            "function isTypeUnsigned",
            "function isTypeAssociativeArray",
            "function isTypeStaticArray",
            "function isTypeAbstractClass",
            "function isTypeFinalClass",
            "function isFuncAbstractFunction",
            "function isFuncVirtualFunction",
            "function isFuncVirtualMethod",
            "function isFuncFinalFunction",
            "function isFuncStaticFunction",
            "function isFuncOverrideFunction",
            "function isDeclRef",
            "function isDeclOut",
            "function isDeclLazy",
        ],
        M("builtin", null, ["mars", "expression", "func", "arraytypes", "defs", "mtype", "lexer"]) :
        [
            "function eval_bsf",
            "function eval_bsr",
            "function eval_bswap",
            "function eval_builtin",
        ],
        M("clone", null, ["mars", "defs", "declaration"]) :
        [
            "function mergeFuncAttrs",
        ],
        M("lib") :
        [
            "struct Library",
        ],
        M("arrayop", null, ["root.aav", "func", "identifier", "expression", "dscope", "mars", "defs", "arraytypes", "mtype", "statement",
                            "lexer", "id", "declaration", "dsymbol"]) :
        [
            "variable arrayfuncs",
            "struct ArrayOp",
            "function isDruntimeArrayOp",
            "function buildArrayOp",
            "function isArrayOpValid",
        ],
        M("aliasthis", null, ["dsymbol", "identifier", "mars", "dscope", "root.outbuffer", "hdrgen", "visitor", "expression", "defs",
                              "aggregate", "mtype", "declaration", "lexer", "opover"]) :
        [
            "struct AliasThis",
            "function resolveAliasThis",
        ],
        M("json", null, ["visitor", "root.outbuffer", "mars", "mtype", "arraytypes", "dsymbol", "declaration", "dmodule", "dimport",
                         "attrib", "dtemplate", "func", "aggregate", "denum", "defs", "id", "identifier", "dclass"]) :
        [
            "struct ToJsonVisitor",
            "function json_generate",
        ],
        M("dunittest", null, ["defs"]) :
        [
            "function unittests",
        ],
        M("imphint", null, ["defs"]) :
        [
            "function importHint",
            "version imphint.c:71",
        ],
        M("argtypes", null, ["mtype", "defs", "mars"]) :
        [
            "function mergeFloatToInt",
            "function argtypemerge",
        ],
        M("apply") :
        [
            "macro condApply",
        ],
        M("sapply") :
        [
            "macro scondApply",
        ],
        M("sideeffect", null, ["expression", "defs", "lexer", "mtype"]) :
        [
            "function lambdaHasSideEffect",
            "version sideeffect.c:249",
        ],
        M("canthrow", null, ["expression", "dsymbol", "defs", "lexer", "mars", "mtype", "dstruct", "attrib", "declaration", "dtemplate",
                             "arraytypes", "init", "root.rootobject"]) :
        [
            "struct CanThrow",
            "function lambdaCanThrow",
            "function Dsymbol_canThrow",
        ],
        M("target", null, ["mtype", "mars", "defs"]) :
        [
            "struct Target",
        ],
        M("id", null, ["identifier", "defs", "lexer"]) :
        [
            "struct Id",
        ],
        M("visitor", null, ["statement", "mtype", "dsymbol", "staticassert", "dversion", "denum", "dimport",
                            "aliasthis", "attrib", "cond", "dtemplate", "dmodule", "aggregate", "dstruct", "dclass",
                            "declaration", "func", "init", "expression", "ctfeexpr", "defs"]) :
        [
            "struct Visitor",
        ],
    ];
}