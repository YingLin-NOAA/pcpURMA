#!/bin/sh
set -x

day1=20190913
day2=20191002

UTILROOT=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2
FINDDATE=$UTILROOT/ush/finddate.sh

day=$day1

datadir=/gpfs/dell2/ptmp/Ying.Lin/wget_urma2p8

while [ $day -le $day2 ];
do 
  mkdir -p $datadir/pcpurma.$day
  cd $datadir/pcpurma.$day
  URLPATH=https://ftp.emc.ncep.noaa.gov/mmb/precip/urma.v2.8.0/pcpurma.$day/
  wget ${URLPATH}/pcpurma_wexp.${day}{00,06,12,18}.06h.grb2

  day=`$FINDDATE $day d+1`
done

exit
