
====== Magicport Manual ======

Magicport is a terrible hack.

Source:

magicport.d

- Contains entry point.
- First loads the json settings file
- prefixes all the imports with 'ddmd.'
- Translates the list of modules into a D format
- Loads tables of basic types, structs,
  'root' classes (base classes),
  functions that need 'override',
  functions that don't need 'final'
- For each source file
    - Loads and lexes the file
    - Scans for class and struct names
- Parses and runs 'scanner' on each file
- Collapses the AST (combining member functions declarations with definitions, etc)
- Builds a map of all symbols using a mangling scheme
- Walks the AST to write the output files

tokens.d
- Lexes C++ source files

parser.d
- Parses C++ source files

ast.d
- Containts C++ AST definitions

dprinter.d
- Contains D output AST walker

namer.d
- Contains symbol mangler

printerast.d
- Debug ast printer

printercpp.d
- Debug C++ ast printer, not maintained and probably doesn't work

scanner.d
- Contains an AST visitor that builds lists of structs, classes, etc
    - Used for locating declarations to merge with definitions
- A collection of functions to:
    - Merge member function prototypes and definitions
    - Transfer default arguments from function prototypes to definitions
    - Transfer static member initializers to the declarations
    - Drop duplicate typedefs (aliases conflict in D)
    - Drop FILE_H include guards
    - Build a new constructor for Scope (special case)
    - Delete dead code
        - unused prototypes
        - #undef
        - #define LOG
        - Default ctors
        - extern(C) function prototypes
        - backend typedefs
        - assert macro definition

typenames.d
- Lists of names of types, mostly moved into magicport.json

visitor.d
- Visitor implementation



Config:

"src"
    List of C++ source files (.c and .h)

"mapping"
    List of modules containing
        - "module" - module name
        - "package" - package name
        - "imports" - list of imports
        - "extra" - list of special stuff to copy-paste into the generated file
        - "members" - list of mangled names of symbols to include

"basicTypes"
    list of 'basic' types, pretty much anything that isn't a struct/class/enum

"structTypes"
    List of struct/enum types that the scanner doesn't pick up - mostly ones defined
    in weird places

"classTypes"
    ditto

"rootclasses"
    Base classes

"overriddenfuncs"
    List of classname, functionname pairs of functions that can't be final

"nonfinalclasses"
    List of classes that can't be final.



Usage:

- Build magicport (all .d source files together)
- Update magicport.json
- Run magicport
    - takes two arguments (sourcedir, destdir)
    - I usually just run it in the source directory and generate the D source there
    - i.e. path/to/magicport . .
    - It will look for magicport.json in the current directory
