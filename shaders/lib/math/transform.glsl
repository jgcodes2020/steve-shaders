#ifndef MATH_TRANSFORM_GLSL_INCLUDED
#define MATH_TRANSFORM_GLSL_INCLUDED

// Random math functions that are generally useful for linear algebra stuff.

// Performs an affine transformation on a point.
vec3 txAffine(mat4 matrix, vec3 point) {
  return mat3(matrix) * point + matrix[3].xyz;
}

// Performs a projective transformation on a point.
vec3 txProjective(mat4 matrix, vec3 point) {
  vec4 clip = matrix * vec4(point, 1.0);
  return clip.xyz / clip.w;
}

mat2 rotationMatrix(float theta) {
  float sinTheta = sin(theta);
  float cosTheta = cos(theta);

  return mat2(cosTheta, sinTheta, -sinTheta, cosTheta);
}

#endif