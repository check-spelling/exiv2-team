// C++ program calculating the sunrise and sunset for
// the current date and a fixed location(latitude,longitude)
// Jarmo Lammi 1999 - 2000
// Last update January 6th, 2000

#include <iostream>
#include <math.h>
#include <time.h>

double pi = 4.0*atan2(1.0,1.0);
double tpi = 2 * pi;
double degs = 180.0/pi;
double rads = pi/180.0;

double L,g,daylen;
double SunDia = 0.53;     // Sunradius degrees

double AirRefr = 34.0/60.0; // atmospheric refraction degrees //

//   Get the days to J2000
//   h is UT in decimal hours
//   FNday only works between 1901 to 2099 - see Meeus chapter 7

double FNday (int y, int m, int d, float h) {
int luku = - 7 * (y + (m + 9)/12)/4 + 275*m/9 + d;
// type casting necessary on PC DOS and TClite to avoid overflow
luku+= (long int)y*367;
return (double)luku - 730531.5 + h/24.0;
};

//   the function below returns an angle in the range
//   0 to 2*pi

double FNrange (double x) {
    double b = x / tpi;
    double a = tpi * (b - (long)(b));
    if (a < 0) a = tpi + a;
    return a;
};

// Calculating the hourangle
//
double f0(double lat, double declin) {
double fo,dfo;
// Correction: different sign at S HS
dfo = rads*(0.5*SunDia + AirRefr); if (lat < 0.0) dfo = -dfo;
fo = tan(declin + dfo) * tan(lat*rads);
if (fo>0.99999) fo=1.0; // to avoid overflow //
fo = asin(fo) + pi/2.0;
return fo;
};

// Calculating the hourangle for twilight times
//
double f1(double lat, double declin) {
double fi,df1;
// Correction: different sign at S HS
df1 = rads * 6.0; if (lat < 0.0) df1 = -df1;
fi = tan(declin + df1) * tan(lat*rads);
if (fi>0.99999) fi=1.0; // to avoid overflow //
fi = asin(fi) + pi/2.0;
return fi;
};


//   Find the ecliptic longitude of the Sun

double FNsun (double d) {

//   mean longitude of the Sun

L = FNrange(280.461 * rads + .9856474 * rads * d);

//   mean anomaly of the Sun

g = FNrange(357.528 * rads + .9856003 * rads * d);

//   Ecliptic longitude of the Sun

return FNrange(L + 1.915 * rads * sin(g) + .02 * rads * sin(2 * g));
};

// Display decimal hours in hours and minutes
void showhrmn(double dhr) {
int hr,mn;
hr=(int) dhr;
mn = (dhr - (double) hr)*60;
if (hr < 10) std::cout << '0';
std::cout << hr << ':';
if (mn < 10) std::cout << '0';
std::cout << mn;
};

int main(void){
double y,m,day,h,latit,longit;

time_t sekunnit;
struct tm *p;

//  get the date and time from the user
// read system date and extract the year

/** First get time **/
time(&sekunnit);

/** Next get localtime **/

 p=localtime(&sekunnit);

 y = p->tm_year;
 // this is Y2K compliant method
 y+= 1900;
 m = p->tm_mon + 1;

 day = p->tm_mday;

 h = 12;

double tzone=2.0;
std::cout << "Input latitude, longitude and timezone and month\n";
std::cin >> latit;
std::cin >> longit;
std::cin >> tzone;

// testing
// m=6; day=10;

double d = FNday(y, m, day, h);

//   Use FNsun to find the ecliptic longitude of the
//   Sun

double lambda = FNsun(d);

//   Obliquity of the ecliptic

double obliq = 23.439 * rads - .0000004 * rads * d;

//   Find the RA and DEC of the Sun

double alpha = atan2(cos(obliq) * sin(lambda), cos(lambda));
double delta = asin(sin(obliq) * sin(lambda));

// Find the Equation of Time
// in minutes
// Correction suggested by David Smith
double LL = L - alpha;
if (L < pi) LL += tpi;
double equation = 1440.0 * (1.0 - LL / tpi);
double ha = f0(latit,delta);
double hb = f1(latit,delta);
double twx = hb - ha;	// length of twilight in radians
twx = 12.0*twx/pi;		// length of twilight in hours
std::cout << "ha=" << ha << "  hb=" << hb << std::endl;
// Conversion of angle to hours and minutes //
daylen = degs*ha/7.5;
     if (daylen<0.0001) {daylen = 0.0;}
// arctic winter     //

double riset = 12.0 - 12.0 * ha/pi + tzone - longit/15.0 + equation/60.0;
double settm = 12.0 + 12.0 * ha/pi + tzone - longit/15.0 + equation/60.0;
double noont = riset + 12.0 * ha/pi;
double altmax = 90.0 + delta * degs - latit; 
// Correction for S HS suggested by David Smith
// to express altitude as degrees from the N horizon
if (latit < delta * degs) altmax = 180.0 - altmax;

double twam = riset - twx;	// morning twilight begin
double twpm = settm + twx;	// evening twilight end

if (riset > 24.0) riset-= 24.0;
if (settm > 24.0) settm-= 24.0;

std::cout << "\n Sunrise and set\n";
std::cout << "===============\n";

std::cout.setf(std::ios::fixed);
std::cout.precision(0);
std::cout << "  year  : " << y << '\n';
std::cout << "  month : " << m << '\n';
std::cout << "  day   : " << day << "\n\n";
std::cout << "Days until Y2K :  " << d << '\n';
std::cout.precision(2);
std::cout << "Latitude :  " << latit << ", longitude:  " << longit << '\n';
std::cout << "Timezone :  " << tzone << "\n\n";
std::cout << "Declination   : " << delta * degs << '\n';
std::cout << "Daylength     : "; showhrmn(daylen); std::cout << " hours \n";
std::cout << "Civil twilight: ";
showhrmn(twam); std::cout << '\n';
std::cout << "Sunrise       : ";
showhrmn(riset); std::cout << '\n';

std::cout << "Sun altitude at noontime ";
// Amendment by D. Smith
showhrmn(noont); std::cout << " = " << altmax << " degrees"
    << (latit>=0.0 ? " S" : " N") << std::endl;
std::cout << "Sunset        : ";
showhrmn(settm); std::cout << '\n';
std::cout << "Civil twilight: ";
showhrmn(twpm); std::cout << '\n';

return 0;
}
