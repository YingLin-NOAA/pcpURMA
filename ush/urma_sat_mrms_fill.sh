#!/bin/ksh
set -x
date=$1
ac=$2
urmafile=$3
mkdir -p $DATA/sat_mrms_fill
cd $DATA/sat_mrms_fill

urmaunfilled=$urmafile.unfilled
cp $DATA/$urmafile $urmaunfilled
urmamask=`echo $urmafile | sed -s 's/wexp/mask/'`

day=${date:0:8}
cp $COMOUT/$RUN.$day/mrms.$date.$ac.wexp .
err1=$?
cp $COMOUT/$RUN.$day/cmorph.$date.$ac.wexp .
err2=$?
cp $COMOUT/$RUN.$day/rd2.out.blend.$date.$ac.wexp.gz .
err3=$?

# Take the ST4 mapped to wexp grid ($urmaunfilled), add 1) MRMS 2) CMORPH:
if [ $err1 = 0 -o $err2 = 0 ]
then

 if [ $err1 = 0 ]; then
  # if MRMS exists
  rm -f sto_* tmp*.grb2

  $WGRIB2 \
  -set_grib_type c1 $urmaunfilled -rpn sto_0 \
  -import_grib $FIXurma/rfcmask_wexp.grb2 \
  -rpn "149:>:rcl_0:swap:mask:sto_1" -grib_out tmp1.grb2 \
  -import_grib mrms.$date.$ac.wexp \
  -rpn "rcl_1:merge:sto_2" -grib_out tmp2.grb2

  cp  tmp2.grb2 blend_wexp.grb2

 else
  # if MRMS doesn't exist
  cp $urmaunfilled blend_wexp.grb2
 fi

 $WGRIB2 -s blend_wexp.grb2 | $WGRIB2 -i blend_wexp.grb2 -ieee slabs_blend.dat

 # Generating a dynamic blending map
 if [ $err3 != 0 ]
 then
  bsub < $USHurma/urma_dynamic_blend_map.sh

  cd $DATA/sat_mrms_fill
    icnt=0
    while [ $icnt -le 90 ]; do

    if [ -f rd2.out ]; then
    cp rd2.out rd2.out_blend_wexp
    err4=$?
    icnt=91
    else
    sleep 10
    icnt=`expr $icnt + 1`
    echo $icnt
    fi
    done  # while [ $icnt -le 90 ]

  if [ $err4 != 0 ]; then
   cp $FIXurma/rd2.out_blend_wexp .
   err4=$?
  fi
 else
  gunzip rd2.out.blend.$date.$ac.wexp.gz
  cp rd2.out.blend.$date.$ac.wexp  rd2.out_blend_wexp
  err4=$?
 fi

  if [ $err4 = 0 ]; then
 # if rd2.out_blend_wexp exists

  ln -sf $FIXurma/rfcmask_wexp.grb2     fort.11
  ln -sf $urmaunfilled                  fort.12
  ln -sf mrms.$date.$ac.wexp            fort.13
  ln -sf cmorph.$date.$ac.wexp          fort.14
  ln -sf $urmafile                      fort.51
  $EXECurma/pcpurma_sat_mrms_fill
  err=$?
  if [ $err = 0 ]; then
# Only copy over the mask and images (if dev) to $COMOUT, since
# $urmafile will be moved by scripts/exurma_pcpn.sh.
    gzip -c rd2.out_blend_wexp > $COMOUT/$RUN.$day/rd2.out.blend.$date.$ac.wexp.gz
    mv $urmafile $DATA/.
  fi
 fi
else
  echo Neither MRMS nor CMORPH for $date $ac exists, no filling is done.
fi # if either the MRMS or CMORPH file exists

# Make a data mask:
if [ $err1 = 0 -a $err2 = 0 ]
then
  # Both MRMS and CMORPH exist
  rm -f sto_* tmp*.grb2
  $WGRIB2 \
  -set_grib_type c1 $urmaunfilled -rpn sto_0 \
  -import_grib $FIXurma/rfcmask_wexp.grb2 \
  -rpn "rcl_0:0:*:+" -grib_out sto_1 \
  -rpn "dup:149:>:mask:dup:163:<:mask:sto_1" -grib_out tmp1.grb2 \
  -import_grib mrms.$date.$ac.wexp \
  -rpn "0:*:99:+:rcl_1:merge:sto_2" -grib_out tmp2.grb2 \
  -import_grib cmorph.$date.$ac.wexp \
  -rpn "0:*:98:+:rcl_2:merge" -set_var "IMGD" -grib_out $urmamask

  # Only copy over the mask to $COMOUT, since
  # $urmafile will be moved by scripts/exurma_pcpn.sh (a step that's taken
  # w/ or w/o the filling)

  cp $urmamask $COMOUT/$RUN.$day/.
  mv $urmamask $DATA/.
elif [ $err1 = 0 -o $err2 = 0 ]
then
  # if only one field exist (either MRMS or CMORPH, but not both):
  if [ $err1 = 0 ]; then
    fillfld=mrms
    masknum=99
  elif [ $err2 = 0 ]; then
    fillfld=cmorph
    masknum=98
  fi

  rm -f sto_* tmp*.grb2
  $WGRIB2 \
  -set_grib_type c1 $urmaunfilled -rpn sto_0 \
  -import_grib $FIXurma/rfcmask_wexp.grb2 \
  -rpn "rcl_0:0:*:+" -grib_out sto_1 \
  -rpn "dup:149:>:mask:dup:163:<:mask:sto_1" -grib_out tmp1.grb2 \
  -import_grib $fillfld.$date.$ac.wexp \
  -rpn "0:*:${masknum}:+:rcl_1:merge" -set_var "IMGD" -grib_out $urmamask

  cp $urmamask $COMOUT/$RUN.$day/.
  mv $urmamask $DATA/.
else
  echo Neither MRMS nor CMORPH for $date $ac exists, no filling is done.
fi # if either the MRMS or CMORPH file exists

exit
