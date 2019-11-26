!
!=============================================================================
module pietc
!=============================================================================
! Some of the commonly used constants (pi etc) for double-precision
! subroutines
! ms10 etc are added to satisfy the gfortran compiler. 
!=============================================================================
use pkind, only: dp,dpc
implicit none
!private:: ms10,ms13,ms18,ms20,ms22,ms26,ms30,ms36,ms39,ms40,ms45, &
!          ms50,ms51,ms54,ms60,ms64,ms68,ms70,ms72,ms77,ms80
logical ,parameter:: t=.true.,f=.false.
real(dp),parameter:: zero=0,one=1,mone=-one,two=2,mtwo=-two, &
                     three=3,mthree=-three,four=4,mfour=-four, &
                     five=5,mfive=-five,    &
                     half=one/two,third=one/three,fourth=one/four,&
                     fifth=one/five,                              & 
     pi =3.1415926535897932384626433832795028841971693993751058209749e0_dp, &
     pi2=6.2831853071795864769252867665590057683943387987502116419498e0_dp, &
     pih=1.5707963267948966192313216916397514420985846996875529104874e0_dp, &
     rpi=1.7724538509055160272981674833411451827975494561223871282138e0_dp, &
     r2 =1.4142135623730950488016887242096980785696718753769480731766e0_dp, &
     r3 =1.7320508075688772935274463415058723669428052538103806280558e0_dp, &
     r5 =2.2360679774997896964091736687312762354406183596115257242708e0_dp, &
     phi=1.6180339887498948482045868343656381177203091798057628621354e0_dp, &
     euler=0.5772156649015328606065120900824024310421593359399235988057e0_dp,&
     rh=r2/2, &
     dtor=pi/180,rtod=180/pi, &
s13=& ! sin(12.857142...)
0.2225209339563144042889025644967947594663555687645449553119870158974212e0_dp,&
s18=.30901699437494742410229341718281905886015458990288143106772431e0_dp, &
s26=& ! sin(25.714285...)
0.4338837391175581204757683328483587546099907277874598764445473035322033e0_dp,&
s30=half,&
s36=.58778525229247312916870595463907276859765243764314599107227248e0_dp,&
s39=& ! sin(38.571428...)
0.6234898018587335305250048840042398106322747308964021053655494390968537e0_dp,&
s45=rh,&
s51=& ! sin(51.428571...)
0.7818314824680298087084445266740577502323345187086875289806349580450917e0_dp,&
s54=.80901699437494742410229341718281905886015458990288143106772431e0_dp,&
s60=r3*half,&
s64=& ! sin(64.285714...)
0.9009688679024191262361023195074450511659191621318571500535624231994324e0_dp,&
s72=.95105651629515357211643933337938214340569863412575022244730564e0_dp,&
s77=& ! sin(77.142857...)
0.9749279121818236070181316829939312172327858006199974376480795750876459e0_dp
real(dp),parameter:: &
     s22=0.38268343236508978e0_dp, &
     s68=0.92387953251128674e0_dp
real(dp),parameter:: &
     s10=0.17364817766693033e0_dp, &
     s20=0.34202014332566871e0_dp, &
     s40=0.64278760968653925e0_dp, &
     s50=0.76604444311897801e0_dp, &
     s70=0.93969262078590832e0_dp, &
     s80=0.98480775301220802e0_dp 
real(dp),parameter::  &
ms10=-s10, &
ms13=-s13, &
ms18=-s18, &
ms20=-s20, &
ms22=-s22, &
ms26=-s26, &
ms30=-s30, &
ms36=-s36, &
ms39=-s39, &
ms40=-s40, &
ms45=-s45, &
ms50=-s50, &
ms51=-s51, &
ms54=-s54, &
ms60=-s60, &
ms64=-s64, &
ms68=-s68, &
ms70=-s70, &
ms72=-s72, &
ms77=-s77, &
ms80=-s80

complex(dpc),parameter:: &
     c0=(zero,zero),c1=(one,zero),mc1=-c1,ci=(zero,one),mci=-ci, &
     cipi=ci*pi,                                                 &
! Degree rotations:
     z000=c1        ,z010=( s80,s10),z013=( s77,s13),z018=( s72,s18), &
     z020=( s70,s20),z022=( s68,s22),z026=( s64,s26),z030=( s60,s30), &
     z036=( s54,s36),z039=( s51,s39),z040=( s50,s40),z045=( s45,s45), &
     z050=( s40,s50),z051=( s39,s51),z054=( s36,s54),z060=( s30,s60), &
     z064=( s26,s64),z068=( s22,s68),z070=( s20,s70),z072=( s18,s72), &
     z077=( s13,s77),z080=( s10,s80),z090=ci,        z100=(ms10,s80), &
     z103=(ms13,s77),z108=(ms18,s72),z110=(ms20,s70),z112=(ms22,s68), &
     z116=(ms26,s64),z120=(ms30,s60),z126=(ms36,s54),z129=(ms39,s51), &
     z130=(ms40,s50),z135=(ms45,s45),z140=(ms50,s40),z141=(ms51,s39), &
     z144=(ms54,s36),z150=(ms60,s30),z154=(ms64,s26),z158=(ms68,s22), &
     z160=(ms70,s20),z162=(ms72,s18),z167=(ms77,s13),z170=(ms80,s10), &
     z180=-z000,z190=-z010,z193=-z013,z198=-z018,z200=-z020,z202=-z022, &
     z206=-z026,z210=-z030,z216=-z036,z219=-z039,z220=-z040,z225=-z045, &
     z230=-z050,z231=-z051,z234=-z054,z240=-z060,z244=-z064,z248=-z068, &
     z250=-z070,z252=-z072,z257=-z077,z260=-z080,z270=-z090,z280=-z100, &
     z283=-z103,z288=-z108,z290=-z110,z292=-z112,z296=-z116,z300=-z120, &
     z306=-z126,z309=-z129,z310=-z130,z315=-z135,z320=-z140,z321=-z141, &
     z324=-z144,z330=-z150,z334=-z154,z338=-z158,z340=-z160,z342=-z162, &
     z347=-z167,z350=-z170
end module pietc
