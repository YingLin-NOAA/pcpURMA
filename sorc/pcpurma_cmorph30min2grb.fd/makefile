SHELL=		/bin/sh

LIBS=           ${G2_LIB4} ${W3NCO_LIB4} ${W3EMC_LIB4} ${BACIO_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB}
FC=             ifort
FFLAGS=         -convert big_endian -assume byterecl -cpp

LDFLAGS=
SRCS=		cmorph30min2grb.f grib2_wrt_g2func.f
OBJS=		cmorph30min2grb.o grib2_wrt_g2func.o
CMD=		pcpurma_cmorph30min2grb

all:		$(CMD)

$(CMD):		$(OBJS)
	$(FC) $(LDFLAGS) -o $(@) $(OBJS) $(LIBS)

clean:
	-rm -f *.o *.lst $(CMD)
mvexec:
	-mv $(CMD) ../../exec/.
