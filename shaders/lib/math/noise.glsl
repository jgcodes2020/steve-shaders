#ifndef MATH_NOISE_GLSL_INCLUDED
#define MATH_NOISE_GLSL_INCLUDED

#include "/lib/pipeline_config.glsl"

//! Useful functions for generating noise.

// Samples the noise texture, seeded by pixel coordinates.
vec4 sampleNoise(ivec2 seed) {
  // The noise texture has a power-of-two size, so any odd number is coprime to the size.
  // This keeps the noise from being "fixed" to the screen.
  int frameJitter = frameCounter * 2 + 1;
  // Jitter and wrap the coordinates.
  ivec2 sampleCoords = (seed * frameJitter) % noiseTextureResolution;
  return texelFetch(noisetex, sampleCoords, 0);
}

#endif