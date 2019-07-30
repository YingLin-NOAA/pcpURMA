#!/bin/sh
# script to run wget_nohrsc.sh
#
# Normal run schedule: 
# Suggested by YL on 16 May 2019 in email:
# get snowfall analysis from NOHRSC on 
#     18Z/21Z current day, then 18Z on 
#      $dayp1/$dayp2/$dayp3/$dayp5/$dayp7
#
# Let's ignore the 21Z run for now.  
#   If this script is (optional) argument, 
#     yyyymmdd, it runs "wget_nohrsc.sh yyyymmdd"  (goback=NO)
#   If this script is run w/o an argument (normally run in cron job), then
#     it runs wget_nohrsc.sh for $day, $daym1, $daym2, $daym3, $daym5, $daym7
#                                                  (goback=YES)
#

SCRIPT=/gpfs/dell2/emc/verification/noscrub/Ying.Lin/pcpanl/urma.v2.8.0/util.dev
if [ $# -eq 0 ]; then
  day0=`date +%Y%m%d`
  daym1=`date +%Y%m%d -d "1 day ago"`
  daym2=`date +%Y%m%d -d "2 day ago"`
  daym3=`date +%Y%m%d -d "3 day ago"`
  daym5=`date +%Y%m%d -d "5 day ago"`
  daym7=`date +%Y%m%d -d "7 day ago"`
  goback=YES
else
  day0=$1
  goback=NO
fi

if [ $goback = NO ]; then
  $SCRIPT/wget_nohrsc.sh $day0
else
  for day in $day0 $daym1 $daym2 $daym3 $daym5 $daym7
  do 
    $SCRIPT/wget_nohrsc.sh $day
  done
fi

exit


  

