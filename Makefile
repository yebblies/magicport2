
SRC=magicport2.d ast.d scanner.d tokens.d parser.d printerast.d printercpp.d dprinter.d typenames.d visitor.d preprocess.d

DFLAGS=-g -w -debug

UNAME := $(shell uname)

ifeq ($(UNAME), Linux)
TARGET = magicport2
else
TARGET = magicport2.exe
endif

run: $(TARGET)
	./magicport2

ifeq ($(UNAME), Linux)
	../dmdgit/src/dmd -g -J../dmdgit -magicport port/dmd defs -d -ofport/dmd ../dmdgit/src/glue.a ../dmdgit/src/backend.a
	port/dmd -g -J../dmdgit -magicport port/dmd defs -d -ofport/dmdx ../dmdgit/src/glue.a ../dmdgit/src/backend.a
else
	..\dmdgit\src\dmd -g -J..\dmdgit -magicport port/dmd defs -d -ofport\dmd.exe ..\dmdgit\src\glue.lib ..\dmdgit\src\backend.lib
	port\dmd -g -J..\dmdgit -magicport port/dmd defs -d -ofport\dmdx.exe ..\dmdgit\src\glue.lib ..\dmdgit\src\backend.lib
endif

$(TARGET) : $(SRC)
	dmd $(SRC) $(DFLAGS)

clean:
ifeq ($(UNAME), Linux)
	rm magicport2 *.o
else
	del magicport2.exe
endif
