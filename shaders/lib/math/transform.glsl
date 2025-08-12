#ifndef MATH_TRANSFORM_GLSL_INCLUDED
#define MATH_TRANSFORM_GLSL_INCLUDED

// Performs an affine transformation on a point.
vec3 txAffine(mat4 matrix, vec3 point) {
  return mat3(matrix) * vec + matrix[3].xyz;
}

// Performs a projective transformation on a point.
vec3 txProjective(mat4 matrix, vec3 point) {
  vec4 clip = matrix * vec4(point, 1.0);
  return clip.xyz / clip.w;
}

#endif