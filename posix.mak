
SRC=magicport2.d ast.d scanner.d tokens.d parser.d dprinter.d typenames.d visitor.d namer.d

DFLAGS=-g

COMPILER=dmd

magicport2 : $(SRC)
	$(COMPILER) $(SRC) $(DFLAGS)

clean:
	rm -f magicport2
	rm -f *.o
