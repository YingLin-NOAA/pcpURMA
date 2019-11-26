BASE=`pwd`
export BASE

cd $BASE

# partial build list
# set all to yes to compile all codes

export BUILD_pcpurma_cmorph30min2grb=yes
export BUILD_pcpurma_sat_mrms_fill=yes
export BUILD_pcpurma_change2wmohdr=yes

mkdir $BASE/logs
export logs_dir=$BASE/logs

. /usrx/local/prod/lmod/lmod/init/ksh    #dell
module purge
module use -a ${BASE}/../modulefile
module load URMA/v2.8.0

module list

##############################

if [ $BUILD_pcpurma_cmorph30min2grb = yes ] ; then

echo " .... Building pcpurma_cmorph30min2grb .... "
./build_pcpurma_cmorph30min2grb.sh > $logs_dir/build_pcpurma_cmorph30min2grb.log 2>&1

fi

cd $BASE

##############################

if [ $BUILD_pcpurma_sat_mrms_fill = yes ] ; then

echo " .... Building pcpurma_sat_mrms_fill .... "
./build_pcpurma_sat_mrms_fill.sh > $logs_dir/build_pcpurma_sat_mrms_fill.log 2>&1

fi

cd $BASE

##############################


if [ $BUILD_pcpurma_change2wmohdr = yes ] ; then

echo " .... Building pcpurma_change2wmohdr .... "
./build_pcpurma_change2wmohdr.sh > $logs_dir/build_pcpurma_change2wmohdr.log 2>&1

fi

cd $BASE




