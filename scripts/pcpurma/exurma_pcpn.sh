#!/bin/ksh
#######################################################################
#  Purpose: Produce precip URMA fields from IV.  
#  Use todo_urma.$date0 ($date0 is the current hour) produced by the pcpanl
#    job to determine which URMA files to process.  
#######################################################################
#
echo "------------------------------------------------"
echo " exurma_pcpn.sh:                                "
echo "------------------------------------------------"
#
# History:
# 2017/05/31 starting from pcpanl/scripts/expcpn_anal.sh, combine with
#   scripts/expcpn_stage4.sh to do post-pcpanl generation of pcp RTMA and URMA
#   fields.
# 2017/07/07: separate out rtma and urma processing.
#
#######################################################################

set -x

export JDATA=$DATA 
DATA=$DATA
mkdir -p $DATA
cd $DATA
# $PDY and $cyc are exported in J-job.
# date0 exported for ush/urma_prep_sat_mrms.sh:
export date0=${PDY}${cyc}
# Do the OConUS filling for hourlies that are at least 24 hours old
export date0m24h=`$NDATE -24 $date0`

postmsg $jlogfile "Begin Precip URMA analysis for $run version of $date0"

########################################

day0=`echo $date0 | cut -c1-8`

cd $DATA

pwd

# process the URMA file by going through a list produced by the pcpanl file:

# The 2345x1597 west-expanded ConUS grid (wexp):
export NDFDwexp="30 1 0 6371200 0 0 0 0 2345 1597  19228976 233723448 8 25000000 265000000 2539703 2539703 0 64 25000000 25000000 -90000000 0"

# ConUS grid (NDFDgrid184 is created for ush/urma_prep_sat_mrms.sh):
export NDFDgrid184="30 1 0 6371200 0 0 0 0 2145 1377  20191999 238445999 8 25000000 265000000 2539703 2539703 0 64 25000000 25000000 -90000000 0"
# NWRFC grid: 
NDFDgrid188="30 1 0 6371200 0 0 0 0 709 795 37979684 234042704  8 25000000 265000000 2539703 2539703 0 64 25000000 25000000 -90000000 0"

# Prepare CMORPH and MRMS data for URMA:
$USHurma/urma_prep_sat_mrms.sh

cp $COMINpcpanl/pcpanl.$day0/todo_urma.$date0 .

for item in `cat todo_urma.$date0`
do 
  date=`echo $item | cut -c1-10`
  day=`echo $item | cut -c1-8`
  ac=`echo $item | awk -F"." '{print $2}'`
  region=`echo $item | awk -F"." '{print $3}'`
  
  if [ $region = conus ]; then
    ST4file=ST4.$date.$ac
    urmawexp=pcpurma_wexp.$date.$ac.grb2
    urma184=pcpurma_g184.$date.$ac.grb2
    urma188=pcpurma_g188.$date.$ac.grb2
  else
    ST4file=st4_${region}.$date.$ac
    urmafile=pcpurma_${region}.$date.$ac.grb2
  fi

  cp $COMINpcpanl/pcpanl.$day/$ST4file.gz .
  gunzip $ST4file.gz
  err=$?
  if [ $err -ne 0 ]; then
    echo $ST4file.gz does not exist or cannot be gunzipped.  Skip this for URMA.
    break
  fi
  
  # Change the generating process number, PDS(2) from 182 (Stage IV) to 118
  # (URMA products); also change the time range setting from the RFC convention
  # for 6h QPE (as 00-06, 06-12, 12-18, 18-24h 'forecasts' from 12Z) to
  # straightforward 06h accumulation.

  ln -sf $ST4file                     fort.11
  ln -sf $ST4file.chgdpds             fort.51
  ${EXECurma}/pcpurma_changepds
  export err=$?;err_chk
  echo '     err=' $? 
  # Convert to GRIB2:
  $CNVGRIB -g12 $ST4file.chgdpds ${ST4file}.gb2

  if [ $region = conus ]; then
    # map to the 2.5km 2345x1597 west-expanded ConUS grid (wexp)
    $COPYGB2 -g "$NDFDwexp" -i3 -x ${ST4file}.gb2 $urmawexp

    # If valid time is at least 24h ago, fill in with MRMS and CMORPH:
    if [ $date -le $date0m24h ]
    then
      $USHurma/urma_sat_mrms_fill.sh $date $ac $urmawexp
    fi

    # Use copygb nearest neighbor to map $urmawexp to g184 and g188:
    # Map to 2.5km ConUS NDFD grid:
    $COPYGB2 -g "$NDFDgrid184" -i2 -x $urmawexp $urma184
    wmohdrconus=grib2_pcpurma_g184.$ac

    # Map to 2.5km NWRFC NDFD grid:
    $COPYGB2 -g "$NDFDgrid188" -i2 -x $urmawexp $urma188
    wmohdrnwrfc=grib2_pcpurma_g188.$ac

  elif [ $region = pr ]; then
    NDFDgrid="10 1 0 6371200 0 0 0 0 177 129 16828685 291804687 56 20000000 19747399 296027600 64 0 2500000 2500000"
    wmoheader=grib2_pcpurma_g195.$ac
  elif [ $region = ak ]; then
    NDFDgrid="20 1 0 6371200 0 0 0 0 1649 1105 40530101 181429000 8 60000000 210000000 2976563 2976563 0 64"
    # AK URMA is 06h only, but use $ac, (in case there's a script error, '01h' 
    # would be a tip-off)
    wmoheader=grib2_pcpurma_g91.$ac
  fi # ConUS, PR or AK?

  # Change the generating process number, PDS(2) from 182 (Stage IV) to 118
  # (URMA products); for 6h URMA, also change the time range setting from the 
  # RFC convention for 6h QPE (as 00-06, 06-12, 12-18, 18-24h 'forecasts' 
  # from 12Z) to straightforward 06h accumulation.

  ln -sf $ST4file                     fort.11
  ln -sf $ST4file.chgdpds             fort.51
  ${EXECurma}/pcpurma_changepds
  export err=$?;err_chk
  echo '     err=' $? 
# Convert to GRIB2:
  $CNVGRIB -g12 $ST4file.chgdpds ${ST4file}.gb2

  if [ $region = conus ]; then
      
    #####################################################################
    #    Process PRECIP URMA FOR AWIPS
    #    Files for AWIPS are named locally as 
    #      grib2.${day}.t${hh}z.awpurmapcp.[184/188/ak/pr].$ac
    #    When sent to $pcom, they are renamed on $pcom as
    #      grib2.t${hh}z.awpurmapcp.[184/188/ak/pr].$ac
    #    Because we process multiple days' of precip URMA files, and we
    #    found in Oct 2017 that when two different days' of files (e.g. 
    #    day1 and day2) for the same t${hh}z are made in one cycle,
    #    if we reuse the same file name in the working directory 
    #    and if the file for day1 is larger than the file for day2, the
    #    day2 file will assume the file size of the previously written
    #    day1 file (the day2 file would be a fully functional GRIB2 file,
    #    but its size (ls -l) will be different from what's indicated in
    #    the WMO header. 
    #
    # 2018/06/28: 
    # Starting in v2.7.0: send pcpurma files with WMO headers to 
    #   $COMOUT/${RUN}.$day0/wmo/ instead of PCOM
    # 
    #####################################################################

    hh=`echo $date | cut -c 9-10`
    # Process the G184:
    export pgm=tocgrib2
    . prep_step
    export FORT11="$urma184"
    export FORT31=" "
    export FORT51="grib2.${day}.t${hh}z.awpurmapcp.184.$ac"
    startmsg
    $TOCGRIB2 < $PARMurma/$wmohdrconus
    export err=$?;err_chk
    echo '     err=' $? 

    # Process the G188:
    export pgm=tocgrib2
    . prep_step
    export FORT11="$urma188"
    export FORT31=" "
    export FORT51="grib2.$day.t${hh}z.awpurmapcp.188.$ac"
    startmsg
    $TOCGRIB2 < $PARMurma/$wmohdrnwrfc
    export err=$?;err_chk
    echo '     err=' $? 

  else # PR or AK
    $COPYGB2 -g "$NDFDgrid" -i3 -x ${ST4file}.gb2 $urmafile
    #####################################################################
    #    Process PRECIP URMA FOR AWIPS
    #####################################################################

    hh=`echo $date | cut -c 9-10`
    # add WMO header:
    export pgm=tocgrib2
    . prep_step
    export FORT11="$urmafile"
    export FORT31=" "
    export FORT51="grib2.$day.t${hh}z.awpurmapcp.$region.$ac"
    startmsg
    $TOCGRIB2 < $PARMurma/$wmoheader
    export err=$?; echo "After $pgm, err=$err"; err_chk
  fi

  if test $SENDCOM = 'YES'
  then
    if [ $region = conus ]
    then
      # urmamask was already moved to $COMOUT/$RUN.$day/ 
      #   in ush/urma_sat_mrms_fill.sh.  $urmawexp was not yet moved to $COMOUT
      #   in ush/urma_sat_mrms_fill.sh becuase we needed it in this script to
      #   create the urma184/urma188 files.  
      cp $urmawexp $COMOUT/${RUN}.$day/.
      cp $urma184 $COMOUT/${RUN}.$day/.
      cp $urma188 $COMOUT/${RUN}.$day/.
      cp grib2.$day.t${hh}z.awpurmapcp.184.$ac $COMOUT/${RUN}.$day/wmo/grib2.t${hh}z.awpurmapcp.184.$ac
      cp grib2.$day.t${hh}z.awpurmapcp.188.$ac $COMOUT/${RUN}.$day/wmo/grib2.t${hh}z.awpurmapcp.188.$ac
    else
      cp $urmafile $COMOUT/${RUN}.$day/.
      cp grib2.$day.t${hh}z.awpurmapcp.$region.$ac $COMOUT/${RUN}.$day/wmo/grib2.t${hh}z.awpurmapcp.$region.$ac
    fi # ConUS or OConUS?
  fi   # SENDCOM?

  if test $SENDDBN = 'YES'
  then
    if [ $region = conus ]; then
      # SEND URMA precip files to nomads.ncep.noaa.gov.  Note that ConUS
      # urmamask file is not made for valid hours < 24 (offshore filling not
      # for valid times of less than one day from the present, since CMORPH
      # has a ~19 hour lag time; and full ConUS coverage has an up to 26h lag.

      urmamask=`echo $urmawexp | sed -s 's/wexp/mask/'`
      $DBNROOT/bin/dbn_alert MODEL URMA2P5PCP_GB2 $job $COMOUT/${RUN}.$day/$urmawexp
      if [ -s $COMOUT/${RUN}.$day/$urmamask ]; then 
        $DBNROOT/bin/dbn_alert MODEL URMA2P5PCP_GB2 $job $COMOUT/${RUN}.$day/$urmamask
      fi
    else
      $DBNROOT/bin/dbn_alert MODEL URMAOCONUSPCP_GB2 $job $COMOUT/${RUN}.$day/$urmafile
    fi # ConUS or OConUS?
  fi   # SENDDBN?

# to TOC/AWIPS:
  if test $SENDDBN_NTC = 'YES'
  then
    if [ $region = conus ]; then
      $DBNROOT/bin/dbn_alert GRIB_LOW $NET $job $COMOUT/${RUN}.$day/wmo/grib2.t${hh}z.awpurmapcp.184.$ac
      $DBNROOT/bin/dbn_alert GRIB_LOW $NET $job $COMOUT/${RUN}.$day/wmo/grib2.t${hh}z.awpurmapcp.188.$ac
    else
      $DBNROOT/bin/dbn_alert GRIB_LOW $NET $job $COMOUT/${RUN}.$day/wmo/grib2.t${hh}z.awpurmapcp.$region.$ac
    fi # ConUS or OConUS?
  fi   # SENDDBN_NTC?

done # for each item in this cycle's todo_urma list

if [ $RUN_ENVIR = dev ]; then   # for developers
  $HOMEurma/util.dev/run_python_plts.ksh 
  bsub < $HOMEurma/util.dev/send2rzdm.ksh
fi

#####################################################################
# GOOD RUN
postmsg $jlogfile "$0 completed normally"
#####################################################################

############## END OF SCRIPT #######################

