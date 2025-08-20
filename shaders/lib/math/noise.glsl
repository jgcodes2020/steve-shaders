#ifndef MATH_NOISE_GLSL_INCLUDED
#define MATH_NOISE_GLSL_INCLUDED

#include "/lib/pipeline_config.glsl"

// Samples the noise texture, seeded by pixel coordinates.
vec4 sampleNoise(ivec2 pixelCoords) {
  // The noise texture has a power-of-two size, so any odd number is to it.
  // This helps break up any regularity that might be visible.
  int frameJitter = frameCounter * 2 + 1;
  ivec2 sampleCoords = (pixelCoords * frameJitter) % noiseTextureResolution;
  return texelFetch(noisetex, sampleCoords, 0);
}

#endif