/* Build Swiss Ephemeris into this target by including sources directly.
   Sources are vendored under ThirdParty/SwissEph/src. */
#import <Foundation/Foundation.h>
#import "SwissEphBridge.h"

// Use the vendored Swiss Ephemeris headers; link to libswe.a built in CI.
#include "swephexp.h"

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

void swe_bridged_set_ephe_path(const char *path) {
    if (path) {
        swe_set_ephe_path((char *)path);
    }
}

int swe_bridged_calc_lon_speed(int planet, double jd_ut, int flags, double* lon, double* speed) {
    double xx[6];
    char serr[256] = "";
    int ret = swe_calc_ut(jd_ut, planet, flags, xx, serr);
    if (lon) *lon = xx[0];
    if (speed) *speed = xx[3];
    return ret;
}

int swe_bridged_houses_placidus(double jd_ut, double geolat, double geolon, int flags, double* cusps13, double* ascmc10) {
    char hsys = 'P';
    // Ensure sidereal mode is already set by caller (Lahiri)
    // flags may include SEFLG_SIDEREAL
    return swe_houses_ex(jd_ut, flags, geolat, geolon, hsys, cusps13, ascmc10);
}
