
SRC=magicport2.d ast.d scanner.d tokens.d parser.d printerast.d printercpp.d dprinter.d typenames.d visitor.d preprocess.d

DFLAGS=-g

run: magicport2.exe
	magicport2

magicport2.exe : $(SRC)
	dmd $(SRC) $(DFLAGS)

clean:
	del magicport2.exe
