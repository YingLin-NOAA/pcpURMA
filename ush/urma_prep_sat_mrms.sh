#!/bin/ksh
set -x
# Prepare CMORPH and MRMS files for URMA:
#
#  1. For date0m60h-date0m19h: 
#     If cmorph file on NDFD grid for this hour does not exist on 
#     pcpurma.$day already:
#     a) Convert the file to GRIB2; copygb2 to NDFD grid
#     b) If the cmorph file needed for date0m24h does not exist on /dcom, email
#        an alert to self
#  2. for date0m60h-date0m19h:
#     If MRMS file for this hour does not already exist (it should have been
#     copied over by pcpanl/ush/pcpn_make_hrlywgts.sh), convert the grib2 
#     file on /dcom to 'normal' APCP format using wgrib2
#       If there has been no down time - e.g. devwcoss down/taken away for 
#       para/prod tests - then this only needs to be done for $date0m19h.  We go
#       back to also check datem60h-datem20h in case there has been an outage.  
#     a) copy over the corresponding Radar Quality Index file for that hour
#        (on the dot; RQI files are every 2 minutes); use the RQI file as 
#        a filter - throw out MRMS grid points where RQI < 0.1.
#     b) Convert the MRMS file to NDFD grid; copygb to NDFD
#  3. Make 6h accumulations of the 'wexp' files for both MRMS and CMORPH, for
#     hour6m60-hour6m18, where hour6 is the nearest divisible-by-six hour
#     before the current hour (not including the current hour), i.e. 
#     for the following run cycles:
#      day 01:33-06:33Z - hour6=00, compute the 6h accumulation for 
#          ${daym2}06-${daym2}12
#          ${daym2}12-${daym2}18
#          ${daym2}18-${daym1}00
#          ${daym1}00-${daym1}06
#      day 07:33-12:33Z - hour6=06, compute the 6h accumulation for 
#          ${daym2}12-${daym2}18
#          ${daym2}18-${daym1}00
#          ${daym1}00-${daym1}06
#          ${daym1}06-${daym1}12
#      day 13:33-18:33Z - hour6=12, compute the 6h accumulation for 
#          ${daym2}18-${daym1}00
#          ${daym1}00-${daym1}06
#          ${daym1}06-${daym1}12
#          ${daym1}12-${daym1}18
#      day 19:33-00:33Z - hour6=18, compute the 6h accumulation for 
#          ${daym1}00-${daym1}06
#          ${daym1}06-${daym1}12
#          ${daym1}12-${daym1}18
#          ${daym1}18-${day}00
#    
# As of Aug 2017, CMORPH has an 18h46min lag; MRMS has a 90-95 min lag.  
# So by the time we check for $date0m19h, MRMS should be there already (if not,
# it's not going to be re-run).  So we're processing MRMS just once, for 
# $date0m19h, while attempting for cmorph for $date0m24h - $date0m19h.

mkdir -p $DATA/prep_sat_mrms
cd $DATA/prep_sat_mrms

# The 2345x1597 west-expanded ConUS grid (wexp):
export NDFDwexp="30 1 0 6371200 0 0 0 0 2345 1597  19228976 233723448 8 25000000 265000000 2539703 2539703 0 64 25000000 25000000 -90000000 0"

# date0 is exported from scripts/exurma_pcpn.sh
datem19h=`$NDATE -19 $date0`
datem60h=`$NDATE -60 $date0`

date=$datem60h
while [ $date -le $datem19h ]
do
  day=${date:0:8}
  hr=${date:8:2}

  if [ ! -s $COMOUT/${RUN}.$day/cmorph.$date.01h.wexp ]; then
    # yyyymmddhh in original cmorph file name is the beginning of the hour that
    # contains the two half-hours.  
    cdate=`$NDATE -1 $date`
    cday=${cdate:0:8}
    cmorphfile=CMORPH_8KM-30MIN_$cdate
    dcomdir=$DCOMROOT/us007003/$cday/wgrbbul/cpc_rcdas
    if [ -s $dcomdir/$cmorphfile ]
    then
      ln -sf $PARMurma/grib2_pds.tbl  fort.11
      ln -sf $dcomdir/$cmorphfile     fort.12
      ln -sf cmorph.$date.01h.grb2    fort.51
      ${EXECurma}/pcpurma_cmorph30min2grb <<ioEOF
$date
ioEOF
      $COPYGB2 -g "$NDFDwexp" -i3 -x cmorph.$date.01h.grb2 \
                                        cmorph.$date.01h.wexp
      cp cmorph.$date.01h.wexp $COMOUT/${RUN}.$day/.

      if [ $RUN_ENVIR = dev ]; then   # for developers
        if [ ! -d $NOSCRUBDIR/$day ]; then 
          mkdir -p $NOSCRUBDIR/$day
        fi

        if [ ! -s $NOSCRUBDIR/$day/cmorph.$date.01h.grb2.gz ]; then
          gzip -c cmorph.$date.01h.grb2 > $NOSCRUBDIR/$day/cmorph.$date.01h.grb2.gz
        fi
      fi  # dev: copy cmorph file to noscrub
    fi
  fi # if cmorph.$date.01h.wexp does not already exist on COMOUT/${RUN}.$day

  # Now process MRMS, for the hour between $datem60h and $datem19h:

  if [ ! -s $COMIN/${RUN}.$day/mrms.$date.01h.wexp ]; then
    # first, find out if an RQI-filtered GC MRMS file is available, if not, 
    # attempt to make one:
    if [ -s $COMIN/${RUN}.$day/mrmsrqid.$date.gz ]; then
      cp $COMIN/${RUN}.$day/mrmsrqid.$date.gz .
      gunzip mrmsrqid.$date.gz
    else
      if [ -s $COMIN/${RUN}.$day/mrms.$date.gz ]; then
        cp $COMIN/${RUN}.$day/mrms.$date.gz .
        gunzip mrms.$date.gz
      else
        rawmrms=GaugeCorr_QPE_01H_00.00_${day}-${hr}0000.grib2
        cp $MRMSDIR/GaugeCorr_QPE/$rawmrms.gz .
        err=$? 
        if [ $err -eq 0 ]; then
          gunzip $rawmrms
          $MYWGRIB2 $rawmrms -rpn "dup:-3:!=:mask" -set_scaling -1 0 -set_bitmap 1 -set_grib_type c3 -grib_out mrms.$date
          gzip -c mrms.$date > $COMOUT/${RUN}.$day/mrms.$date.gz
        fi
      fi # does the pre-RQI'd mrms.$date exist?

      # We normally use the RQI file
      #   RadarQualityIndex_00.00_${day}-${hr}0000.grib2
      # In case the file does not exist, find the one closest to ${hr}0000
      # in the previous hour.
      # list all 
      # file does not exist), use the last one, e.g. the one closest 
      # to {hr}0000.
      #
      # cdate/cday (for cmorph) is from datem1h, so we'll just use that.
      RQI=RadarQualityIndex
      chr=${cdate:8:2}
      # 
      # The command below does the following:
      #   1) list all RQI files from {hrm1}0000 to {hr}0000 
      #   2) find the latest one (which will normally be {hr}0000), unless
      #      that one was missing
      #   3) strip off the directory path and the .gz suffix
      rqifile=`ls -1 $MRMSDIR/$RQI/${RQI}_00.00_${cday}-${chr}*.grib2.gz \
                     $MRMSDIR/$RQI/${RQI}_00.00_${day}-${hr}0000.grib2.gz \
               | tail -1 | awk -F"/"  '{ print $NF }' | sed 's/.gz//'`
      cp $MRMSDIR/RadarQualityIndex/$rqifile.gz .
      cp $rqifile.gz $COMOUT/${RUN}.$day/.
      gunzip $rqifile
      rqierr=$?

      if [ -s mrms.$date -a $rqierr -eq 0 ]; then
        # if the RQI is available, use it to screen out MRMS points where
        # RQI < 0.5:
        $MYWGRIB2 \
        -set_grib_type c1 mrms.$date -rpn sto_0 \
        -set_bitmap 1 -import_grib $rqifile \
        -rpn "0.09:>:rcl_0:swap:mask:sto_1" -grib_out mrmsrqid.$date
        gzip -c mrmsrqid.$date > $COMOUT/${RUN}.$day/mrmsrqid.$date.gz
      fi

      if [ -s mrmsrqid.$date ]; then
        $COPYGB2 -g "$NDFDwexp" -i3 -x mrmsrqid.$date mrms.$date.01h.wexp
      elif [ -s mrms.$date ]; then
        $COPYGB2 -g "$NDFDwexp" -i3 -x mrms.$date mrms.$date.01h.wexp
      fi
    fi
    cp mrms.$date.01h.wexp $COMOUT/${RUN}.$day/.
  fi # if mrms.$date.01h.wexp doesn't already exist
  date=`$NDATE +1 $date`
done # Check for/process cmorph and MRMS files from $datem60h to $datem19h

# Now compute the 6h accumulations, if the 6-hourlies have not been processed 
# already:
  
hr0=${date0:8:2}
day0=${date0:0:8}
day0m1=`finddate.sh $day0 d-1`

if [ $hr0 -ge 01 -a $hr0 -le 06 ]
then
#  hour6=${day0m1}00
   end6h0=${day0m1}06
elif [ $hr0 -ge 07 -a $hr0 -le 12 ]
then
#  hour6=${day0}06
   end6h0=${day0m1}12
elif [ $hr0 -ge 13 -a $hr0 -le 18 ]
then
#  hour6=${day0}12
   end6h0=${day0m1}18
elif [ $hr0 -ge 19 -o $hr0 -eq 00 ]
then
#  hour6=${day0}18
   end6h0=${day0m1}00
fi

# end6h0 is the end of the last 6h period we want to compute 6h sums.  Also 
# compute sums for three earlier 6-hour period, if the sums have not been 
# done earlier (this is checked inside urma_sum_pcp_wexp.sh)
#
end6h=`$NDATE -60 $end6h0`

while [ $end6h -le $end6h0 ]; do
  for anl in cmorph mrms
  do
    $USHurma/urma_sum_pcp_wexp.sh $anl $end6h 06
  done
  end6h=`$NDATE +6 $end6h`
done

exit




