#!/bin/ksh
# sum up the wexp 6h/24h cmorph/mrms from hourlies
#  (nothing special in the grib2 sum using wgrib2 about wexp, except for the
#   wexp suffix in the output file name) 
# The CMORPH files have already been processed into 'standard' GRIB2 files with
#   'APCP'. 
# MRMS files have 'normal' data mask (rather than '-3' as missing values, which
#   will mess up copygb), though the parameter is still not 
#   'APCP/Total Precipitation'
# 
# Input: 
#   Hourly cmorph: cmorph.2018011615.01h.wexp
#   Hourly MRMS:     mrms.2018011605.01h.wexp
# 
# Output:
#                  cmorph.2018011606.06h.wexp
#                  cmorph.2018011612.24h.wexp
#                    mrms.2018011606.06h.wexp
#                    mrms.2018011612.24h.wexp
#
set -x
if [ $# -lt 3 ]; then
  echo Three arguments required: analysis name \(cmorph or mrms\), vvdate \(yyymmddhh\) and ac \(e.g. 06 or 24\)
  exit
else
  anl=$1
  vdate=$2
  ac=$3
fi

vday=${vdate:0:8}

# Check to see if the 6h sum exists already:
if [ -s $COMIN/$RUN.$vday/$anl.$vdate.${ac}h.wexp ]; then
  echo $COMIN/$RUN.$vday/$anl.$vdate.${ac}h.wexp exists already
  exit
fi

# COMIN set by config/pcpurma/pcpurma_envir.sh in dev, 
#              in jobs/JURMA_PCPN in non-dev
#COMIN=/ptmpp2/Ying.Lin/pcpanl/pcpurma

let delt=ac-1
# refdate is used to set reference time in wgrib2 below.  For ac=24, 
# it's 24h prior
refdate=`$NDATE -$ac $vdate`  
# date1hr is the validation time of the first hourly file to be summed, so it's
# actually refdate+1hr.
date1hr=`$NDATE +1 $refdate`

# all files present?
aok=YES
rm -f input_acc
while [ $date1hr -le $vdate ]; do
  day1hr=${date1hr:0:8}
  file=$COMIN/${RUN}.$day1hr/$anl.$date1hr.01h.wexp
  if [ -s $file ]
  then
    echo $file >> input_acc
  else
    aok=NO
    echo $file not found.  
    break
  fi
  date1hr=`$NDATE +1 $date1hr`
done

if [ $aok = YES ]
then
  cat `cat input_acc` | $WGRIB2 - -ave 1hr ave.grb

  $WGRIB2 ave.grb -rpn "${ac}:*" -set_date $refdate -set_ave "0-${ac} hour ave anl" -set_scaling -1 0 -grib_out $anl.$vdate.${ac}h.wexp

  cp $anl.$vdate.${ac}h.wexp $COMOUT/${RUN}.$vday/.
fi

exit
