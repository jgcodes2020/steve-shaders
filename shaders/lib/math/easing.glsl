#ifndef MATH_EASING_GLSL_INCLUDED
#define MATH_EASING_GLSL_INCLUDED

#include "/lib/math/misc.glsl"

// Basic linear easing between two edges.
float linearStep(float edge0, float edge1, float x) {
  return clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
}

// f(t) = 4t(1 - t)
float easeTempQuadratic(float edge0, float edge1, float x) {
  float t = linearStep(edge0, edge1, x);
  float t_x4 = 4.0 * t;
  return fma(t_x4, -t, t_x4);
}

// f(t) = t(2 - t)
float easeOutQuadratic(float edge0, float edge1, float x) {
  float t = linearStep(edge0, edge1, x);
  return fma(t, -t, 2.0 * t);
}

#endif