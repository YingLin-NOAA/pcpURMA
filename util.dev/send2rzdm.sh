#!/bin/bash
#BSUB -J pcpurma_send2rzdm
#BSUB -P RTMA-T2O
#BSUB -o /gpfs/dell2/ptmp/Ying.Lin/cron.out/send2rzdm_urma_2p8.%J
#BSUB -e /gpfs/dell2/ptmp/Ying.Lin/cron.out/send2rzdm_urma_2p8.%J
#BSUB -n 1
#BSUB -q "dev_transfer"
#BSUB -W 0:10
#BSUB -R "rusage[mem=300]"
#BSUB -R affinity[core(1)]

set -x

module purge
module load gnu/4.8.5
module load ips/18.0.1.163
module load prod_util/1.1.0

# for userdev, bsub'd by PCPURMA.lsf after completion of pcpurma processing.
# Fow now just send the snowfall file (original nohrsc; and ones with wmo 
#   header for awips.

# So that we can quickly find our place in the output:
echo Actual output starts here:

if [ $# -eq 1 ]; then
  date0=$1
else                      
  date0=`date +%Y%m%d%H`
fi
day0=${date0:0:8}
hr0=${date0:8:2}

COMOUT=/gpfs/dell2/ptmp/Ying.Lin/pcpanl_2p8
todosnow=$COMOUT/pcpurma.$day0/todo_snow.$date0

for item in `cat $todosnow`
do
  vdate=`echo $item | awk -F"." '{print $1}'`
  vday=${vdate:0:8}
  vhr=${vdate:8:2}
  ac=`echo $item | awk -F"." '{print $2}'`
  nohrscfile=sfav2_CONUS_${ac}_${vday}${vhr}_grid184.grb2
  if [ $ac = 6h ]; then
    awipsfile=grib2.${vday}.t${vhr}z.snowfall.184.06h
  else
    awipsfile=grib2.${vday}.t${vhr}z.snowfall.184.24h
  fi

  RZDMDIR=/home/ftp/emc/mmb/precip/urma.v2.8.0
  ssh wd22yl@emcrzdm "mkdir -p $RZDMDIR/pcpurma.$vday/wmo"
  cd $COMOUT/pcpurma.$vday
  scp $nohrscfile wd22yl@emcrzdm:$RZDMDIR/pcpurma.$vday/.
  cd $COMOUT/pcpurma.$vday/wmo
  scp $awipsfile wd22yl@emcrzdm:$RZDMDIR/pcpurma.$vday/wmo/.
done

exit

