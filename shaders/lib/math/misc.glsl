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

// The largest integer. Probably not represented exactly.
const float INT_MAX_F = 4294967295.0;

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

// Raises a number to the 5th power.
float pow5(float x) {
  float x2 = x * x;
  return x2 * x2 * x;
}
vec2 pow5(vec2 x) {
  vec2 x2 = x * x;
  return x2 * x2 * x;
}
vec3 pow5(vec3 x) {
  vec3 x2 = x * x;
  return x2 * x2 * x;
}
vec4 pow5(vec4 x) {
  vec4 x2 = x * x;
  return x2 * x2 * x;
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

// Like sign, but never returns 0.
float signNonzero(float x) {
  return (x >= 0.0)? 1.0 : -1.0;
}
vec2 signNonzero(vec2 x) {
  return mix(vec2(-1.0), vec2(1.0), greaterThanEqual(x, vec2(0.0)));
}
vec3 signNonzero(vec3 x) {
  return mix(vec3(-1.0), vec3(1.0), greaterThanEqual(x, vec3(0.0)));
}
vec4 signNonzero(vec4 x) {
  return mix(vec4(-1.0), vec4(1.0), greaterThanEqual(x, vec4(0.0)));
}

#endif