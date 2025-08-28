#ifndef MATH_NOISE_GLSL_INCLUDED
#define MATH_NOISE_GLSL_INCLUDED

#include "/lib/pipeline_config.glsl"

//! Useful functions for generating noise.

// https://www.shadertoy.com/view/XlGcRh
uint hashPCG(uint v) {
  uint state = v * 747796405u + 2891336453u;
  uint word  = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
  return (word >> 22u) ^ word;
}

uvec2 hashPCG2(uvec2 v) {
  v = v * 1664525u + 1013904223u;

  v.x += v.y * 1664525u;
  v.y += v.x * 1664525u;

  v = v ^ (v >> 16u);

  v.x += v.y * 1664525u;
  v.y += v.x * 1664525u;

  v = v ^ (v >> 16u);

  return v;
}

// Samples the noise texture, seeded by pixel coordinates.
vec4 sampleNoise(ivec2 seed) {
  // Generate a random offset
  uint frameJitter = hashPCG(uint(frameCounter));
  // Jitter and wrap the coordinates.
  ivec2 sampleCoords = (seed + int(frameJitter)) % noiseTextureResolution;
  return texelFetch(noisetex, sampleCoords, 0);
}

#endif