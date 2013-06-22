
SRC=magicport2.d ast.d scanner.d tokens.d parser.d printerast.d printercpp.d dprinter.d typenames.d visitor.d preprocess.d

DFLAGS=-g

LIBS=..\dmdgit\src\glue.lib ..\dmdgit\src\backend.lib ..\dmdgit\src\outbuffer.obj
# LIBS=..\dmdgit\src\gluestub.obj ..\dmdgit\src\backend.lib

COMPILER=

run: magicport2.exe
	magicport2
	..\dmdgit\src\dmd -g -J..\dmdgit -magicport port/dmd defs -d -ofport\dmd.exe  $(LIBS) -debug
	port\dmd          -g -J..\dmdgit -magicport port/dmd defs -d -ofport\dmdx.exe $(LIBS) -debug

magicport2.exe : $(SRC)
	dmd $(SRC) $(DFLAGS)

clean:
	del magicport2.exe
