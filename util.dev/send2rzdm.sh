#!/bin/bash
#BSUB -J pcpurma_send2rzdm
#BSUB -P RTMA-T2O
#BSUB -o /gpfs/dell2/ptmp/Ying.Lin/cron.out/send2rzdm_urma.%J
#BSUB -e /gpfs/dell2/ptmp/Ying.Lin/cron.out/send2rzdm_urma.%J
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

COMOUT=/gpfs/dell2/ptmp/Ying.Lin/pcpanl

todosnow=$COMOUT/pcpurma.$day0/todo_snow.$date0
todourma=$COMOUT/pcpanl.$day0/todo_urma.$date0

for item in `cat $todosnow`
do
  vdate=`echo $item | awk -F"." '{print $1}'`
  vday=${vdate:0:8}
  vhr=${vdate:8:2}
  ac=`echo $item | awk -F"." '{print $2}'`
  snowfile=snowfall_wexp.$vdate.$ac.grb2 
  awipsfile=grib2.${vday}.t${vhr}z.snowfall.184.$ac

  RZDMDIR=/home/ftp/emc/mmb/precip/urma.v2.8.0
  ssh wd22yl@emcrzdm "mkdir -p $RZDMDIR/pcpurma.$vday/wmo"
  cd $COMOUT/pcpurma.$vday
  scp $snowfile wd22yl@emcrzdm:$RZDMDIR/pcpurma.$vday/.
  cd $COMOUT/pcpurma.$vday/wmo
  scp $awipsfile wd22yl@emcrzdm:$RZDMDIR/pcpurma.$vday/wmo/.
done

for item in `cat $todourma`
do
  date=`echo $item | cut -c 1-10`
  day=`echo $item | cut -c 1-8`
  acc=`echo $item | cut -c 12-14`
  region=`echo $item | awk -F"." '{print $3}'`
  if [ $region = conus ]; then
    urmafile=pcpurma_wexp.${date}.$acc.grb2
    urmamask=pcpurma_mask.${date}.$acc.grb2
  else
    urmafile=pcpurma_${region}.${date}.$acc.grb2
  fi
    
  RZDMDIR=/home/ftp/emc/mmb/precip/urma.v2.8.0/pcpurma.$day
  ssh wd22yl@emcrzdm "mkdir -p $RZDMDIR"
  cd $COMOUT/pcpurma.$day
  scp $urmafile wd22yl@emcrzdm:$RZDMDIR/.

  # only ConUS files older than 24h has a mask:
  if [[ $region = conus && -s $urmamask ]]; then
    scp $urmamask wd22yl@emcrzdm:$RZDMDIR/.
  fi
done


exit

