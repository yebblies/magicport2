
SRC=magicport2.d ast.d scanner.d tokens.d parser.d printerast.d printercpp.d dprinter.d typenames.d visitor.d preprocess.d

DFLAGS=-g

run: magicport2.exe
	magicport2
	..\dmdgit\src\dmd -g -magicport port/dmd defs -d -ofport\dmd.exe ..\dmdgit\src\glue.lib ..\dmdgit\src\backend.lib
	port\dmd -g -magicport port/dmd defs -d -ofport\dmdx.exe ..\dmdgit\src\glue.lib ..\dmdgit\src\backend.lib

magicport2.exe : $(SRC)
	dmd $(SRC) $(DFLAGS)

clean:
	del magicport2.exe
