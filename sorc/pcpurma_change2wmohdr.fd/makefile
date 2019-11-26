SHELL= 	/bin/bash
#INC=     /nwprod/lib/incmod/g2_4
LIBS=    ${G2_LIB4} ${W3NCO_LIB4} ${W3EMC_LIB4} ${BACIO_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB}
	 #-ljasper -lpng -lz
SRCSf90= change2wmohdr.f90 INIT_PARM.f90 PRINTINFR.f90
#SRCSf=   EPDF.f SORTMM.f
SRCS=    $(SRCSf90) $(SRCSf)
OBJS=    $(SRCSf90:.f90=.o)
CMD=   	pcpurma_change2wmohdr
FC= 	ifort
FFLAGS = -O3 -g -convert big_endian -I ${G2_INC4}
LDFLAGS=

# Lines from here on down should not need to be changed.  They are the
# actual rules which make uses to build a.out.
#
all:    $(CMD)

$(CMD):		$(OBJS)
	$(FC) $(LDFLAGS) -o $(@) $(OBJS) $(LIBS)
	rm -f $(OBJS)

$(OBJS):        $(SRCS)
	$(FC) $(FFLAGS) -c $(SRCS)

$(OBJS):        makefile

allclean:       clean all

clean:
	-rm -f $(OBJS)

mvexec:
	mv $(CMD) ../../exec/$(CMD)


