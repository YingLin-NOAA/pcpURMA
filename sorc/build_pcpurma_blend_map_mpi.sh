set -x

##############################

BASE=`pwd`
export BASE

#. /usrx/local/Modules/default/init/ksh #wcoss phase-2
. /usrx/local/prod/lmod/lmod/init/ksh   #dell

export LANG=en_US

export MP_EAGER_LIMIT=165536
export MP_COREFILE_FORMAT=lite
export MP_EUIDEVELOP=min
export MP_EUIDEVICE=sn_all
export MP_EUILIB=us
export MP_MPILIB=mpich2

export MP_LABELIO=yes
export MP_SINGLE_THREAD=yes
export MP_USE_BULK_XFER=yes
export MP_SHARED_MEMORY=yes

export MPICH_ALLTOALL_THROTTLE=0
export MP_COLLECTIVE_OFFLOAD=no
export KMP_STACKSIZE=1024m

export MP_TASK_AFFINITY=core:2
export OMP_NUM_THREADS=1

   thismachine=DELL
   MPIEXEC=mpirun
. /usrx/local/prod/lmod/lmod/init/ksh
   module purge
   module load ips/18.0.1.163
   module load impi/18.0.1
   module load lsf/10.1
   module load prod_util/1.1.0

#module list



cd ${BASE}/pcpurma_blend_map_mpi.fd
makefile.sh

##############################
