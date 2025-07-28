#ifndef SHADOW_GLSL_INCLUDED
#define SHADOW_GLSL_INCLUDED

#include "/lib/util.glsl"

// Perform shadow distortion to improve shadows near to the player.
vec3 distortShadowClipPos(vec3 shadowClipPos){
  // distort geometry by distance from player
  float distortionFactor = length(shadowClipPos.xy);
  // very small distances can cause issues so we add this to slightly reduce the distortion
  distortionFactor += 0.1;

  shadowClipPos.xy /= distortionFactor;
  // increases shadow distance on the Z axis, which helps when the sun is very low in the sky
  shadowClipPos.z *= 0.5;
  return shadowClipPos;
}

vec3 screenToView(vec2 texcoord, float depth) {
	vec3 ndcPos = vec3(texcoord, depth) * 2.0 - 1.0;
	return txProjective(gbufferProjectionInverse, ndcPos);
}

const int shadowMapResolution = 2048;
const bool shadowHardwareFiltering = true;

#endif