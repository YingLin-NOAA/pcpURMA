     PROGRAM SAT_MRMS_FILL
!
!  Read in the precip URMA, MRMS and CMORPH data on wexp, and fill the URMA
!  grid with 1) MRMS and 2) CMORPH (in that order) if either
!    a) the grid point is outside of any of the RFC's domains (< 150 or > 162),
!  or
!    b) the point has no coverage from Stage IV
!  Also output an gridmask file that has the values of
!     - RFC id, if the value is from pcpanl (including hourlies in NW/CN RFCs)
!     - 99, if filled with MRMS
!     - 98, if filled with CMORPH
!     -  0, if no valid value
!
     use wgrib2api

     parameter(itest=156, jtest=318)
     real, allocatable :: grid(:,:), rfcmask(:,:), mrms(:,:), cmorph(:,:), urmaold(:,:), urmanew(:,:), urmamrms(:,:)
     real(4),allocatable,dimension(:,:)::rd2
     character (len=200) :: inv, desc(12:14), metadata
     character (len=7) :: fortdxx, template
     real(4) dmax         !the prescribed width of the blend zone in grid units for the slab
     data dmax/50./
     logical*1 mexist, cexist
!
     cexist=.true.
     mexist=.true.

     inv = '@mem:0'

     fortdxx(1:5)='fort.'

     do iunit=11,14
       write(*,*) 'iunit=', iunit
       write(fortdxx(6:7),'(i2.0)') iunit
!      make inv file, save in memory file #0
       iret = grb2_mk_inv(fortdxx, inv)
       write(*,*) 'iret=', iret
       if (iret.ne.0.and.iunit==11) stop 1
       if (iret.ne.0.and.iunit==12) stop 1
       if (iret.ne.0.and.iunit==13) mexist=.false.
       if (iret.ne.0.and.iunit==14) cexist=.false.

       iret = grb2_inq(fortdxx,inv,nx=nx,ny=ny,data2=grid,desc=desc(iunit),regex=1)
       write(*,*) 'desc=', desc(iunit)
       write(*,*) 'iret=', iret
       if (iret.ne.1) then
         if (iret.eq.0) write(*,*) 'could not find message'
         if (iret.gt.1) write(*,*) 'found multiple messages ', iret
         if (iret.ne.1.and.iunit == 11) stop 2
         if (iret.ne.1.and.iunit == 12) stop 2
       endif
!
! Allocate arrays if this is the first call:
       if (iunit == 11) then
         ALLOCATE(grid(nx,ny), STAT=istat)
         ALLOCATE(rfcmask(nx,ny), STAT=istat)
         ALLOCATE(mrms(nx,ny), STAT=istat)
         ALLOCATE(cmorph(nx,ny), STAT=istat)
         ALLOCATE(urmaold(nx,ny), STAT=istat)
         ALLOCATE(urmanew(nx,ny), STAT=istat)
         ALLOCATE(urmamrms(nx,ny), STAT=istat)
         ALLOCATE(rd2(nx,ny), STAT=istat) 
         rfcmask=grid
       elseif (iunit == 12) then
         urmaold=grid
         template='fort.12'
         metadata=desc(iunit)
       elseif (iunit == 13) then
         if (iret.eq.1) then
          mrms=grid
         else
          mrms=9.999e+20
         endif
       elseif (iunit == 14) then
         if (iret.eq.1) then
          cmorph=grid
         else
          cmorph=9.999e+20
         endif
       endif
     enddo

     do j = 1, ny
     do i = 1, nx
       if (rfcmask(i,j).ge.150 .and. rfcmask(i,j).le.162 .and.                 &
           urmaold(i,j).lt.1000.) then
         urmanew(i,j)=urmaold(i,j)
         urmamrms(i,j)=urmaold(i,j)
       elseif ( mrms(i,j).lt.1000.) then
         urmanew(i,j)=mrms(i,j)
         urmamrms(i,j)=mrms(i,j)
       elseif ( cmorph(i,j).lt.1000.) then
         urmanew(i,j)=cmorph(i,j)
       else
         urmanew(i,j)=9.999e+20
         urmamrms(i,j)=9.999e+20
       endif
     enddo
     enddo

     if (mexist .eq. .false. .and. cexist .eq. .true.) urmamrms =urmaold
     if (mexist .eq. .false. .and. cexist .eq. .false.) urmanew =urmaold

!    if CMORPH exists
     if (cexist .eq. .true.) then  
! Read in fixed blending map for CMORPH and MRMS:
     open (48,file='rd2.out_blend_wexp',form='unformatted')    
     read(48) rd2
     close(48)
! Smoother Offshore Filling of the PCPURMA Field
     call blend03_qpe(cmorph,urmamrms,rd2,dmax,nx,ny)

     do j = 1, ny
     do i = 1, nx
        urmanew(i,j)=cmorph(i,j)
     enddo
     enddo

     endif

     iret = grb2_wrt('fort.51','fort.12',1,data2=urmanew,meta=metadata)
     write(*,*) 'Write out filled URMA: iret=', iret

     DEALLOCATE(grid)
     DEALLOCATE(rfcmask)
     DEALLOCATE(mrms)
     DEALLOCATE(cmorph)
     DEALLOCATE(urmaold)
     DEALLOCATE(urmanew)
     DEALLOCATE(urmamrms)
     DEALLOCATE(rd2)
     stop
     end

!=======================================================================
!***********************************************************************
     subroutine blend03_qpe(field1,field2,rd2,dmax0,nx,ny)

     use pbend
    
     implicit none

!Declare passed variables
     integer(4),intent(in)  ::nx,ny
     real(4),intent(inout)::field1(nx,ny)
     real(4),intent(in)   ::field2(nx,ny)
     real(4),intent(in)   ::rd2(nx,ny)
     real(4),intent(in)   ::dmax0

!Declare local parameters
     real(4),parameter::spval=-9999.
     real(4),parameter::spval2=1.e10
     real(4),parameter::epsilon=1.e-3
  
!Declare local variables
     real(4),allocatable,dimension(:,:):: fldaux
     real(4) diff,diff2
     real(4) rmin,rmax
     real(8) x,alpha        !double precision
     integer(4) i,j,n

     print*
     print*,'==================================================================='
     print*,'in blend03_qpe: spval,spval2=',spval,spval2
     print*,'in blend03_qpe: dmax0=',dmax0 ; print*

     call rminmax_excludespval(field2,nx,ny,1.e19,rmin,rmax)
     print*,'in blend03_qpe: field2,min,max=',rmin,rmax

     call rminmax_excludespval(field1,nx,ny,1.e19,rmin,rmax)
     print*,'in blend03_qpe: before blending  field1,min,max=',rmin,rmax

     allocate(fldaux(nx,ny))        
     do j=1,ny
     do i=1,nx
        diff=abs(rd2(i,j)-spval)
        diff2=abs(rd2(i,j)-spval2)

        if (diff  < epsilon) fldaux(i,j)=field1(i,j)
        if (diff2 < epsilon) fldaux(i,j)=field2(i,j)

        if (diff >= epsilon  .and. diff2  >= epsilon ) then
           if (field1(i,j) == 9.999e+20 .and. field2(i,j) /= 9.999e+20 ) then
              fldaux(i,j)=field2(i,j)
           elseif (field1(i,j) /= 9.999e+20 .and. field2(i,j) == 9.999e+20 ) then
              fldaux(i,j)=field1(i,j)
           elseif (field1(i,j) == 9.999e+20 .and. field2(i,j) == 9.999e+20 ) then
              fldaux(i,j)=9.999e+20
           elseif (field1(i,j) /= 9.999e+20 .and. field2(i,j) /= 9.999e+20 ) then
            x=min(1.,rd2(i,j)/dmax0)
            call wbend(x,alpha)
            fldaux(i,j)=alpha*field2(i,j)+(1.-alpha)*field1(i,j)
           endif
!             if ( fldaux(i,j) > 1.e10 ) then
!             print*, 'i,j,fldaux(i,j)=',i,j,fldaux(i,j)
!             endif


        endif
!        if ( rd2(i,j) == -9999.0 .and. fldaux(i,j) > 0.0 ) then
!        if ( rd2(i,j) >= 1.e10 .and. fldaux(i,j) > 0.0 ) then
!           print*, 'i,j,fldaux(i,j)=',i,j,fldaux(i,j)
!        endif

     enddo
     enddo
  
     do j=1,ny
     do i=1,nx
        field1(i,j)=fldaux(i,j)
     enddo
     enddo

     deallocate(fldaux)

     call rminmax_excludespval(field1,nx,ny,1.e19,rmin,rmax)
     print*,'in blend03_qpe: after blending  field1,min,max=',rmin,rmax ; print*

     end subroutine blend03_qpe

!=======================================================================
!=======================================================================
     subroutine rminmax_excludespval(field,nx,ny,spval,rmin,rmax)

     implicit none

     integer(4),intent(in)::nx,ny
     real(4),intent(in)::spval
     real(4),intent(in)::field(nx,ny)
     real(4),intent(out)::rmin,rmax

     integer(4) i,j

     rmin=+huge(rmin)
     rmax=-huge(rmax)
     do j=1,ny
     do i=1,nx
        if (field(i,j) < spval ) then
           if (field(i,j) < rmin) rmin=field(i,j)
           if (field(i,j) > rmax) rmax=field(i,j)
        endif
     enddo
     enddo

     end subroutine rminmax_excludespval

