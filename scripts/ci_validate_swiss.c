#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "ThirdParty/SwissEph/src/swephexp.h"

static const char* signs[12] = {
  "Aries","Taurus","Gemini","Cancer","Leo","Virgo",
  "Libra","Scorpio","Sagittarius","Capricorn","Aquarius","Pisces"
};
static const char* nakshatras[27] = {
  "Ashwini","Bharani","Krittika","Rohini","Mrigashira","Ardra","Punarvasu","Pushya","Ashlesha",
  "Magha","Purva Phalguni","Uttara Phalguni","Hasta","Chitra","Swati","Vishakha","Anuradha",
  "Jyeshtha","Mula","Purva Ashadha","Uttara Ashadha","Shravana","Dhanishta","Shatabhisha","Purva Bhadrapada","Uttara Bhadrapada","Revati"
};

static void sign_degmin(double lon, const char** sign, int* d, int* m) {
  int sidx = ((int)floor(lon/30.0)) % 12;
  double within = lon - sidx*30.0;
  int deg = (int)floor(within);
  int min = (int)floor((within - deg)*60.0 + 0.5);
  *sign = signs[sidx];
  *d = deg; *m = min;
}

static void nak_pada(double lon, const char** nak, int* pada) {
  double seg = 13.333333333333;
  int nidx = ((int)floor(lon/seg)) % 27;
  double rem = lon - nidx*seg;
  int pd = (int)floor(rem/(seg/4.0)) + 1; if (pd<1) pd=1; if (pd>4) pd=4;
  *nak = nakshatras[nidx];
  *pada = pd;
}

int main(int argc, char** argv) {
  // Ephemeris path from repo resource folder
  swe_set_ephe_path("NotesApp/SwissEph");
  swe_set_sid_mode(SE_SIDM_LAHIRI, 0, 0);
  // 1993-05-18 17:00 UT (22:30 IST)
  double jdut = swe_julday(1993,5,18,17.0,SE_GREG_CAL);
  int bodies[] = {SE_SUN, SE_MOON, SE_MERCURY, SE_VENUS, SE_MARS, SE_JUPITER, SE_SATURN, SE_MEAN_NODE};
  const char* names[] = {"Sun","Moon","Mercury","Venus","Mars","Jupiter","Saturn","Rahu"};
  int n = sizeof(bodies)/sizeof(bodies[0]);
  int flags = SEFLG_SWIEPH | SEFLG_SIDEREAL;
  int had_err = 0;
  for (int i=0;i<n;i++) {
    double xx[6]; char serr[256] = {0};
    int ret = swe_calc_ut(jdut, bodies[i], flags, xx, serr);
    if (ret < 0) { fprintf(stderr, "ERR %s: %s\n", names[i], serr); had_err=1; continue; }
    double lon = fmod(xx[0],360.0); if (lon<0) lon+=360.0;
    const char* s; int d,m; sign_degmin(lon,&s,&d,&m);
    const char* nak; int pada; nak_pada(lon,&nak,&pada);
    printf("%s: lon=%.6f sign=%s %d°%d' nak=%s p%d (ret=%d)\n", names[i], lon, s, d, m, nak, pada, ret);
  }
  // Basic sanity: Sun should be Taurus and Krittika around 4° Taurus for given date
  double xx[6]; char serr[256]={0};
  int ret = swe_calc_ut(jdut, SE_SUN, flags, xx, serr);
  if (ret < 0) { fprintf(stderr, "::error::Swiss calc failed for Sun: %s\n", serr); return 2; }
  double sun = fmod(xx[0],360.0); if (sun<0) sun+=360.0;
  const char* sign; int sd, sm; sign_degmin(sun,&sign,&sd,&sm);
  const char* nak; int pd; nak_pada(sun,&nak,&pd);
  if (strcmp(sign,"Taurus")!=0 || strcmp(nak,"Krittika")!=0) {
    fprintf(stderr, "::error::Sun expected Taurus/Krittika, got %s/%s at %d°%d'\n", sign, nak, sd, sm);
    return 3;
  }
  if (had_err) return 4;
  return 0;
}

