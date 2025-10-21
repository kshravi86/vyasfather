/* Build Swiss Ephemeris into this target by including sources directly.
   Sources are vendored under ThirdParty/SwissEph/src. */
#import <Foundation/Foundation.h>
#import "SwissEphBridge.h"

// Ensure the C sources are visible. We include them to avoid Xcode project edits.
// Header
#include "ThirdParty/SwissEph/src/swephexp.h"

// Core sources (order matters for some compilers)
#include "ThirdParty/SwissEph/src/swedate.c"
#include "ThirdParty/SwissEph/src/swephlib.c"
#include "ThirdParty/SwissEph/src/sweph.c"
#include "ThirdParty/SwissEph/src/swemini.c"
#include "ThirdParty/SwissEph/src/swemmoon.c"
#include "ThirdParty/SwissEph/src/swecl.c"
#include "ThirdParty/SwissEph/src/sweclips.c"
#include "ThirdParty/SwissEph/src/swehouse.c"
#include "ThirdParty/SwissEph/src/swehel.c"
#include "ThirdParty/SwissEph/src/sweasp.c"
#include "ThirdParty/SwissEph/src/swephgen4.c"
#include "ThirdParty/SwissEph/src/swemplan.c"
#include "ThirdParty/SwissEph/src/swevents.c"

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
