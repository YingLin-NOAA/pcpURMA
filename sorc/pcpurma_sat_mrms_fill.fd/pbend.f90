!
!                                **********************************************
!                                *             MODULE pbend                   *
!                                *  R. J. Purser, NOAA/NCEP/EMC  October 2004 *
!                                *  jim.purser@noaa.gov                       *
!                                *                                            *
!                                **********************************************
!
! Evaluate smooth monotonic increasing blending functions y from 0 to 1
! for x in the interval [0,1]. In the case of the "bend" functions,
! these have continuity in the first {2**nit-1} 
! derivatives at the ends of this interval. (nit .ge. 0). The gradient, dydx,
! achieves its maximum value of (1.5)**nit at mid-interval, about which it is
! symmetric.
! In the case of the "beta" functions, the same symmetry pertains, but the
! rise from 0 at x = 0 goes in proportion to x**n for x << 1.
! Both blending function formulations are built up recursively from those
! of lower orders, which simplifies and stabilizes the codes.
! 
! The mode of incremental construction used for the BETA function of index n
! as a correction to that of order n-1 has its analogues in the area of
! numerical stencils for midpoint interpolation, differencing and 
! quadrature over a centered interval. Such
! stencils are generated in the routines MID, DIF, DDIF, QUAD and SDIF,
! which also remain valid up to exceedingly high orders, n.
!
! DIRECT DEPENDENCIES
! modules:   pietc, pkind
!
!=============================================================================
module pbend
!=============================================================================
!                                   R. J. Purser, NOAA/NCEP/EMC October 2004
!                                                    "beta" added, June 2010   
!=============================================================================
use pkind, only: sp,dp
implicit none
private
public:: bend,beta,abeta,mid,dif,ddif,quad,sdif,iniwhit,wbend
integer,parameter      :: nh=128,n=256
real(dp),dimension(0:n):: whit
real(dp)               :: twhit
logical                :: not_iniwhit
data not_iniwhit/.true./

interface bend;  module procedure sbend,dbend,sbendd,dbendd; end interface
interface beta;  module procedure sbeta,dbeta,sbetad,dbetad; end interface
interface abeta; module procedure abeta;                     end interface
interface mid;   module procedure mid;                       end interface
interface dif;   module procedure dif;                       end interface
interface ddif;  module procedure ddif;                      end interface
interface quad;  module procedure quad;                      end interface
interface sdif;  module procedure sdif;                      end interface

interface iniwhit;    module procedure iniwhit;                  end interface
interface wbend;      module procedure wbend,wbendd,wbenddn;     end interface
interface wd;         module procedure wd;                       end interface
interface ed;         module procedure ed;                       end interface
interface et;         module procedure et;                       end interface
interface abernoulli; module procedure abernoulli;               end interface
interface choose;     module procedure choose;                   end interface
interface fact;       module procedure fact;                     end interface
interface setwhit;    module procedure setwhit;                  end interface

contains

!=============================================================================
subroutine sbend(nit,x,y)!                                              [bend]
!=============================================================================
integer, intent(IN ):: nit
real(SP),intent(IN ):: x
real(SP),intent(OUT):: y
!-----------------------------------------------------------------------------
integer             :: it
!=============================================================================
y=2*x-1;y=max(-1._SP,min(1._SP,y));do it=1,nit; y=y*(3-y*y)/2;enddo; y=(y+1)/2
end subroutine sbend
!=============================================================================
subroutine dbend(nit,x,y)!                                              [bend]
!=============================================================================
integer, intent(IN ):: nit
real(DP),intent(IN ):: x
real(DP),intent(OUT):: y
!-----------------------------------------------------------------------------
integer             :: it
!=============================================================================
y=2*x-1;y=max(-1._DP,min(1._DP,y));do it=1,nit; y=y*(3-y*y)/2;enddo; y=(y+1)/2
end subroutine dbend
!=============================================================================
subroutine sbendd(nit,x,y,dydx)!                                        [bend]
!=============================================================================
integer, intent(IN ):: nit
real(SP),intent(IN ):: x
real(SP),intent(OUT):: y,dydx
!-----------------------------------------------------------------------------
integer             :: it
!=============================================================================
y=2*x-1; dydx=2; y=max(-1._SP,min(1._SP,y)); if(y==1 .or. y==-1)dydx=0
do it=1,nit; dydx=3*dydx*(1-y*y)/2; y=y*(3-y*y)/2;enddo; y=(y+1)/2;dydx=dydx/2
end subroutine sbendd
!=============================================================================
subroutine dbendd(nit,x,y,dydx)!                                        [bend]
!=============================================================================
integer, intent(IN ):: nit
real(DP),intent(IN ):: x
real(DP),intent(OUT):: y,dydx
!-----------------------------------------------------------------------------
integer             :: it
!=============================================================================
y=2*x-1; dydx=2; y=max(-1._DP,min(1._DP,y)); if(y==1 .or. y==-1)dydx=0
do it=1,nit; dydx=3*dydx*(1-y*y)/2; y=y*(3-y*y)/2;enddo; y=(y+1)/2;dydx=dydx/2
end subroutine dbendd

!============================================================================
subroutine sbeta(n,x,y)!                                               [beta]
!============================================================================
! Output the incomplete beta function of x with symmetrical integer indices n
! and with the function standardized to the interval [0,1]
!============================================================================
integer, intent(IN ):: n
real(sp),intent(IN ):: x
real(sp),intent(OUT):: y
!----------------------------------------------------------------------------
real(sp),parameter  :: one=1,half=one/2
real(sp)            :: w,ws,c
integer             :: i,ip,i2p
!============================================================================
if(x<=0)      then; y=0;   return
elseif(x>=one)then; y=one; return
endif
w=x*(one-x)
c=(one-2*x)*half
y=half
do i=0,n-1; ip=i+1; i2p=i+ip; ws=2*i2p*w
   y=y-c
   c=c*ws/ip
enddo
end subroutine sbeta
!============================================================================
subroutine sbetad(n,x,y,dydx)!                                         [beta]
!============================================================================
integer, intent(IN ):: n
real(sp),intent(IN ):: x
real(sp),intent(OUT):: y,dydx
!----------------------------------------------------------------------------
real(sp),parameter  :: one=1,half=one/2
real(sp)            :: w,ws,c
integer             :: i,ip,i2p
!============================================================================
if(x<=0)      then; y=0;   dydx=0; return
elseif(x>=one)then; y=one; dydx=0; return
endif
w=x*(one-x)
c=(one-2*x)*half
y=half
dydx=0
do i=0,n-1; ip=i+1; i2p=i+ip; ws=2*i2p*w
   if(i==0)then; dydx=one
   else;         dydx=dydx*ws/i
   endif
   y=y-c
   c=c*ws/ip
enddo
end subroutine sbetad
!============================================================================
subroutine dbeta(n,x,y)!                                               [beta]
!============================================================================
! Output the incomplete beta function of x with symmetrical integer indices n
! and with the function standardized to the interval [0,1]
!============================================================================
integer, intent(IN ):: n
real(dp),intent(IN ):: x
real(dp),intent(OUT):: y
!----------------------------------------------------------------------------
real(dp),parameter  :: one=1,half=one/2
real(dp)            :: w,ws,c
integer             :: i,ip,i2p
!============================================================================
if(x<=0)      then; y=0;   return
elseif(x>=one)then; y=one; return
endif
w=x*(one-x)
c=(one-2*x)*half
y=half
do i=0,n-1; ip=i+1; i2p=i+ip; ws=2*i2p*w
   y=y-c
   c=c*ws/ip
enddo
end subroutine dbeta
!============================================================================
subroutine dbetad(n,x,y,dydx)!                                         [beta]
!============================================================================
integer, intent(IN ):: n
real(dp),intent(IN ):: x
real(dp),intent(OUT):: y,dydx
!----------------------------------------------------------------------------
real(dp),parameter  :: one=1,half=one/2
real(dp)            :: w,ws,c
integer             :: i,ip,i2p
!============================================================================
if(x<=0)      then; y=0;   dydx=0; return
elseif(x>=one)then; y=one; dydx=0; return
endif
w=x*(one-x)
c=(one-2*x)*half
y=half
dydx=0
do i=0,n-1; ip=i+1; i2p=i+ip; ws=2*i2p*w
   if(i==0)then; dydx=one
   else;         dydx=dydx*ws/i
   endif
   y=y-c
   c=c*ws/ip
enddo
end subroutine dbetad

!==============================================================================
subroutine abeta(n,y,xc)!                                               [abeta]
!==============================================================================
! Invert the symmetric-parameter-n beta function for 0<=y<=1, i.e.,
! the functional inverse of beta(n,x,y).
! Note that this inverse function is highly sensitive near y=0 and y=1
! owing to the flatness of y=beta(x) near the corresponding x=0 and x=1.
!==============================================================================
integer, intent(in ):: n
real(dp),intent(in ):: y
real(dp),intent(out):: xc
!-----------------------------------------------------------------------------
integer, parameter  :: nit=56 !<-- ~ number of bits assigned to dp mantissa
integer,parameter   :: njt=12 !<-- Allowed number of Newton iterations
real(dp),parameter  :: zip=0,one=1,half=one/2,crit=1.e-11_dp
real(dp)            :: xa,xb,yc,dydx,r,ya,yb
integer             :: it,jt
real(dp),dimension(3:20):: f
data f/ &
  0.6626423,  0.6253248,  0.6047160,  0.5916596,  0.5826500,  0.5760592, &
  0.5710288,  0.5670636,  0.5638576,  0.5612119,  0.5589915,  0.5571014, &
  0.5554731,  0.5540557,  0.5528107,  0.5517085,  0.5507258,  0.5498442/
! When X is the 1st real root bigger than one of the polynomial,
! P(X) = (X^n - 1)/(X - 1)-3n/2,
! f(n) = 1 - 1/X^n, for n>2
!==============================================================================
if(y<zip)stop 'In abeta; y<0 is out of bounds'
if(y>one)stop 'In abeta; y>1 is out of bounds'
if(y==zip)then; xc=zip; return; endif
if(y==one)then; xc=one; return; endif
if(n<3)then       ! Always perform Newton iterations
   ya=zip
   yb=one
elseif(n<=20)then ! Perform newton its. only once yc gets within [ya,yb]
   yb=f(n)*y*(one-y)
   ya=y-yb
   yb=y+yb
else              ! Never perform Newton iterations
   ya=y
   yb=y
endif
xa=zip
xb=one
xc=half
do it=1,nit
   call beta(n,xc,yc,dydx)
   if(ya<yc .and. yc<yb)then
! Polish results with a few Newton iterations:
      do jt=1,njt
         r=yc-y
         xc=xc-r/dydx
         if(jt>4 .and. abs(r)<crit)return
         call beta(n,xc,yc,dydx)
      enddo
      print'(''In abeta; n,y,yc,xc='',i3,3(1x,e13.6))',n,y,yc,xc
      print'('' Warning: failure of Newton its. to sufficiently converge'')'
      return
   endif
! Bisect the interval [xa,xb] according to which side of the center point xc
! the true x must lie:
   if    (y<yc)then; xb=xc
   elseif(y>yc)then; xa=xc
   else            ; return
   endif
   xc=(xa+xb)/2
enddo
end subroutine abeta

!=============================================================================
subroutine mid(n,w)!                                                     [mid]
!=============================================================================
! Provide the mid-point interpolation weights for half-stencil of span n
!=============================================================================
integer,              intent(IN ):: n
real(dp),dimension(n),intent(OUT):: w
!-----------------------------------------------------------------------------
real(dp),parameter   :: one=1
real(dp)             :: b
real(dp),dimension(n):: v
integer              :: i,j
!=============================================================================
v=0; v(1)=one/2
w=v
b=1 ! <- Initialize (2i)!/(i!*i!) for i=0
do i=1,n-1
   do j=1,i;      v(j)=v(j+1)-v(j); enddo ! <- convolve with [-1,1]
   do j=i+1,2,-1; v(j)=v(j-1)-v(j); enddo ! <- convolve with [1,-1]
   v(1)=-v(1)                             !
   v(1:i+1)=v(1:i+1)/16                   ! <- rescale v
   b=(2*(2*i-1)*b)/i                      ! <- update new beta factor
   w(1:i+1)=w(1:i+1)+b*v(1:i+1)           ! <- apply next order of correction
enddo
end subroutine mid
   
!=============================================================================
subroutine dif(n,w)!                                                     [dif]
!=============================================================================
! Return the differencing weights for an unstaggered half stencil of n points
!=============================================================================
integer,              intent(IN ):: n
real(dp),dimension(n),intent(OUT):: w
!-----------------------------------------------------------------------------
real(dp),parameter   :: one=1
real(dp)             :: b
real(dp),dimension(n):: v
integer              :: i,j
!=============================================================================
v=0; v(1)=one
b=2
w=v/b
do i=1,n-1
   do j=i,1,-1; v(j+1)=v(j+1)-v(j); enddo ! <-Convolve with [-1,1]
   do j=1,i;    v(j)=v(j)-v(j+1);   enddo ! <-Convolve with [1,-1]
   b=(b*2*(i*2+1))/i                      ! <- update the beta divisor
   w(1:i+1)=w(1:i+1)+v(1:i+1)/b           ! <- add correction at next order
enddo
end subroutine dif

!=============================================================================
subroutine ddif(n,w)!                                                   [ddif]
!=============================================================================
! Return weights for second-differences for a half stencil of width n
!=============================================================================
integer,                intent(IN ):: n
real(dp),dimension(0:n),intent(OUT):: w
!-----------------------------------------------------------------------------
real(dp),dimension(0:n):: v
real(dp)               :: b
integer                :: i,j
!=============================================================================
v=0; v(0)=-1
w=0
do i=1,n
   do j=i,1,-1; v(j)=v(j)-v(j-1); enddo; v(0)=-v(1)
   do j=0,i-1;  v(j)=v(j)-v(j+1); enddo
   b=-(v(0)*i*i)/2
   w(0:i)=w(0:i)+v(0:i)/b
enddo
end subroutine ddif

!=============================================================================
subroutine quad(n,w)!                                                   [quad]
!=============================================================================
! Return weights for quadrature over a centered interval
!=============================================================================
use pietc, only: half
integer,              intent(in ):: n
real(dp),dimension(n),intent(out):: w
!-----------------------------------------------------------------------------
real(dp),dimension(n-1)  :: b
real(dp),dimension(n)    :: cbin,dbin
real(dp)                 :: q
integer                  :: i,m,mm
!==============================================================================
if(n<=0)return
w=0; w(1)=half
if(n==1)return
call abernoulli(n-1,b); do i=1,n-1; b(i)=abs(b(i))/(4*i); enddo
cbin=0;    dbin=0
cbin(1)=1; dbin(1)=1
m=0
do m=2,n
   do i=m,2,-1;       dbin(i)=dbin(i)-dbin(i-1); enddo; dbin(1)=0
   do i=1,min(m,n-1); dbin(i)=dbin(i)-dbin(i+1); enddo; q=0
   do i=1,m-1;        q=q+b(i)*cbin(m-i);        enddo
   do i=2,2*m-3;      q=q/i;                     enddo
   w(1:m)=w(1:m)+dbin(1:m)*q
   if(m==n)exit
   mm=(m-1)**2;       cbin(m+1)=cbin(m)*mm
   do i=m,2,-1;       cbin(i)=cbin(i)+cbin(i-1)*mm; enddo
enddo
end subroutine quad

!=============================================================================
subroutine sdif(n,w)!                                                   [sdif]
!=============================================================================
! Return weights for staggered centered differencing
!=============================================================================
use pietc, only: two
integer,              intent(in ):: n
real(dp),dimension(n),intent(out):: w
!-----------------------------------------------------------------------------
integer                          :: i,i2m
!=============================================================================
call mid(n,w)
do i=1,n
   i2m=i*2-1
   w(i)=w(i)*two/i2m
enddo
end subroutine sdif

!=============================================================================
subroutine abernoulli(n,b)!                                       [abernoulli]
!=============================================================================
! Use Seidel's method to compute the first n even Bernoulli
! numbers in an array, b.
!=============================================================================
integer,              intent(in ):: n
real(dp),dimension(n),intent(out):: b
!-----------------------------------------------------------------------------
real(dp),dimension(-n:n):: s
real(dp)                :: p4
integer                 :: i,j,jp
!=============================================================================
s=0; s(0)=1
p4=4
b(1)=(2*s(0))/(p4*(p4-1))! = +1/6
do j=1,n-1
   jp=j+1
   p4=p4*4
   do i=1-j,j;      s(i)=s(i-1)+s(i); enddo
   do i=j-1,-j,-1;  s(i)=s(i+1)+s(i); enddo
   b(jp)=(2*jp*s(-j))/(p4*(p4-1))
   if(mod(jp,2)==0)b(jp)=-b(jp)
enddo
end subroutine abernoulli

!=============================================================================
subroutine iniwhit!                                                 [iniwhit]
!=============================================================================
real(dp),dimension(0:nh)            :: halfwhit
real(dp)                            :: t
integer                             :: i
data t/  0.702985840660966E-02_dp/
data halfwhit/ &
 0.000000E+00_dp,0.67359444443273553E-112_dp, 0.2608408785121281E-56_dp &
,0.8801231682008762E-38_dp,0.1613424230472854E-28_dp,0.5820531302607829E-23_dp&
,0.2946725078062176E-19_dp,0.1307590394438251E-16_dp,0.5917823830562705E-15_dp&
,0.2591614424941571E-13_dp,0.5441419310092633E-12_dp,0.6676767768608254E-11_dp&
,0.5467523927512676E-10_dp,0.3276520801161667E-09_dp,0.1534959338765173E-08_dp&
,0.5900866406381041E-08_dp,0.1930697859790518E-07_dp,0.5528907334495580E-07_dp&
,0.1416321546114386E-06_dp,0.3302004861041521E-06_dp,0.7103923379911236E-06_dp&
,0.1426270541868245E-05_dp,0.2697055107030170E-05_dp,0.4840334630092205E-05_dp&
,0.8297103172994092E-05_dp,0.1365758078797233E-04_dp,0.2168673097780949E-04_dp&
,0.3334843458927756E-04_dp,0.4982739617144138E-04_dp,0.7254802213933115E-04_dp&
,0.1031896977427643E-03_dp,0.1436980829031463E-03_dp,0.1962922309798845E-03_dp&
,0.2634674995553088E-03_dp,0.3479943625546429E-03_dp,0.4529133459362094E-03_dp&
,0.5815263947848335E-03_dp,0.7373850396274710E-03_dp,0.9242757669395942E-03_dp&
,0.1146203016445436E-02_dp,0.1407370229419156E-02_dp,0.1712159361148942E-02_dp&
,0.2065109250142466E-02_dp,0.2470893209275720E-02_dp,0.2934296172259578E-02_dp&
,0.3460191694455736E-02_dp,0.4053519071769307E-02_dp,0.4719260806287108E-02_dp&
,0.5462420613424190E-02_dp,0.6288002133235882E-02_dp,0.7200988478685671E-02_dp&
,0.8206322726295996E-02_dp,0.9308889429879461E-02_dp,0.1051349721597787E-01_dp&
,0.1182486250017334E-01_dp,0.1324759434647151E-01_dp,0.1478618047734467E-01_dp&
,0.1644497442959199E-01_dp,0.1822818384073985E-01_dp,0.2013985984208035E-01_dp&
,0.2218388752744064E-01_dp,0.2436397746121104E-01_dp,0.2668365818486081E-01_dp&
,0.2914626967797845E-01_dp,0.3175495772763778E-01_dp,0.3451266915847676E-01_dp&
,0.3742214787516024E-01_dp,0.4048593166876912E-01_dp,0.4370634973902026E-01_dp&
,0.4708552088498509E-01_dp,0.5062535231806493E-01_dp,0.5432753905233099E-01_dp&
,0.5819356382888847E-01_dp,0.6222469753262800E-01_dp,0.6642200006153997E-01_dp&
,0.7078632161065378E-01_dp,0.7531830433459287E-01_dp,0.8001838435468084E-01_dp&
,0.8488679407847611E-01_dp,0.8992356480153219E-01_dp,0.9512852956306293E-01_dp&
,0.1005013262290311E+00_dp,0.1060414007779580E+00_dp,0.1117480107664713E+00_dp&
,0.1176202289532598E+00_dp,0.1236569470616844E+00_dp,0.1298568796628042E+00_dp&
,0.1362185681620095E+00_dp,0.1427403848738154E+00_dp,0.1494205371706586E+00_dp&
,0.1562570716927552E+00_dp,0.1632478786072203E+00_dp,0.1703906959057328E+00_dp&
,0.1776831137310350E+00_dp,0.1851225787235057E+00_dp,0.1927063983799338E+00_dp&
,0.2004317454174441E+00_dp,0.2082956621363032E+00_dp,0.2162950647760514E+00_dp&
,0.2244267478600758E+00_dp,0.2326873885243654E+00_dp,0.2410735508267631E+00_dp&
,0.2495816900335698E+00_dp,0.2582081568808478E+00_dp,0.2669492018082339E+00_dp&
,0.2758009791634947E+00_dp,0.2847595513764499E+00_dp,0.2938208931012491E+00_dp&
,0.3029808953263236E+00_dp,0.3122353694516360E+00_dp,0.3215800513331383E+00_dp&
,0.3310106052945987E+00_dp,0.3405226281072051E+00_dp,0.3501116529375592E+00_dp&
,0.3597731532648769E+00_dp,0.3695025467683935E+00_dp,0.3792951991861331E+00_dp&
,0.3891464281463480E+00_dp,0.3990515069730743E+00_dp,0.4090056684673654E+00_dp&
,0.4190041086658778E+00_dp,0.4290419905785764E+00_dp,0.4391144479074184E+00_dp&
,0.4492165887479450E+00_dp,0.4593434992757786E+00_dp,0.4694902474200807E+00_dp&
,0.4796518865260709E+00_dp,0.4898234590087504E+00_dp,0.5000000000000000E+00_dp&
 /
!============================================================================
not_iniwhit=.false. !<- signifies that whit is now initialized
do i=0,nh
   whit(n-i)=1-halfwhit(i)
   whit(i)  =  halfwhit(i)
enddo
twhit=t
end subroutine iniwhit

!============================================================================
subroutine wbend(x,w)!                                                [wbend]
!============================================================================
use pietc, only: half,one
integer,parameter                  :: n=256,mh=4,m=mh*2,mhp=mh+1
real(dp),intent(IN )               :: x
real(dp),intent(OUT)               :: w
!----------------------------------------------------------------------------

integer,dimension(m) :: q
real(dp),dimension(m):: d
real(dp)             :: y,p
integer              :: i,j,k,L
data q/-5040, 720,-240, 144,-144, 240,-720, 5040/ !<- Lagrange divisors
!============================================================================
if(not_iniwhit)call iniwhit
if    (x<=0)then; w=0; return
elseif(x>=1)then; w=1; return
endif
y=x; if(x>half)y=one-x

! Interpolate using m-point centered Lagrange:
y=y*n; j=y; y=y-j
do i=1,m; d(i)=y+mh-i; enddo
w=0
do k=1,m
   L=j+k-mh
   if(L<=0)cycle
   p=one/q(k); do i=1,m; if(i/=k)p=p*d(i); enddo
   w=w+p*whit(L)
enddo
if(w<0)w=0
if(x>half)w=one-w
end subroutine wbend

!============================================================================
subroutine wbendd(x,w,wd)!                                             [wbend]
!============================================================================
real(dp),intent(IN ):: x
real(dp),intent(OUT):: w,wd
!-----------------------------------------------------------------------------
call wbend(x,w)
call wbend(1,x,wd)
end subroutine wbendd

!=============================================================================
subroutine wbenddn(L,x,dLwdxL)!                                        [wbend]
!=============================================================================
integer, intent(IN ):: L
real(dp),intent(IN ):: x
real(dp),intent(OUT):: dLwdxL
!-----------------------------------------------------------------------------
if(L<0)stop 'In wbend; argument L must not be negative'
if(L==0)then; call wbend(x,dLwdxL)
else; call wd(L-1,x,dLwdxL); dLwdxL=dLwdxL/twhit
endif
end subroutine wbenddn

!============================================================================
subroutine wd(n,x,dnwdxn)
!============================================================================
! Get the Nth derivative, at x, of w(x)=e(x)*e(1-x), where e(x)=exp(-1/x)
! Use the Leibniz rule for the derivative of this product.
!============================================================================
integer, intent(IN ):: n
real(dp),intent(IN ):: x
real(dp),intent(OUT):: dnwdxn
!----------------------------------------------------------------------------
real(dp),parameter:: one=1
real(dp)          :: y,dmedxm,dLedyL
integer           :: L,m,c
!============================================================================
dnwdxn=0; if(n<0 .or. x<0 .or. x>one)return
y=one-x
dnwdxn=0
do L=0,n
   m=n-L
   call ed(m,x,dmedxm)
   call ed(L,y,dLedyL); if(mod(L,2)==1)dLedyL=-dLedyL
   call choose(n,L,c)
   dnwdxn=dnwdxn+c*dLedyL*dmedxm
enddo
end subroutine wd
   
!============================================================================
subroutine ed(n,x,dnedxn)
!============================================================================
! Get the Nth derivative, at x, of e(x)=exp(-1/x).
! If N=0, just return e(x) itself.
!============================================================================
integer, intent(IN ):: n
real(dp),intent(IN ):: x
real(dp),intent(OUT):: dnedxn
!----------------------------------------------------------------------------
real(dp),parameter:: one=1
real(dp)          :: e,xi,p,xx,xp,xxp
integer           :: m,t
!============================================================================
dnedxn=0; if(x<=0.or. n<0)return
xi=one/x; e=exp(-xi); if(n==0)then; dnedxn=e; return; endif
p=0
xx=x*x
xp=one
xxp=one
do m=0,n-1
   call et(n,m,t)
   p=p+t*xp
   xp=xp*x
   xxp=xxp*xx
enddo
dnedxn=(e*p)/xxp
end subroutine ed

!===========================================================================
subroutine et(n,m,t)
!===========================================================================
integer,intent(IN ):: n,m
integer,intent(OUT):: t
integer            :: n1,d,d1,fn,fm,fn1,fd,fd1
!===========================================================================
if(m>=n)then
   t=0
else
   d=n-m
   d1=d-1
   n1=n-1
   call fact(n,fn)
   call fact(m,fm)
   call fact(n1,fn1)
   call fact(d,fd)
   call fact(d1,fd1)
   t=(fn*fn1)/(fd*fd1*fm)
endif
if(mod(m,2)==1)t=-t
end subroutine et

!===========================================================================
subroutine choose(n,m,t)
!===========================================================================
integer,intent(IN ):: n,m
integer,intent(OUT):: t
integer            :: d,fn,fm,fd
!===========================================================================
t=0; if(n<0 .or. m<0 .or. m>n)return
d=n-m
call fact(n,fn)
call fact(m,fm)
call fact(d,fd)
t=fn/(fm*fd)
end subroutine choose

!===========================================================================
subroutine fact(n,fn)
!===========================================================================
integer,intent(IN ):: n
integer,intent(OUT):: fn
integer            :: i
!===========================================================================
fn=0; if(n<0)return
fn=1; do i=1,n; fn=fn*i; enddo
end subroutine fact

!============================================================================
subroutine setwhit(halfwhit)
!============================================================================
! Set up the table if integrals of the bell-shaped function,
! g(x) = exp(-1/x)*exp(-1/(1-x))
! for steps, x(i) at equal intervals, x(i)=real(i)/real(N), with N=256, for
! the half domain, [0,.5]. 
!============================================================================
integer,parameter                   :: nb=6
real(dp),parameter                  :: one=1,dx=one/n,dxh=dx/2,dxdx=dx*dx
real(dp),dimension(0:nh),intent(OUT):: halfwhit
!----------------------------------------------------------------------------
real(dp)                            :: x,g,dg,s,t,dxdxp,gdxh
real(dp),dimension(nb)              :: B ! <- Even Bernoulli numbers
integer,dimension(nb)               :: Bnumer,Bdenom
integer                             :: i,j,j2,j2m,fj2
data Bnumer/1,-1, 1,-1, 5,-691/
data Bdenom/6,30,42,30,66,2730/
!============================================================================
! Initialize the first few Bernoulli numbers, times dxdx**j/(2j)!
dxdxp=one
do j=1,nb
   j2=j*2
   dxdxp=dxdxp*dxdx
   call fact(j2,fj2)
   B(j)=(dxdxp*Bnumer(j))/(Bdenom(j)*fj2)
enddo
print'('' modified bernoulli factors:'')'
write(6,62)B
62 format(e23.16)
read(*,*)

halfwhit(0)=0
s=0
do i=1,nh
   x=i*dx
   call wd(0,x,g)
   gdxh=g*dxh
   t=s+gdxh ! <- last value half-weighted for t, ..
   s=t+gdxh ! <- .. full-weighted for s.

!   print'('' g, x = '',2(1x,e22.16))',g,x
   j=0
!   print'('' i,j,E-M term:'',2i5,1x,e22.16)',i,j,t
   do j=1,nb
      if(i<8)exit
      if(j==5 .and. i<24)exit
      if(j==6 .and. i<30)exit  
      j2=j*2
      j2m=j2-1
      call wd(j2m,x,dg)
      t=t-B(j)*dg ! <- Apply Euler-Maclaurin correction for t
!      print'('' i,j,E-M term:'',2i5,1x,e22.16)',i,j,B(j)*dg
   enddo
!   read(*,*)
   halfwhit(i)=t
enddo
t=t*2
halfwhit=halfwhit/t
print '("data t/",e23.15,"_dp/")',t
print '("data halfwhit/ &")'
print '(e13.6,"_dp,",e24.17,"_dp,",e23.16,"_dp &")',halfwhit(0:2)
write(6,600)halfwhit(3:); 600 format((3(",",e23.16,"_dp"),"&"))
print '(" / ")'
end subroutine setwhit

end module pbend

