BASE=`pwd`
export BASE

cd $BASE

# partial build list
# set all to yes to compile all codes

export BUILD_urma_firstguess=yes
export BUILD_urma_gsianl=yes
export BUILD_urma_post=yes
export BUILD_urma_mintobs=yes
export BUILD_urma_mintbg=yes
export BUILD_urma_maxtobs=yes
export BUILD_urma_maxtbg=yes
export BUILD_urma_maxrh=yes
export BUILD_urma_minrh=yes
export BUILD_pcpurma_cmorph30min2grb=yes
export BUILD_pcpurma_sat_mrms_fill=yes
export BUILD_pcpurma_change2wmohdr=yes
export BUILD_pcpurma_blend_map_mpi=yes
export BUILD_grib2_lib=yes

mkdir $BASE/logs
export logs_dir=$BASE/logs

#. /usrx/local/Modules/default/init/ksh  #wcoss-phase2
. /usrx/local/prod/lmod/lmod/init/ksh    #dell
module purge
module use -a ${BASE}/../modulefile
module load URMA/v2.8.0

module list

sleep 1

##############################

if [ $BUILD_urma_firstguess = yes ] ; then

echo " .... Building urma_firstguess .... "
./build_urma_firstguess.sh > $logs_dir/build_urma_firstguess.log 2>&1

fi

cd $BASE

##############################

if [ $BUILD_urma_gsianl = yes ] ; then

echo " .... Building urma_gsi .... "
./build_urma_gsianl.sh > $logs_dir/build_urma_gsianl.log 2>&1

fi

cd $BASE

##############################

if [ $BUILD_urma_post = yes ] ; then

echo " .... Building post .... "
./build_urma_post.sh > $logs_dir/build_urma_post.log 2>&1

fi

cd $BASE

##############################

if [ $BUILD_urma_mintobs = yes ] ; then

echo " .... Building urma_mintobs .... "
./build_urma_mintobs.sh > $logs_dir/build_urma_mintobs.log 2>&1

fi

cd $BASE

##############################

if [ $BUILD_urma_mintbg = yes ] ; then

echo " .... Building urma_mintbg .... "
./build_urma_mintbg.sh > $logs_dir/build_urma_mintbg.log 2>&1

fi

cd $BASE

##############################

if [ $BUILD_urma_maxtobs = yes ] ; then

echo " .... Building urma_maxtobs .... "
./build_urma_maxtobs.sh > $logs_dir/build_urma_maxtobs.log 2>&1

fi

cd $BASE

##############################

if [ $BUILD_urma_maxtbg = yes ] ; then

echo " .... Building urma_maxtbg .... "
./build_urma_maxtbg.sh > $logs_dir/build_urma_maxtbg.log 2>&1

fi

cd $BASE

##############################

if [ $BUILD_urma_maxrh = yes ] ; then

echo " .... Building urma_maxrh .... "
./build_urma_maxrh.sh > $logs_dir/build_urma_maxrh.log 2>&1

fi

cd $BASE

##############################

if [ $BUILD_urma_minrh = yes ] ; then

echo " .... Building urma_minrh .... "
./build_urma_minrh.sh > $logs_dir/build_urma_minrh.log 2>&1

fi

cd $BASE

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

##############################

if [ $BUILD_pcpurma_blend_map_mpi = yes ] ; then

echo " .... Building pcpurma_blend_map_mpi .... "
./build_pcpurma_blend_map_mpi.sh > $logs_dir/build_pcpurma_blend_map_mpi.log 2>&1

fi

cd $BASE


##############################

if [ $BUILD_grib2_lib = yes ] ; then

echo " .... Building grib2/wgrib2 library .... "
cd ../lib/grib2
build_wgrib2.sh > $logs_dir/build_wgrib2_lib.log 2>&1

export BUILD_grib2_lib=yes


fi

cd $BASE
