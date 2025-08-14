#ifndef MATH_MISC_GLSL_INCLUDED
#define MATH_MISC_GLSL_INCLUDED

// x^(2.2) and x^(1/2.2) are approximations of the sRGB
// transfer function, but it's good enough.

const float SRGB_GAMMA = 2.2;
const float SRGB_GAMMA_RCP = 1.0 / 2.2;

const float M_PI = 3.1415926;

// Coefficients for measuring luma/luminance.
const vec3 LUMA_COEFFS = vec3(0.2126, 0.7152, 0.0722);

// Squares a number.
float pow2(float x) {
  return x * x;
}
// Squares a number.
vec2 pow2(vec2 x) {
  return x * x;
}
// Squares a number.
vec3 pow2(vec3 x) {
  return x * x;
}
// Squares a number.
vec4 pow2(vec4 x) {
  return x * x;
}

#endif