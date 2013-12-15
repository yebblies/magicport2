
SRC=magicport2.d ast.d scanner.d tokens.d parser.d printerast.d printercpp.d dprinter.d typenames.d visitor.d preprocess.d

PHOBOSLIB=../phobos/generated/linux/release/64

DFLAGS=-g -I../druntime/import -I../phobos -L-L$(PHOBOSLIB) -L--export-dynamic

LIBS=../dmd/src/outbuffer.o ../dmd/src/glue.a ../dmd/src/backend.a
# LIBS=../dmd/src/gluestub.o ../dmd/src/backend.a

COMPILER=../dmd/src/dmd
FLAGS=-debug -gc -vtls -J../dmd -d -version=DMDV2 -I../druntime/import

default: gen build1 build2

gen: magicport2
	./magicport2 ../dmd/src/

build1: port/dmd
port/dmd: port/dmd.d defs.d $(LIBS)
	$(COMPILER) port/dmd defs -c -ofport/dmd.o $(FLAGS)
	g++ -oport/dmd port/dmd.o $(LIBS) -L$(PHOBOSLIB) -lphobos2

build2: port/dmdx
port/dmdx: port/dmd.d defs.d port/dmd $(LIBS)
	LD_LIBRARY_PATH=$(PHOBOSLIB) port/dmd port/dmd defs -c -ofport/dmdx.o $(FLAGS)
	g++ -oport/dmdx port/dmd.o $(LIBS) -L$(PHOBOSLIB) -lphobos2

magicport2 : $(SRC)
	$(COMPILER) $(SRC) $(DFLAGS)

clean:
	rm magicport2
	rm *.o
	rm port/*.o
	rm port/dmd
	rm port/dmdx
