#ifndef POST_FOG_GLSL_INCLUDED
#define POST_FOG_GLSL_INCLUDED

#include "/lib/common.glsl"

const int FOG_EXP = 2048;
const int FOG_EXP2 = 2049;
const int FOG_LINEAR = 9729;

const int FOG_SPHERE = 0;
const int FOG_CYLINDER = 1;

float getFog(vec3 eyePos) {
  float dist;
  if (fogShape == FOG_CYLINDER) {
    dist = length(eyePos.xz);
  }
  else {
    dist = length(eyePos);
  }

  float fog;
  if (fogMode == FOG_EXP) {
    fog = exp(-dist * fogDensity);
  }
  else if (fogMode == FOG_EXP2) {
    float temp = dist * fogDensity;
    fog = exp(-(temp * temp));
  }
  else {
    fog = (dist - fogStart) / (fogEnd - fogStart);
  }
  return clamp(fog, 0.0, 1.0);
}

#endif