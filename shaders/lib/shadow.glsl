#ifndef SHADOW_GLSL_INCLUDED
#define SHADOW_GLSL_INCLUDED

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

vec3 shadowViewToScreen(vec3 shadowViewPos) {
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
	shadowClipPos.z -= 0.001; // shadow bias
	shadowClipPos.xyz = distortShadowClipPos(shadowClipPos.xyz);
	vec3 shadowNdcPos = shadowClipPos.xyz / shadowClipPos.w;
	vec3 shadowScreenPos = shadowNdcPos * 0.5 + 0.5;
	return shadowScreenPos;
}

float pcfShadowTexture(sampler2DShadow shadowtex, vec3 shadowScreenPos) {
  vec4 accum = vec4(0.0);

  accum += textureGatherOffset(shadowtex, shadowScreenPos.xy, shadowScreenPos.z, ivec2(-1, -1));
  accum += textureGatherOffset(shadowtex, shadowScreenPos.xy, shadowScreenPos.z, ivec2(-1, +1));
  accum += textureGatherOffset(shadowtex, shadowScreenPos.xy, shadowScreenPos.z, ivec2(+1, -1));
  accum += textureGatherOffset(shadowtex, shadowScreenPos.xy, shadowScreenPos.z, ivec2(+1, +1));

  return dot(accum, vec4(1.0 / 16.0));
}

const int shadowMapResolution = 2048;
const bool shadowHardwareFiltering = true;

#endif