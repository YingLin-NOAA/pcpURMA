set -x

##############################

BASE=`pwd`
export BASE

#. /usrx/local/Modules/default/init/ksh #wcoss phase-2
. /usrx/local/prod/lmod/lmod/init/ksh   #dell
module purge
module use -a ${BASE}/../modulefile
module load URMA/v2.7.3

module list

cd ${BASE}/pcpurma_cmorph30min2grb.fd
make clean
make
make mvexec
make clean

##############################
