      program cmorph30min2grb
!$$$  MAIN PROGRAM DOCUMENTATION BLOCK
!                .      .    .                                       .
! MAIN PROGRAM: CMORPH30MIN2GRB
!   Read in a 30-min/8km deg CMORPH file, convert it to GRIB2 hourly. 
!
! The file in /dcom/us007003/20170817/wgrbbul/cpc_rcdas/
!   CMORPH_8KM-30MIN_2017081715
!   contains two half-hourly cmorph estimates (though in the unit of hourly
!   rates, i.e. mm/hr).  Take the average of the two to arrive at hourly
!   accumulation ending at 2017081716 (i.e. 1 hour after the hour in the
!   file name.  
!
! From Bob Joyce, 2017/09/18:
!   1 byte can only store 256 unique values ... in CMORPH valid precipitation 
!   rates are stored in the range 0-250 scaled by 0.2 ... 255 is the missing 
!   value ... in FORTRAN the data should be read as char*1 ... then use the 
!   ichar function to convert to integer*4 
!    
! From PingPing Xie, 2013/06/05:
!   CMORPH is for half hourly precipitation. However, the output files, for 
!   historical reason, are hourly. So, inside each hourly file, there are 
!   precipitation fields for two half-hourly periods. Inside a file with hourly
!   tag of HH='00', the first field is for the mean precipitation from 
!   00hour00min to 00hour30min, the second for 00hour30min to 01hour00min. 
!
!   Please also note, the unit for the precipitation field is mm/hr, despite 
!   the hourly hourly time period. So if you want to get the hourly mean from 
!   the two half hourly values, you should take an average R=(R1+R2)/2. 
!
!   covering 00-23:55UTC).  Make 12Z-12Z sum.  Convert from binary to GRIB.
!  
! Missing data in binary file denoted by a value of -9999.
!
! PROGRAM HISTORY LOG:
!   2017/08/24  YING LIN program based on the bin-to-grb conversion code for
!     in verf_precip/nam_cmorph2grb.fd
!
! USAGE:
!   INPUT FILES:
!     fort.05 - $datep1h (e.g. 2017081716 - need this for date info in grib 
!                                          header)
!     fort.11 - grib2 table
!     fort.12 - CMORPH_025DEG-30MIN_$date (e.g. 2017081715)
!     fort.51 - cmorph.$datep1h.01h.grb1
!
!   SUBPROGRAMS CALLED: 
!     LIBRARY:  BAOPEN PUTGB W3TAGB  W3TAGE
!
!   EXIT STATES:
!     COND =   0 - SUCCESSFUL RUN
!          =  98 - UNEXPECTED END-OF-FILE ON UNIT 11
! 
! ATTRIBUTES:
!   LANGUAGE:  FORTRAN 90
!   MACHINE:   IBM SP
!
!$$$
!
      parameter(nx=4948,ny=1649)
! Co-ord of 'lower-left corner' [i.e. (1,480) point]:
      parameter(alat1=-59.963614, alon1=0.036378335,                          &
     &   deltlon=0.072756669, deltlat=0.072771377)
!  xpnmcaf, ypnmcaf - location of pole.
!  xmeshl - grid mesh length at 60N in km
!  orient - the orientation west longitude of the grid.
!
      dimension KPDS(25),KGDS(22)
      character*1 cmchar1(nx,ny),cmchar2(nx,ny),dum1(nx,ny),dum2(nx,ny)
      character varnam*19, vdate*10
      integer*4 half1, half2
      integer iptable(13)
      real cmorph(nx,ny)
      logical*1 bitmap(nx,ny)
!
      CALL W3TAGB('CMORPH2GRB',1998,0313,0072,'NP2    ')                  
!--------------------------------------------------------------------
!    
!  Compute the (lat,lon) of upper-right corner of the domain:
!
      alon2=alon1 + (nx-1)*deltlon
      alat2=alat1 + (ny-1)*deltlat
      write(6,*) 'alon2, alat2=', alon2, alat2
!
      nerr=0
      read(5,'(a10)',err=101) vdate
!
!  Read in GRIB2 table to APCP:
      do k = 1, 42
        read(11,*)
      end do
      read (11,*) varnam, (iptable(i),i=1,13)
      open(12,access='direct',recl=nx*ny*3,form='unformatted')
!
      read(12,rec=1,err=102) cmchar1, dum1, dum2
      read(12,rec=2,err=103) cmchar2, dum1, dum2
!
!      write(6,*) 'cmchar1(1,1)=', cmchar1(1,1)
!      write(6,*) 'ichar(cmchar1(1,1))=', ichar(cmchar1(1,1))
      do jrev = ny, 1, -1
      do i = 1, nx
!        length1=len_trim(cmchar1(i,jrev))
!        length2=len_trim(cmchar2(i,jrev))
!        if (length1 .ne. 0 .or. length1 .ne. 0) then
!          write(52,98) i, jrev, length1, length2,                         &
!     &    cmchar1(i,jrev), cmchar2(i,jrev)
!        endif
 98     format(i4,2x,i4,3x,i2,1x,i2,4x,a8,2x,a8)
        j=ny-jrev+1
        ihalf1=ichar(cmchar1(i,jrev))
        ihalf2=ichar(cmchar2(i,jrev))
        write(52,99) i, jrev, ihalf1, ihalf2
 99     format(i4,2x,i4,7x,i3,2x,i3)
!
        if (ihalf1 .eq. 255 .or. ihalf2 .eq. 255) then
          bitmap(i,j)=.false.   
        else
          cmorph(i,j) = (ihalf1+ihalf2)*0.1
          bitmap(i,j)=.true.
        endif
      enddo
      enddo

      go to 10
 101  write(6,*) 'Error reading yyyymmddhh from Unit 5'
      nerr=nerr+1
      go to 999
 102  write(6,*) 'Error reading 1st 30 min of cmorph'
      nerr=nerr+1
 103  write(6,*) 'Error reading 2nd 30 min of cmorph'
      nerr=nerr+1
      go to 999
!
 10   continue ! Read successful.  Go on to GRIB'ing.
!
      KPDS(1) =7     ! Generating center: NCEP
      KPDS(2) =0     ! Generating Process: no number defined in grib manual
      KPDS(3) =255   ! Grid definition: undefined 
      KPDS(4) =192   ! GDS/BMS flag (right adj copy of octet 8)
      KPDS(5) =61    ! Parameter type
      KPDS(6) =1     ! Type of level
      KPDS(7) =0     ! Height/pressure , etc of level
      KPDS(8) =mod(iyear-1,100)+1  ! 2-digit year
      KPDS(9) =imn   ! Month
      KPDS(10)=idy   ! Day
      KPDS(11)=ihr   ! Hour
      KPDS(12)=0     ! Minute
      KPDS(13)=1     ! Indicator of forecast time unit
      KPDS(14)=0     ! Time range 1
      KPDS(15)=1     ! Time range 2 (time interval)
      KPDS(16)=4     ! Time range flag
      KPDS(17)=0     ! Number included in average
      KPDS(18)=1     ! Version nr of grib specification
      KPDS(19)=2     ! Version nr of parameter table
      KPDS(20)=0     ! NR missing from average/accumulation
      KPDS(21)=(iyear-1)/100 + 1 ! Centery
      KPDS(22)=2     ! Units decimal scale factor
      KPDS(23)=4     ! Subcenter number (EMC)
      KPDS(24)=0     ! PDS byte 29, for nmc ensemble products
      KPDS(25)=0     ! PDS byte 30, not used
!
      KGDS(1)= 0     ! Data representation type (lat/lon)
      KGDS(2)= nx    ! Number of points on latitude circle
      KGDS(3)= ny    ! Number of points on longitude meridian
      KGDS(4)= 1000.*alat1 ! latitude of origin
      KGDS(5)= 1000.*alon1 ! Longitude of origin
      KGDS(6)= 128     ! Resolution flag (right adj copy of octet 17)
      KGDS(7)= 1000.*alat2   ! latitude of extreme point
      KGDS(8)= 1000.*alon2  ! longitude of extreme point
      KGDS(9)= 1000.*deltlon ! longitudinal direction of increment
      KGDS(10)= 1000.*deltlat ! latitudinal direction of increment
      KGDS(11)= 64           ! scanning mode flag (right adj copy of octet 28)
      KGDS(12)= 0
      KGDS(13)= 0
      KGDS(14)= 0
      KGDS(15)= 0
      KGDS(16)= 0
      KGDS(17)= 0
      KGDS(18)= 0
      KGDS(19)= 0
      KGDS(20)= 255
      KGDS(21)= 0
      KGDS(22)= 0
!
!  Output GRIB version of the CMORPH analysis, if there hasn't been any
!  read error(s)
!
      call baopen(51,'fort.51',iretba)
      write(6,*) 'check 5, vdate=', vdate
      call grib2_wrt_g2func(cmorph,bitmap,vdate,1.,iptable,51,iret)
      write(6,*) 'PUTGB to unit 51, iret=', iret,' iretba=', iretba
      stop
!
 999  continue  ! error exit
!
      end
