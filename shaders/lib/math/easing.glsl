#ifndef MATH_EASING_GLSL_INCLUDED
#define MATH_EASING_GLSL_INCLUDED

#include "/lib/math/misc.glsl"

//! Functions for easing between edges.

// Inverse lerp between edges.
float linearStep(float edge0, float edge1, float x) {
  return clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
}

// f(t) = 4t(1 - t)
// Starts at 0, goes to 1, returns back to 0.
float easeTempQuadratic(float t) {
  float t_x4 = 4.0 * t;
  return fma(t_x4, -t, t_x4);
}

// f(t) = 1 - (2t - 1)^4
// Starts at 0, goes to 1, returns back to 0.
// Plateaus in the center.
float easeTempQuartic(float t) {
  float inner = fma(t, 2.0, -1.0);
  return 1.0 - pow2(pow2(inner));
}

// f(t) = t(2 - t)
// Starts at 0, ends at 1 with a nice ease-out.
float easeOutQuadratic(float t) {
  return fma(t, -t, 2.0 * t);
}

#endif