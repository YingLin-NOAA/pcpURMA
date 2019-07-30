#!/bin/sh
# 
# get nohrsc 6h/24h snowfall analysis covering a 12Z-12Z 24h period
# and place them in my simulated 
# dcom/../qpe/
#
set -x
# files at NORHSC:
# https://www.nohrsc.noaa.gov/snowfall/data/201906/
# sfav2_CONUS_24h_2019060912_grid184.grb2  
# sfav2_CONUS_6h_2019060818_grid184.grb2

UTILROOT=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2
FINDDATE=$UTILROOT/ush/finddate.sh

DCOMROOT=/gpfs/dell2/ptmp/Ying.Lin/dcom/prod
NOHRSCDAT=www.nohrsc.noaa.gov/snowfall/data

day=$1
daym1=`$FINDDATE $day d-1`

yyyymm=${day:0:6}
yyyymmm1=${daym1:0:6}

DCOM=/gpfs/dell2/ptmp/Ying.Lin/dcom/prod/$day/wgrbbul/qpe
DCOMm1=/gpfs/dell2/ptmp/Ying.Lin/dcom/prod/$daym1/wgrbbul/qpe

if [ ! -d $DCOM ]; then mkdir -p $DCOM; fi
if [ ! -d $DCOMm1 ]; then mkdir -p $DCOMm1; fi

snow18z6h=sfav2_CONUS_6h_${daym1}18_grid184.grb2
snow00z6h=sfav2_CONUS_6h_${day}00_grid184.grb2
snow06z6h=sfav2_CONUS_6h_${day}06_grid184.grb2
snow12z6h=sfav2_CONUS_6h_${day}12_grid184.grb2
snow12z24h=sfav2_CONUS_24h_${day}12_grid184.grb2

cd $DCOMm1
wget -N $NOHRSCDAT/$yyyymmm1/$snow18z6h
cd $DCOM
wget -N $NOHRSCDAT/$yyyymm/$snow00z6h
wget -N $NOHRSCDAT/$yyyymm/$snow06z6h
wget -N $NOHRSCDAT/$yyyymm/$snow12z6h
wget -N $NOHRSCDAT/$yyyymm/$snow12z24h

exit


