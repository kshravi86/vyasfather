#ifndef SwissEphBridge_h
#define SwissEphBridge_h

#include "swephexp.h"

// Wrapper helpers to call Swiss Ephemeris from Swift
double swe_bridged_julday_gregorian(int year, int month, int day, double hour);
void swe_bridged_set_sidereal_lahiri(void);
double swe_bridged_longitude_ut(int planet, double jd_ut, int flags, int* rc);
void swe_bridged_set_ephe_path(const char *path);

#endif /* SwissEphBridge_h */
