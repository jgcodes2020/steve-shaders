#ifndef COMMON_GLSL_INCLUDED
#define COMMON_GLSL_INCLUDED

#include "/lib/render_settings.glsl"
#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"

// USEFUL CONSTANTS
// ===============================================

// The SRGB gamma and reciproclal gamma
const float SRGB_GAMMA     = 2.2;
const float SRGB_GAMMA_INV = 1.0 / 2.2;

// Coefficients for measuring luma/luminance.
const vec3 LUMA_COEFFS = vec3(0.2126, 0.7152, 0.0722);

// Encoded normal equal to zero. This prevents lighting
// from being processed for that pixel.
const vec4 COL_NORMAL_NONE = vec4(0.5, 0.5, 0.5, 1.0);

// A pretty small number. Used for computing approximate equality.
const float EPSILON = 1.0e-4;

// FLAGS
// ===============================================

// Lighting: do not apply shadowing to this object.
const uint LTG_NO_SHADOW = (1u << 0);

// TRANSFORMATION
// ===============================================

// Transforms a 3D vector by a projective transformation in homogenous
// coordinates.
vec3 txProjective(mat4 projectionMatrix, vec3 position) {
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}
// Transforms a 3D vector by an affine transformation.
vec3 txAffine(mat4 matrix, vec3 position) {
  return (matrix * vec4(position, 1.0)).xyz;
}
// Transforms a 3D vector by a linear (i.e. translation-free) transformation.
// If used with a non-linear transformation, eliminates the non-linear
// components.
vec3 txLinear(mat4 matrix, vec3 position) {
  return mat3(matrix) * position;
}

mat2 rotationMatrix(float t) {
  float cosT = cos(t);
  float sinT = sin(t);
  return mat2(cosT, sinT, -sinT, cosT);
}

vec2 fragToNdc(vec2 fragCoord) {
  return fma(fragCoord.xy, vec2(2.0) / vec2(viewWidth, viewHeight), vec2(-1.0));
}

// WEIRD MATH FUNCTIONS
// ===============================================

// Quadratic ease out between 0 and satPoint.
float horizonStep(float cosSunToUp, float satPoint) {
  float x = clamp(cosSunToUp / satPoint, 0.0, 1.0);
  // quadratic ease-out
  float xm1 = x - 1.0;
  return 1.0 - xm1 * xm1;
}

// A inverse version of mix(). For a value, returns
// the appropriate mixing factor if it's between start and end.
// If past either end, it is clamped.
float linearStep(float start, float end, float value) {
  return clamp((value - start) / (end - start), 0.0, 1.0);
}

// 4-norm of a vector.
float l4norm(vec2 pos) {
  pos *= pos;
  float sum = dot(pos, pos);
  return sqrt(sqrt(sum));
}

// Reinhard-Jodie tonemapping function.
vec3 reinhardJodie(vec3 v) {
  float l = dot(v, LUMA_COEFFS);
  vec3 tv = v / (1.0 + v);
  return mix(v / (1.0 + l), tv, tv);
}

vec4 sampleNoise(ivec2 fragCoord) {
  int biasFactor = frameCounter * 2 + 1;

  return texelFetch(
    noisetex, (fragCoord * biasFactor) % noiseTextureResolution, 0);
}

const float MF_TWO_PI = 6.2831853071;
const float MF_PI     = 3.1415926535;

// ENCODING
// ===============================================

// Convert a normal to a colour.
vec4 normalToColor(vec3 normal) {
  return vec4(normal * 0.5 + 0.5, 1.0);
}

// Convert a colour back to a normal. Normals with very small
// magnitudes will map to the zero vector.
vec3 colorToNormal(vec4 colour) {
  vec3 decoded = (colour.rgb - 0.5) * 2.0;
  if (dot(decoded, decoded) < 0.01) {
    return vec3(0.0);
  }
  else {
    return normalize(decoded);
  }
}

// Convert a set of 8 flags to a color component.
float flagsToColor(uint flags) {
  return float(flags & 0xFFu) / 255.0;
}
// Convert a color component to a set of 8 flags.
uint colorToFlags(float color) {
  return uint(color * 255.0);
}

#endif