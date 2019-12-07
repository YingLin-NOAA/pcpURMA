        program blending_map_mpi

!   prgmmr: pondeca           org: np23                date: 2012-xx-xx
!
! abstract: compute 2d-blending map used to merge two fields together 
!           used for example to "regularize" a hrrr field in rtma
!           by merging it with a rap field. the latter fills around
!           the edges of the rtma domain where the hrrr is undefined.
!           the acual merging can use a Whittaker blending function
!           or any other suitible function. 
!
! program history log:
!   2019-08-07  pondeca - add mpi capability


        use mpi

        implicit none

        real(4),parameter:: rbitmap=1.e+18   !0.9999000261E+21
        real(4),parameter:: spval=-9999.     !in output file, represents bitmap point
        real(4),parameter:: spval2=1.e10     !in output file, represents deep interior point free of bitmap

        integer(4) nx,ny,ijdel
        integer(4) mype,npe,ierror

        integer(4) i,j,i1,i2,j1,j2,ii,jj,ij
        integer(4) imin,imax,jmin,jmax

        real(4),allocatable,dimension(:,:)::field,rout,rout2
        real(4) rr,rmin,rmax

        logical fexist

        namelist/domain_conf/nx,ny,ijdel


! MPI setup
        call mpi_init(ierror)
        call mpi_comm_size(mpi_comm_world,npe,ierror)
        call mpi_comm_rank(mpi_comm_world,mype,ierror)
    
!
        print*,'mype,npe=',mype,npe

        inquire(file='domain_conf_input',exist=fexist)
        if (fexist) then
           open (55,file='domain_conf_input',form='formatted')
           read(55,domain_conf)
           close(55)
           if (mype==0) print*,'nx,ny,ijdel=',nx,ny,ijdel
        else
           if (mype==0) print*,'missing file domain_conf_input, ...  aborting'
           stop
           call mpi_finalize(ierror)
        endif
            
        allocate(field(nx,ny))
        allocate(rout(nx,ny))
        allocate(rout2(nx,ny))

        open (10,file='TMP.dat',form='unformatted')
        read(10) field
        close(10)

        if (mype==0) print*,'field,min,max=',minval(field),maxval(field)

        rout(:,:)=0.
        ij=0
        do j=1,ny
        do i=1,nx
           ij=ij+1
           if (mype==mod(ij-1,npe)) then
              if (field(i,j) < rbitmap) then
                 j1=max(1,j-ijdel) ; j2=min(ny,j+ijdel)
                 i1=max(1,i-ijdel) ; i2=min(nx,i+ijdel)
                 rout(i,j)=spval2
                 rmin=huge(rmin)
                 do jj=j1,j2
                 do ii=i1,i2
                    if (field(ii,jj) > rbitmap ) then
                      rr=float((ii-i)*(ii-i)+(jj-j)*(jj-j))
!                     if (rr > 0.) rr=sqrt(rr)
                      rr=sqrt(rr)
                      rmin=min(rmin,rr)
                      rout(i,j)=rmin
                    endif
                 enddo
                 enddo
              endif
           endif
        enddo
        enddo

        rout2(:,:)=0.
        call mpi_allreduce(rout,rout2,nx*ny,mpi_real4,mpi_sum,mpi_comm_world,ierror)

        do j=1,ny
        do i=1,nx
           if (rout2(i,j) == 0.) rout2(i,j)=spval
        enddo
        enddo
        
        if (mype==0) then
           open (20,file='rd2.out',form='unformatted')
           write(20) rout2
           close(20)
        endif
        call mpi_barrier(mpi_comm_world,ierror)

        rmin=+huge(rmin)     
        rmax=-huge(rmax)     
        do j=1,ny
        do i=1,nx
           if (abs(rout2(i,j)-spval) > 1.e-03 .and. abs(rout2(i,j)-spval2) > 1.e-03 ) then
             if (rout2(i,j) < rmin) then 
                rmin=rout2(i,j)
                imin=i
                jmin=j
             endif

             if (rout2(i,j) > rmax) then 
                rmax=rout2(i,j)
                imax=i
                jmax=j
             endif
           endif
        enddo
        enddo
        if (mype==0) then
           print*,'imin,jmin,rmin=',imin,jmin,rmin
           print*,'imax,jmax,rmax=',imax,jmax,rmax
        endif 

        deallocate(field)
        deallocate(rout)
        deallocate(rout2)
        end
