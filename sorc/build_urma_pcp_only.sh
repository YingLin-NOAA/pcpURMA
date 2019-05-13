BASE=`pwd`
export BASE

cd $BASE

# partial build list
# set all to yes to compile all codes

export BUILD_pcpurma_changepds=yes
export BUILD_pcpurma_cmorph30min2grb=yes

mkdir $BASE/logs
export logs_dir=$BASE/logs

. /usrx/local/prod/lmod/lmod/init/ksh    #dell
module purge
module use -a ${BASE}/../modulefile
module load URMA/v2.7.2

module list

##############################

if [ $BUILD_pcpurma_changepds = yes ] ; then

echo " .... Building pcpurma_changepds .... "
./build_pcpurma_changepds.sh > $logs_dir/build_pcpurma_changepds.log 2>&1

fi

cd $BASE

##############################

if [ $BUILD_pcpurma_cmorph30min2grb = yes ] ; then

echo " .... Building pcpurma_cmorph30min2grb .... "
./build_pcpurma_cmorph30min2grb.sh > $logs_dir/build_pcpurma_cmorph30min2grb.log 2>&1

fi

cd $BASE

##############################

