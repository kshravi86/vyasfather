#ifndef SwissEphBridge_h
#define SwissEphBridge_h

#include "swephexp.h"

// Wrapper helpers to call Swiss Ephemeris from Swift
double swe_bridged_julday_gregorian(int year, int month, int day, double hour);
void swe_bridged_set_sidereal_lahiri(void);
double swe_bridged_longitude_ut(int planet, double jd_ut, int flags, int* rc);
void swe_bridged_set_ephe_path(const char *path);

// Extended: compute longitude and speed (lon deg/day)
int swe_bridged_calc_lon_speed(int planet, double jd_ut, int flags, double* lon, double* speed);

// Houses (Placidus) and Asc/MC
// Returns 0 on success; fills 13 cusps (1..12) and 10 ascmc values (ASC, MC, etc.).
int swe_bridged_houses_placidus(double jd_ut, double geolat, double geolon, int flags, double* cusps13, double* ascmc10);

#endif /* SwissEphBridge_h */
