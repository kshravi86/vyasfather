#import <Foundation/Foundation.h>
#import "SwissEphBridge.h"

double swe_bridged_julday_gregorian(int year, int month, int day, double hour) {
    return swe_julday(year, month, day, hour, SE_GREG_CAL);
}

void swe_bridged_set_sidereal_lahiri(void) {
    swe_set_sid_mode(SE_SIDM_LAHIRI, 0.0, 0.0);
}

double swe_bridged_longitude_ut(int planet, double jd_ut, int flags, int* rc) {
    double xx[6];
    char serr[256] = "";
    int ret = swe_calc_ut(jd_ut, planet, flags, xx, serr);
    if (rc) *rc = ret;
    return xx[0]; // ecliptic longitude in degrees
}

