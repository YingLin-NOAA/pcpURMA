SHELL=		/bin/sh

LIBS=           ${W3NCO_LIB4} ${W3EMC_LIB4} ${BACIO_LIB4}
FC=             ifort
FFLAGS=         -FR -cpp 

LDFLAGS=
SRCS=		pcpurma_changepds.f 
OBJS=		pcpurma_changepds.o 
CMD=		pcpurma_changepds

all:		$(CMD)

$(CMD):		$(OBJS)
	$(FC) $(LDFLAGS) -o $(@) $(OBJS) $(LIBS)

clean:
	-rm -f *.o *.lst $(CMD)
mvexec:
	-mv $(CMD) ../../exec/.
