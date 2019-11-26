SHELL = /bin/sh
LIBS  = ${WGRIB2LIB} ${W3NCO_LIB4} ${W3EMC_LIB4} ${BACIO_LIB4} 
MOD   = -I${WGRIB2INC}

FC      =ifort
FFLAGS   =  -free -convert big_endian -qopenmp

SRCS = pkind.f90 pietc.f90 pbend.f90 sat_mrms_fill.f90
OBJS = pkind.o   pietc.o   pbend.o   sat_mrms_fill.o
CMD  = pcpurma_sat_mrms_fill

all: $(CMD)

$(CMD): $(OBJS)
	$(FC) $(FFLAGS) -o $(@) $(OBJS) $(LIBS)

$(OBJS): $(SRCS)
	$(FC)  $(FFLAGS) $(SRCS) -c $(MOD)

clean:
	rm -f *.o *.lst *.mod $(CMD)
mvexec:
	mv $(CMD) ../../exec/.

