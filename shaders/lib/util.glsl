#ifndef UTIL_GLSL_INCLUDED
#define UTIL_GLSL_INCLUDED

/*
// Setup transparent color buffer
const int colortex4Format = RGBA8;
const vec4 colortex4ClearColor = vec4(0.0, 0.0, 0.0, 0.0);

// clear normal buffers to empty normal
const vec4 colortex2ClearColor = vec4(0.5, 0.5, 0.5, 1.0);
const vec4 colortex5ClearColor = vec4(0.5, 0.5, 0.5, 1.0);
*/

// TRANSFORMATION
// ===============================================

// Transforms a 3D vector by a projective transformation in homogenous coordinates.
vec3 txProjective(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}
// Transforms a 3D vector by an affine transformation.
vec3 txAffine(mat4 matrix, vec3 position) {
	return (matrix * vec4(position, 1.0)).xyz;
}
// Transforms a 3D vector by a linear (i.e. translation-free) transformation.
// If used with a non-linear transformation, eliminates the non-linear components.
vec3 txLinear(mat4 matrix, vec3 position) {
	return mat3(matrix) * position;
}

// WEIRD MATH FUNCTIONS
// ===============================================

// Ease-out transition between 0 and the saturation point.
float horizonStep(float cosSunToUp, float satPoint) {
	float x = clamp(cosSunToUp / satPoint, 0.0, 1.0);
	// quadratic ease-out
	float xm1 = x - 1.0;
	return 1.0 - xm1 * xm1;
}

// 4-norm of a vector.
float l4norm(vec2 pos) {
  pos *= pos;
  float sum = dot(pos, pos);
  return sqrt(sqrt(sum));
}

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
  } else {
    return normalize(decoded);
  }
}

// Convert a set of 8 flags to a color component.
float flagsToColor(uint flags) {
  return float(flags & 0xFF) / 256.0;
}
// Convert a color component to a set of 8 flags.
uint colorToFlags(float color) {
  return uint(color * 256.0);
}

// USEFUL CONSTANTS
// ===============================================

// The SRGB gamma and reciproclal gamma
const float SRGB_GAMMA = 2.2;
const float SRGB_GAMMA_INV = 1.0 / 2.2;

// Coefficients for measuring luma/luminance.
const vec3 LUMA_COEFFS = vec3(0.2126, 0.7152, 0.0722);

// Encoded normal equal to zero. This prevents lighting
// from being processed for that pixel.
const vec4 COL_NORMAL_NONE = vec4(0.5, 0.5, 0.5, 1.0);

// Lighting: do not apply shadowing to this object.
const uint LTG_NO_SHADOW = (1u << 0);

#endif