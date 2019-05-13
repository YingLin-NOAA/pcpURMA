      program changepds
!
!$$$  MAIN PROGRAM DOCUMENTATION BLOCK
!                .      .    .                                       .
! MAIN PROGRAM: CHANGEPDS changes a GRIB file's Product Definition Section
!  
!   Programmer: Ying lin           ORG: NP22        Date: 2013-09-15
!
! ABSTRACT: Read in a Stage IV analysis, and make the following changes
!   in the PDS:
!   1) change PDS(2) from 182 (NCEP Stage IV) to 118 (URMA)
!   2) If processing Stage IV 6-hourly (as of Sept 2013, we are only going
!      to produce 6-hourly precip URMA; but just in case we'll be doing
!      24h or hourly, we should add the 'if 6-hourly' check), make the 
!      following changes to the time range section.  
!      In Stage IV 6-hourly, following the convention at the RFCs, the
!      'reference time' for the four 6-hourly accumulation periods (12Z-12Z)
!      is the starting time (12Z) for all four periods, and the time ranges
!      for the four are given as 'forecast time (from the beginning 12Z) of
!      00-06, 06-12, 12-18, 18-24h.  This is confusion for those who are
!      not accustomed to the RFC convention.  We are changing this thus:
!      
!      ST4                          Stage IV                   URMA
!      file name             ref time     P1   P2        ref time     P1   P2
!      ---------------------------------------------------------------------
!      ST4.2013091318.06h   2013091312    00   06       2013091312    00   06
!      ST4.2013091400.06h   2013091312    06   12       2013091318    00   06
!      ST4.2013091406.06h   2013091312    12   18       2013091400    00   06
!      ST4.2013091412.06h   2013091312    18   24       2013091406    00   06
!
! Input: 
!        Unit 05: URMA reference time (the time in the Stage4 file name minus
!                 6 hours)
!        Unit 11: Stage IV analysis
!        Unit 51: precip URMA
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
!
      parameter(lmax=1500000)
!
      dimension f(lmax)
      integer ipopt(20), jpds(25), jgds(22), kpds(25), kgds(22)
      logical*1 bit(lmax) 
      integer   idatst4(8), idaturma(8)
      real      rinc(5)
!
      CALL W3TAGB('CHANGEPDS ',2001,0151,0060,'NP22   ')
!
      jpds = -1
      call baopenr(11,"fort.11",ibaret)
      call getgb(11,0,lmax,-1,jpds,jgds,kf,k,kpds,kgds,bit,f,iret)
      write(6,*) 'finished getgb, ibaret, iret=', ibaret, iret
!
      kpds(2)=118
!
!  Change reference time and time ranges if we are processing Stage IV 6-hourly.
!  Verify that the input file is the 6-hourly by checking whether 
!  kpds(15)-kpds(14)=6
      if ( kpds(15)-kpds(14).ne.6) go to 100
!
      idatst4(1)=(kpds(21)-1)*100+kpds(8)
      idatst4(2)=kpds(9)
      idatst4(3)=kpds(10)
      idatst4(5)=kpds(11)
      rinc=0.
      rinc(2)=kpds(14)
      call w3movdat(rinc,idatst4,idaturma)
!
!  Now put the new urma date into KPDS:
!         (8)   - Year of century (2000=100, 2001=1)
      kpds(8)= mod(idaturma(1),100)
      if (kpds(8).eq.0) kpds(8) = 100
!         (9)   - Month of year
      kpds(9)= idaturma(2)
!         (10)  - Day of month
      kpds(10)=idaturma(3)
!         (11)  - Hour of day
      kpds(11)=idaturma(5)
!         (14)  - Time range 1
      kpds(14)=0
!         (15)  - Time range 2
      kpds(15)=6
!
 100  continue
!     
      call baopenw(51,"fort.51",ibaret)
      call putgb(51,kf,kpds,kgds,bit,f,iret)      
      write(6,*) 'finished putgb, ibaret, iret=', ibaret, iret
!
      call baclose(51,ibaret)
      CALL W3TAGE('CHANGEPDS ')
!
      stop
      end
