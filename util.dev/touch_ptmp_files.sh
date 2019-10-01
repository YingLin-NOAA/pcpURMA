#!/bin/sh
set -x
# during parallel runs, need to 'touch' the MRMS and CMORPH files on wexp grid
# on "$COMOUT" directory on ptmp, otherwise these files disappear after 5
# days and won't be available for the 7-day rerun!
#
# each day go 'touch' the mrms and cmorph files on wexp grid for 
#  $daym3,daym4,$daym5
COMOUT=/gpfs/dell2/ptmp/Ying.Lin/pcpanl/pcpurma
today=`date +%Y%m%d`

daym5=`date +%Y%m%d -d "5 days ago"`
daym4=`date +%Y%m%d -d "4 days ago"`
daym4=`date +%Y%m%d -d "3 days ago"`

for day in $daym5 $daym4 $daym3
do
  cd $COMOUT.$day
  touch mrms*wexp cmorph*wexp
done

exit
