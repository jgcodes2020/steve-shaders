#ifndef MATH_MISC_GLSL_INCLUDED
#define MATH_MISC_GLSL_INCLUDED

// x^(2.2) and x^(1/2.2) are approximations of the sRGB
// transfer function, but it's good enough.
const float SRGB_GAMMA = 2.2;
const float SRGB_GAMMA_RCP = 1.0 / 2.2;

// pi, ratio of circle's perimeter to its diameter.
const float M_PI = 3.1415926;

// Coefficients for measuring luma/luminance.
const vec3 LUMA_COEFFS = vec3(0.2126, 0.7152, 0.0722);

// positive-clamped dot product.
float clampDot(vec3 x, vec3 y) {
  return max(dot(x, y), 0.0);
}

// Squares a number.
float pow2(float x) {
  return x * x;
}
vec2 pow2(vec2 x) {
  return x * x;
}
vec3 pow2(vec3 x) {
  return x * x;
}
vec4 pow2(vec4 x) {
  return x * x;
}

// Computes the L4 norm, that is (x^4 + y^4)^(1/4).
float l4norm(vec2 x) {
  vec2 x2 = x * x;
  return sqrt(sqrt(dot(x2, x2)));
}
float l4norm(vec3 x) {
  vec3 x2 = x * x;
  return sqrt(sqrt(dot(x2, x2)));
}
float l4norm(vec4 x) {
  vec4 x2 = x * x;
  return sqrt(sqrt(dot(x2, x2)));
}

// Returns 1 with the sign bit copied from x.
// float signFast(float x) {
//   const uint FLOAT_ONE = 0x3f800000u;
//   uint i = floatBitsToUint(x);
//   i = bitfieldInsert(i, FLOAT_ONE, 0, 31);
//   return uintBitsToFloat(i);
// }

#endif