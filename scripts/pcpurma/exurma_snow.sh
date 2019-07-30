#!/bin/ksh
#######################################################################
#  Purpose: add WMO header to NOHRSC 6h/24h snowfall analysis
#######################################################################
#
echo "------------------------------------------------"
echo " exurma_snow.sh:                                "
echo "------------------------------------------------"
#
# 2019/07/11: created
#
#######################################################################

set -x

export JDATA=$DATA 
DATA=$DATA
mkdir -p $DATA
cd $DATA
# $PDY and $cyc are exported in J-job.
date0=${PDY}${cyc}

postmsg $jlogfile "Begin Precip URMA snowfall analysis for $run version of $PDY"

########################################

day0=`echo $date0 | cut -c1-8`

cd $DATA

pwd

# process the NOHRSC files: for 6h/24h snowfall analysis covering a 24h period
# ending at 12Z $day (day=PDY, PDYm1, PDYm2, PDYm3, PDYm5, PDYm7), add WMO 
# header to each file

# Make a list of snowfall analysis to process.  Only list valid hours/accum 
# periods that have a non-zero NOHRSC file. 

todolist=todo_snow.$date0
rm -f $todolist

for day in $PDYm7 $PDYm5 $PDYm3 $PDYm2 $PDYm1 $PDY
do
  daym1=`$FINDDATE $day d-1`
  vdate=${daym1}18
  while [ $vdate -le ${day}12 ]
  do
    snow6h=sfav2_CONUS_6h_${vdate}_grid184.grb2
    vday=${vdate:0:8}
    vhr=${vdate:8:2}
    cp $DCOMSNOW/$vday/wgrbbul/qpe/$snow6h .
    if [ -s $snow6h ]; then
      echo $vdate.6h >> $todolist
    fi

    if [ $vhr -eq 12 ]; then
      snow24h=sfav2_CONUS_24h_${vdate}_grid184.grb2
      cp $DCOMSNOW/$vday/wgrbbul/qpe/$snow24h .
      if [ -s $snow24h ]; then
        echo $vdate.24h >> $todolist
      fi
    fi
    vdate=`$NDATE +6 $vdate`
  done # Loop through valid of ${daym1}18, ${day}00, ${day}06, ${day}12
done   # for 24h period ending at 12Z of PDYm7, PDYm5, PDYm3, PDYm2, PDYm1, PDY

# Entries in the todolist looks like
#   2019070106.06h
#   2019070112.06h
#   2019070112.24h
#
# We are using the format above instead of the more elegant
#   2019070106 06h
#   2019070112 06h
#   2019070112 24h
#   because if we want to use this list later to do a post-processing transfer
#   queue scp to the rzdm in dev mode, 
#     cat $todolist | while read tmp
#     won't work - it stops after the first round of scp
#     (see my ksh note from 2014).  
#  
# With the '2019070106.06h', we can do the loop with 
#     cat $todolist | while read tmp
#   in this script, and later for transfer/scp, use 
#     for tmp in `cat $todolist` 
#     to loop through.  
#  
# Now loop through the to-do list to process each NOHRSC snowfall file:
cat $todolist | while read tmp
do
  vdate=`echo $tmp | awk -F"." '{print $1}'`
  vday=${vdate:0:8}
  vhr=${vdate:8:2}
  ac=`echo $tmp | awk -F"." '{print $2}'`
  nohrscfile=sfav2_CONUS_${ac}_${vdate}_grid184.grb2

  if [ $ac = 6h ]; then
    snowparm=$PARMurma/grib2_sfav2_asnow_g184.06h
    awipsfile=grib2.${vday}.t${vhr}z.snowfall.184.06h
  else
    snowparm=$PARMurma/grib2_sfav2_asnow_g184.24h
    awipsfile=grib2.${vday}.t${vhr}z.snowfall.184.24h
  fi

  # Add WMO header:
  export pgm=tocgrib2
  . prep_step
  export FORT11="$nohrscfile"
  export FORT31=" "
  export FORT51="$awipsfile"
  startmsg
  $TOCGRIB2 < $snowparm
  export err=$?;err_chk
  echo '     err=' $? 

  if test $SENDCOM = 'YES'
  then
    cp $nohrscfile $COMOUT/${RUN}.$vday/.
    cp $awipsfile  $COMOUT/${RUN}.$vday/wmo/.
  fi   # SENDCOM?

  if test $SENDDBN = 'YES'
  then
    # SEND URMA snowfall files to nomads.ncep.noaa.gov.  
    $DBNROOT/bin/dbn_alert MODEL URMASNOWFALL_GB2 $job $COMOUT/${RUN}.$vday/$nohrscfile
  fi   # SENDDBN?

# to TOC/AWIPS:
  if test $SENDDBN_NTC = 'YES'
  then
    $DBNROOT/bin/dbn_alert GRIB_LOW $NET $job $COMOUT/${RUN}.$vday/wmo/$awipsfile
  fi   # SENDDBN_NTC?

done # loop through each item on the to-do list

if [ $RUN_ENVIR = dev ]; then   # for developers
  bsub < $HOMEurma/util.dev/send2rzdm.sh
fi

# copy snow todo list for this hour to COMOUT:
if test $SENDCOM = 'YES'
then
  cp $todolist $COMOUT/${RUN}.$PDY/.
fi   # SENDCOM?
#####################################################################
# GOOD RUN
postmsg $jlogfile "$0 completed normally"
#####################################################################

############## END OF SCRIPT #######################
