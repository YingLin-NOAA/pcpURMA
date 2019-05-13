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

# for userdev, bsub'd by PCPURMA.lsf after jobs/JNAM_PCPN_ANAL to 
# send ST4 and URMA files to rzdm.

# The job is submitted at the end of the PCPURMA job to the transfer queue,
# so it doesn't have a way to directly 'inherit' the run hour (pdyhh) from 
# the Stage II/IV job for which the transfer is to be done.  If the Stage II/IV
# job took too long - a risk especially for the 12Z run, which for 18 Dec 2014
# finished at 12:57Z - this script might not get submitted until after the top
# of the next hour.  So check for the current minute: if it's less than '33',
# subtract one hour from $date0.
# to be submitted to the transfer queue.  If the Stage II/IV

# So that we can quickly find our place in the output:
echo Actual output starts here:

RUN=pcpurma

if [ $# -eq 1 ]; then
  date0=$1
else                      
  date0=`date -u +%Y%m%d%H`
  minute=`date +%M`
  if [ $minute -lt 33 ]; then
    date0=`$NDATE -1 $date0`
  fi
fi
hr0=`echo $date0 | cut -c 9-10`

COMOUTurma=/gpfs/dell2/ptmp/Ying.Lin/pcpanl
COMOUTpcpanl=/gpfs/dell2/ptmp/Ying.Lin/pcpanl

day0=`echo $date0 | cut -c 1-8`
hr0=`echo $date0 | cut -c 9-10`
todourma=$COMOUTpcpanl/pcpanl.$day0/todo_urma.$date0

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
    
  RZDMDIR=/home/ftp/emc/mmb/precip/pcpanl-urma.dell/pcpurma.$day
  ssh wd22yl@emcrzdm "mkdir -p $RZDMDIR"
  cd $COMOUTurma/${RUN}.$day
  scp $urmafile wd22yl@emcrzdm:$RZDMDIR/.

  # only ConUS files older than 24h has a mask:
  if [[ $region = conus && -s $urmamask ]]; then
    scp $urmamask wd22yl@emcrzdm:$RZDMDIR/.
  fi

done

exit

