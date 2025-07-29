#ifndef SHADOW_GLSL_INCLUDED
#define SHADOW_GLSL_INCLUDED

#include "/lib/util.glsl"

const int shadowMapResolution = 2048;
const float shadowDistance = 160.0;
const bool shadowHardwareFiltering = true;

const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;
const bool shadowcolor0Nearest = true;

const float SHADOW_DISTORTION = 0.2;

float l4norm(vec2 pos) {
  pos *= pos;
  float sum = dot(pos, pos);
  return sqrt(sqrt(sum));
}

// Distorts positions in shadow space to enlarge shadows near the player
vec3 shadowDistort(vec3 clipPos) {

  // General XY distortion function:
  // (a + 1) * R
  // -----------
  // a + norm(R)
  // The extra (a + 1) factor on top improves usage of clip space by 
  // stretching the furthest points to r = 1.
  // The norm function may be any p-norm, but I've chosen the 4-norm since
  // it's easier to compute.

  vec2 hpos = clipPos.xy;
  float denom = l4norm(hpos) + SHADOW_DISTORTION;
  clipPos.xy = fma(hpos, vec2(SHADOW_DISTORTION), hpos) / denom;

  // Reduce range in Z. This apparently helps when the sun is lower in the sky.
  clipPos.z *= 0.5;

  return clipPos;
}

#endif