     program change2wmoheader
!
!  Change grib2 messages to allow $TOCGRIB2 to work for AWIPS 
!
      use grib_mod
      use params
      real, allocatable :: urma(:)
      integer maxgrd
      integer ipd1,ipd2,ipd10,ipd11,ipd12
      integer jskp,jdisc,jpdtn,jgdtn,idisc,ipdtn,igdtn
      integer,dimension(200) :: jids,jpdt,jgdt,iids,ipdt,igdt
      common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

      type(gribfield) :: gfldo
      integer :: currlen=0
      logical :: unpack=.true.
      logical :: expand=.false.

      logical :: first=.true.

!  READ IN the urma file
     call baopenr(11,'fort.11',ier11)
     ierrs = ier11
     if (ierrs.eq.0) then

! find grib message

      iids=-9999;ipdt=-9999; igdt=-9999
      idisc=-1;  ipdtn=-1;   igdtn=-1
      call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
      call getgb2(11,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,&
                  unpack,jskp,gfldo,iret)
       if (iret.eq.0) then
          maxgrd=gfldo%ngrdpts
          print *, 'maxgrd=', maxgrd
! Allocate arrays if this is the first call:
       
         allocate(urma(maxgrd))
         urma(1:maxgrd) = gfldo%fld(1:maxgrd)
         call printinfr(gfldo,1)
       else
        write(6,*) 'GETGB PROBLEM FOR URMA DATA: IRET=',iret
        stop 2
       endif
     else
         write(6,*) 'GRIB:BAOPEN ERR FOR DATA '
         write(6,*) 'PLEASE CHECK DATA AVAILABLE OR NOT'
         stop 1
     endif

!       call gf_free(gfldo)
!       call baclose(11,ier11)

!   change grib2 pdt message for new WMO/awips products

     gfldo%idsect(3)=2
     gfldo%idsect(4)=1
     gfldo%ipdtnum=8
     gfldo%ipdtlen=30
     gfldo%ipdtmpl(1)=1      ! Parameter category : 1 Moisture
     gfldo%ipdtmpl(2)=8      ! Parameter number : 8 Total Precipitation(APCP)
     gfldo%ipdtmpl(10)=1 
     gfldo%ipdtmpl(11)=0 
     gfldo%ipdtmpl(12)=0 
     gfldo%ipdtmpl(13)=255 
     gfldo%ipdtmpl(14)=0 
     gfldo%ipdtmpl(15)=0
     gfldo%ipdtmpl(23)=255
     gfldo%ipdtmpl(24)=1 

     call baopenw(51,'fort.51',ier51)
     gfldo%fld(1:maxgrd)= urma(1:maxgrd) 
     call printinfr(gfldo,1)
     call putgb2(51,gfldo,iret)

     call baclose(51,iret)

     stop
     end

