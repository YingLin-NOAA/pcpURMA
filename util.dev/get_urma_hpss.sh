#!/bin/sh
set -x

#day=$1
day1=20190913
day2=20190929

# theia:
# finddate=/scratch4/NCEPDEV/rstprod/nwprod/util/ush/finddate.sh

UTILROOT=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2
FINDDATE=$UTILROOT/ush/finddate.sh

day=$day2

wrkdir=/gpfs/dell2/ptmp/Ying.Lin/prod_urma

while [ $day -ge $day1 ];
do 
  mkdir -p $wrkdir/pcpurma.$day
  cd $wrkdir/pcpurma.$day
  yyyy=`echo $day | cut -c 1-4`
  yyyymm=`echo $day | cut -c 1-6`
#  htar xvf /NCEPPROD/hpssprod/runhistory/rh${yyyy}/$yyyymm/$day/com2_urma_prod_pcpurma.$day.tar
  htar xvf /NCEPPROD/hpssprod/runhistory/rh${yyyy}/$yyyymm/$day/gpfs_dell2_nco_ops_com_urma_prod_pcpurma.$day.tar

  day=`$FINDDATE $day d-1`
done

exit
