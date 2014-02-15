
SRC=magicport2.d ast.d scanner.d tokens.d parser.d dprinter.d typenames.d visitor.d namer.d

PHOBOSLIB32=../phobos/generated/linux/release/32
PHOBOSLIB64=../phobos/generated/linux/release/64

DFLAGS=-g -I../druntime/import -I../phobos -L-L$(PHOBOSLIB32) -L-L$(PHOBOSLIB64) -L--export-dynamic

LIBS=../dmd/src/outbuffer.o ../dmd/src/glue.a ../dmd/src/backend.a
# LIBS=../dmd/src/gluestub.o ../dmd/src/backend.a

COMPILER=../dmd/src/dmd
FLAGS=-debug -gc -vtls -J../dmd -d -version=DMDV2 -I../druntime/import

DP=port
RP=port/root
GENSRC=$(DP)/access.d $(DP)/aggregate.d $(DP)/aliasthis.d $(DP)/apply.d \
	$(DP)/argtypes.d $(DP)/arrayop.d $(DP)/arraytypes.d \
	$(DP)/attrib.d $(DP)/builtin.d $(DP)/canthrow.d $(DP)/dcast.d \
	$(DP)/dclass.d $(DP)/clone.d $(DP)/cond.d $(DP)/constfold.d \
	$(DP)/cppmangle.d $(DP)/ctfeexpr.d $(DP)/declaration.d \
	$(DP)/delegatize.d $(DP)/doc.d $(DP)/dsymbol.d \
	$(DP)/denum.d $(DP)/expression.d $(DP)/func.d \
	$(DP)/hdrgen.d $(DP)/id.d $(DP)/identifier.d $(DP)/imphint.d \
	$(DP)/dimport.d $(DP)/dinifile.d $(DP)/inline.d $(DP)/init.d \
	$(DP)/dinterpret.d $(DP)/json.d $(DP)/lexer.d $(DP)/link.d \
	$(DP)/dmacro.d $(DP)/dmangle.d $(DP)/mars.d \
	$(DP)/dmodule.d $(DP)/mtype.d $(DP)/opover.d $(DP)/optimize.d \
	$(DP)/parse.d $(DP)/sapply.d $(DP)/dscope.d $(DP)/sideeffect.d \
	$(DP)/statement.d $(DP)/staticassert.d $(DP)/dstruct.d \
	$(DP)/target.d $(DP)/dtemplate.d $(DP)/traits.d $(DP)/dunittest.d \
	$(DP)/utf.d $(DP)/dversion.d $(DP)/visitor.d \
	$(RP)/file.d $(RP)/filename.d $(RP)/speller.d

DM=manual
RM=manual/root
MANUALSRC= \
	$(DM)/intrange.d $(DM)/complex.d $(DM)/longdouble.d \
	$(DM)/lib.d $(DM)/libomf.d $(DM)/scanomf.d \
	$(DM)/libmscoff.d $(DM)/scanmscoff.d \
	$(DM)/libelf.d $(DM)/scanelf.d \
	$(DM)/entity.d \
	$(RM)/aav.d $(RM)/array.d \
	$(RM)/man.d $(RM)/rootobject.d $(RM)/outbuffer.d $(RM)/port.d \
	$(RM)/response.d $(RM)/rmem.d  $(RM)/stringtable.d

COPYSRC= \
	$(DP)/intrange.d $(DP)/complex.d $(DP)/longdouble.d \
	$(DP)/lib.d $(DP)/libomf.d $(DP)/scanomf.d \
	$(DP)/libmscoff.d $(DP)/scanmscoff.d \
	$(DP)/libelf.d $(DP)/scanelf.d \
	$(DP)/entity.d \
	$(RP)/aav.d $(RP)/array.d \
	$(RP)/man.d $(RP)/rootobject.d $(RP)/outbuffer.d $(RP)/port.d \
	$(RP)/response.d $(RP)/rmem.d  $(RP)/stringtable.d

DSRC= $(GENSRC) $(COPYSRC)

default: build1 build2

$(GENSRC) $(COPYSRC): magicport2 $(MANUALSRC) settings.json
	./magicport2 ../dmd/src/

build1: port/dmd
port/dmd: $(DSRC) defs.d $(LIBS)
	$(COMPILER) $(DSRC) defs -c -ofport/dmd.o $(FLAGS)
	g++ -oport/dmd port/dmd.o $(LIBS) -L$(PHOBOSLIB32) -L$(PHOBOSLIB64) -lphobos2

build2: port/dmdx
port/dmdx: $(DSRC) defs.d port/dmd $(LIBS)
	LD_LIBRARY_PATH=$(PHOBOSLIB32):$(PHOBOSLIB64) port/dmd $(DSRC) defs -c -ofport/dmdx.o $(FLAGS)
	g++ -oport/dmdx port/dmdx.o $(LIBS) -L$(PHOBOSLIB32) -L$(PHOBOSLIB64) -lphobos2

magicport2 : $(SRC)
	$(COMPILER) $(SRC) $(DFLAGS)

clean:
	rm -f magicport2
	rm -f *.o
	rm -f port/*.o
	rm -f port/*.d
	rm -f port/root/*.d
	rm -f port/dmd
	rm -f port/dmdx
