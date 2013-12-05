
SRC=magicport2.d ast.d scanner.d tokens.d parser.d printerast.d printercpp.d dprinter.d typenames.d visitor.d preprocess.d

DFLAGS=-g -I../druntime/import -I../phobos -L-L../phobos/generated/linux/debug/default

LIBS=../dmd/src/glue.a ../dmd/src/backend.a ../dmd/src/outbuffer.o
# LIBS=../dmd/src/gluestub.o ../dmd/src/backend.a

COMPILER=../dmd/src/dmd
FLAGS=-debug -gc -vtls -J../dmd -d -version=DMDV2 -I../druntime/import

default: gen build1 build2

gen: magicport2
	./magicport2 ../dmd/src/

build1: port/dmd
port/dmd: port/dmd.d defs.d $(LIBS)
	$(COMPILER) port/dmd defs -ofport/dmd $(LIBS) $(FLAGS)

build2: port\dmdx.exe
port\dmdx: port/dmd.d defs.d port/dmd $(LIBS)
	port\dmd    port/dmd defs -ofport/dmdx $(LIBS) $(FLAGS)

magicport2 : $(SRC)
	$(COMPILER) $(SRC) $(DFLAGS)

clean:
	del magicport2
	del *.o
	del port\*.o
	del port\dmd
	del port\dmdx
