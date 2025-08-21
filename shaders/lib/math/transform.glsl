#ifndef MATH_TRANSFORM_GLSL_INCLUDED
#define MATH_TRANSFORM_GLSL_INCLUDED

#include "/lib/math/misc.glsl"

// Useful math functions for dealing with matrices.

// Applies an affine transformation to a point.
// An affine transformation has the form:
// Ix Jx Kx Tx
// Iy Jy Ky Ty
// Iz Jz Kz Tz
// 0  0  0  1
vec3 txAffine(mat4 matrix, vec3 point) {
  return mat3(matrix) * point + matrix[3].xyz;
}

// Applies a projection to a point, returning 
// the resulting clip-space position.
// A projection has the form:
// Sx 0  0  0
// 0  Sy 0  0
// 0  0  Fz Bz
// 0  0  Fw 0
vec4 txProjToClip(mat4 matrix, vec3 point) {
  return vec4(
    vec2(matrix[0].x, matrix[1].y) * point.xy,
    fma(matrix[2].z, point.z, matrix[3].z),
    matrix[2].w * point.z
  );
}

// Applies a projection to a point.
// A projection has the form:
// Sx 0  0  0
// 0  Sy 0  0
// 0  0  Fz Bz
// 0  0  Fw 0
// vec4 txProj(mat4 matrix, vec3 point) {
//   vec4 clip = txProjToClip(matrix, point);
//   return clip.xyz / clip.w;
// }

// Applies an inverse projection to a point.
// An inverse projection has the form:
// Sx 0  0  0
// 0  Sy 0  0
// 0  0  0  Fz
// 0  0  Fw Bw
vec3 txInvProj(mat4 matrix, vec3 point) {
  vec4 clip = vec4(
    vec2(matrix[0].x, matrix[1].y) * point.xy,
    matrix[3].z,
    matrix[2].w * point.z + matrix[3].w
  );
  return clip.xyz / clip.w;
}

// Constructs a 2D rotation matrix for 
// an angle [theta].
mat2 rotationMatrix(float theta) {
  float sinTheta = sin(theta);
  float cosTheta = cos(theta);

  return mat2(cosTheta, sinTheta, -sinTheta, cosTheta);
}

#endif