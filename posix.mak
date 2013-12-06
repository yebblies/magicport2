
SRC=magicport2.d ast.d scanner.d tokens.d parser.d printerast.d printercpp.d dprinter.d typenames.d visitor.d preprocess.d

DFLAGS=-g -I../druntime/import -I../phobos -L-L../phobos/generated/linux/release/default -L--export-dynamic

LIBS=../dmd/src/outbuffer.o ../dmd/src/glue.a ../dmd/src/backend.a
# LIBS=../dmd/src/gluestub.o ../dmd/src/backend.a

COMPILER=../dmd/src/dmd
FLAGS=-debug -gc -vtls -J../dmd -d -version=DMDV2 -I../druntime/import -L-L../phobos/generated/linux/release/default

default: gen build1 build2

gen: magicport2
	./magicport2 ../dmd/src/

build1: port/dmd
port/dmd: port/dmd.d defs.d $(LIBS)
	$(COMPILER) port/dmd defs -c -ofport/dmd.o $(FLAGS)
	g++ port/dmd.o $(LIBS) -L../phobos/generated/linux/release/default -lphobos2

build2: port/dmdx
port/dmdx: port/dmd.d defs.d port/dmd $(LIBS)
	port/dmd    port/dmd defs -ofport/dmdx $(LIBS) $(FLAGS) -L-lstdc++

magicport2 : $(SRC)
	$(COMPILER) $(SRC) $(DFLAGS)

clean:
	del magicport2
	del *.o
	del port/*.o
	del port/dmd
	del port/dmdx
