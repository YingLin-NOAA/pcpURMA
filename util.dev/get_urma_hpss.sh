#!/bin/sh
set -x

#day=$1
day1=20190202
day2=20190203

# theia:
# finddate=/scratch4/NCEPDEV/rstprod/nwprod/util/ush/finddate.sh

UTILROOT=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2
FINDDATE=$UTILROOT/ush/finddate.sh

day=$day1

wrkdir=/gpfs/dell2/ptmp/Ying.Lin

while [ $day -le $day2 ];
do 
  mkdir -p $wrkdir/pcpurma.$day
  cd $wrkdir/pcpurma.$day
  yyyy=`echo $day | cut -c 1-4`
  yyyymm=`echo $day | cut -c 1-6`
  htar xvf /NCEPPROD/hpssprod/runhistory/rh${yyyy}/$yyyymm/$day/com2_urma_prod_pcpurma.$day.tar
  day=`$FINDDATE $day d+1`
done

exit
