
SRC=magicport2.d ast.d scanner.d tokens.d parser.d printerast.d printercpp.d dprinter.d typenames.d visitor.d preprocess.d

DFLAGS=-g

LIBS=..\dmdgit\src\glue.lib ..\dmdgit\src\backend.lib ..\dmdgit\src\outbuffer.obj
# LIBS=..\dmdgit\src\gluestub.obj ..\dmdgit\src\backend.lib

COMPILER=..\dmdgit\src\dmd.exe
FLAGS=-debug -gc -vtls -J..\dmdgit -magicport -d -version=DMDV2

default: gen build1 build2

gen: magicport2.exe
	magicport2

build1: port\dmd.exe
port\dmd.exe: port\dmd.d defs.d $(LIBS)
	$(COMPILER) port/dmd defs -ofport\dmd.exe $(LIBS) $(FLAGS)

build2: port\dmdx.exe
port\dmdx.exe: port\dmd.d defs.d port\dmd.exe $(LIBS)
	port\dmd    port/dmd defs -ofport\dmdx.exe $(LIBS) $(FLAGS)

magicport2.exe : $(SRC)
	$(COMPILER) $(SRC) $(DFLAGS)

clean:
	del magicport2.exe
