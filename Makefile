
SRC=magicport2.d ast.d scanner.d tokens.d parser.d printerast.d printercpp.d dprinter.d typenames.d visitor.d preprocess.d

DFLAGS=-g

LIBS=..\dmdgit\src\glue.lib ..\dmdgit\src\backend.lib ..\dmdgit\src\outbuffer.obj
# LIBS=..\dmdgit\src\gluestub.obj ..\dmdgit\src\backend.lib

COMPILER=

default: gen build1 build2

gen: magicport2.exe
	magicport2

build1: port\dmd.exe
port\dmd.exe: port\dmd.d defs.d
	..\dmdgit\src\dmd -g -J..\dmdgit -magicport port/dmd defs -d -ofport\dmd.exe  $(LIBS) -debug

build2: port\dmdx.exe
port\dmdx.exe: port\dmd.d defs.d port\dmd.exe
	port\dmd          -g -J..\dmdgit -magicport port/dmd defs -d -ofport\dmdx.exe $(LIBS) -debug

magicport2.exe : $(SRC)
	dmd $(SRC) $(DFLAGS)

clean:
	del magicport2.exe
