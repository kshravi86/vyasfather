/* Build Swiss Ephemeris into this target by including sources directly.
   Sources are vendored under ThirdParty/SwissEph/src. */
#import <Foundation/Foundation.h>
#import "SwissEphBridge.h"

// Ensure the C sources are visible. We include them to avoid Xcode project edits.
// Header
#include "swephexp.h"

// Core sources (order matters for some compilers)
#include "swedate.c"
#include "swephlib.c"
#include "sweph.c"
#include "swemini.c"
#include "swemmoon.c"
#include "swecl.c"
#include "sweclips.c"
#include "swehouse.c"
#include "swehel.c"
#include "sweasp.c"
#include "swephgen4.c"
#include "swemplan.c"
#include "swevents.c"

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
