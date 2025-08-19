#ifndef INTEGRAL_GLSL_INCLUDED
#define INTEGRAL_GLSL_INCLUDED
#include "/lib/math/misc.glsl"

// Implementation detail for the Hammersley function.
float radicalInverseVDC(uint bits) {
  bits = (bits << 16u) | (bits >> 16u);
  bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
  bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
  bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
  bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
  return float(bits) * 2.3283064365386963e-10;  // / 0x100000000
}

// Returns a low-discrepancy pair of random values seeded by i.
vec2 hammersley2D(uint i, uint n) {
  return vec2(float(i)/float(n), radicalInverseVDC(i));
}

// Uses a pair of random values to sample a hemisphere by the BRDF distribution.
// The returned unit vector lies in a hemisphere surrounding the vector [0, 0, 1].
vec3 importanceSample(vec2 rand, float spAlpha) {
  float a = pow2(spAlpha);

  // pick a surrounding angle randomly
  float phi = (2.0 * M_PI) * rand.x;
  // pick cos(theta) biased to our BRDF distribution function, then pick a 
  // matching sin(theta). This has the effect of multiplying our integral by D.
  float cosTheta = sqrt((1.0 - rand.y) / (1.0 + (pow2(a) - 1.0) * rand.y));
  float sinTheta = sqrt(1.0 - pow2(cosTheta));

  return vec3(cos(phi) * sinTheta, sin(phi) * sinTheta, cosTheta);
}

#endif