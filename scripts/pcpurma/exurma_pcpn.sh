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
# For wgrib2's new_grid: 

WG2wexp="lambert:265:25:25 233.723448:2345:2539.703 19.228976:1597:2539.703"
WG2ak="nps:210.0:60.0 181.429:1649:2976.0 40.530:1105:2976.0"
WG2pr="mercator:20.00 291.804700:353:1250.0:296.015500 16.828700:257:1250.0:19.736200"
WG2pack="c1 -set_bitmap 1"

# Prepare CMORPH and MRMS data for URMA:
$USHurma/urma_prep_sat_mrms.sh

cp $COMINpcpanl/pcpanl.$day0/todo_urma.$date0 .

for item in `cat todo_urma.$date0`
do 
  date=`echo $item | cut -c1-10`
  day=`echo $item | cut -c1-8`
  ac=`echo $item | awk -F"." '{print $2}'`
  region=`echo $item | awk -F"." '{print $3}'`

  st4file=st4_${region}.$date.$ac.grb2
  if [ $region = conus ]; then
    urmawexp=pcpurma_wexp.$date.$ac.grb2
    urma184=pcpurma_g184.$date.$ac.grb2
    urma188=pcpurma_g188.$date.$ac.grb2
  else
    urmafile=pcpurma_${region}.$date.$ac.grb2
  fi

  cp $COMINpcpanl/pcpanl.$day/$st4file .
  err=$?
  if [ $err -ne 0 ]; then
    echo $st4file does not exist.  Skip this for URMA.
    break
  fi

  if [ $region = conus ]; then
    # map to the 2.5km 2345x1597 west-expanded ConUS grid (wexp)
    $WGRIB2 $st4file \
      -set_grib_type ${WG2pack} \
      -set analysis_or_forecast_process_id 118 \
      -new_grid_winds grid \
      -new_grid_interpolation budget \
      -new_grid ${WG2wexp} \
      $urmawexp

    # If valid time is at least 24h ago, fill in with MRMS and CMORPH:
    if [ $date -le $date0m24h ]
    then
      $USHurma/urma_sat_mrms_fill.sh $date $ac $urmawexp
    fi

    # Use wgrib2 to produce NDFD subsets (g184 and g188) from the large wexp 
    # grid for AWIPS.
    #   g184(i,j) = wexp(i+200,j)
    #   g188(i,j) = wexp(i+200,j+802)
    # 
    #   g184(1,1) = wexp(201,1)
    #   g184(2145,1377) = wexp(2345,1377)
    # 
    #   g188(1,1) = wexp(201,803)
    #   g188(709,795) = wexp(909,1597)

    $WGRIB2 $urmawexp -ijsmall_grib 201:2345 1:1377  $urma184
    wmohdrconus=grib2_pcpurma_g184.$ac

    # Map to 2.5km NWRFC NDFD grid:
    $WGRIB2 $urmawexp -ijsmall_grib 201:909 803:1597 $urma188 
    wmohdrnwrfc=grib2_pcpurma_g188.$ac

  elif [ $region = pr ]; then
    wmoheader=grib2_pcpurma_prico_125km.$ac
    WG2oconus=$WG2pr
  elif [ $region = ak ]; then
    # AK URMA is 06h only, but use $ac, (in case there's a script error, '01h' 
    # would be a tip-off)
    wmoheader=grib2_pcpurma_g91.$ac
    WG2oconus=$WG2ak
  fi # ConUS, PR or AK?

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
#    $TOCGRIB2 < $PARMurma/$wmohdrconus
    export err=$?;err_chk
    echo '     err=' $? 

    # Process the G188:
    export pgm=tocgrib2
    . prep_step
    export FORT11="$urma188"
    export FORT31=" "
    export FORT51="grib2.$day.t${hh}z.awpurmapcp.188.$ac"
    startmsg
#    $TOCGRIB2 < $PARMurma/$wmohdrnwrfc
    export err=$?;err_chk
    echo '     err=' $? 

  else # PR or AK
    $WGRIB2 $st4file \
      -set_grib_type ${WG2pack} \
      -set analysis_or_forecast_process_id 118 \
      -new_grid_winds grid \
      -new_grid_interpolation budget \
      -new_grid ${WG2oconus} \
      $urmafile
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
#    $TOCGRIB2 < $PARMurma/$wmoheader
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

