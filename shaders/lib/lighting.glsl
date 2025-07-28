#ifndef LIGHTING_GLSL_INCLUDED
#define LIGHTING_GLSL_INCLUDED

#include "/lib/shadow.glsl"
#include "/lib/util.glsl"

// sRGB: 252, 252, 222
const vec3 blockLightColor = vec3(0.974, 0.974, 0.737);
const vec3 ambientColor = vec3(0.1);

const vec3 dayLightColor = vec3(1.0, 1.0, 1.0);
const vec3 nightLightColor = vec3(0.00, 0.01, 0.05);

const vec3 dayAmbientColor = vec3(0.15, 0.15, 0.15);
const vec3 nightAmbientColor = vec3(0.05, 0.05, 0.05);

// Angle cosines relative to the horizon where full
// brightness should be achieved.
// sin(25)  ~  0.258819
// sin(-10) ~ -0.173648
const float daySatAngle = 0.258819;
const float nightSatAngle = -0.173648;

// notes from vanilla lighting implementation
// sunrise: 22800 to 1000
// sunset: 11300 to 13200
// -> night: sun is ~10 degrees below horizon (theta = 100)
// -> day: sun is ~25 degrees above horizon (theta = 75)

// Ease-out transition between 0 and the saturation point.
float horizonStep(float cosSunToUp, float satPoint) {
	float x = clamp(cosSunToUp / satPoint, 0.0, 1.0);
	// quadratic ease-out
	float xm1 = x - 1.0;
	return 1.0 - xm1 * xm1;
}

vec3 shadowViewToScreen(vec3 shadowViewPos) {
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
	shadowClipPos.z -= 0.005; // shadow bias
	shadowClipPos.xyz = distortShadowClipPos(shadowClipPos.xyz);
	vec3 shadowNdcPos = shadowClipPos.xyz / shadowClipPos.w;
	vec3 shadowScreenPos = shadowNdcPos * 0.5 + 0.5;
	return shadowScreenPos;
}

vec3 screenToShadowScreen(vec2 texcoord, float depth) {
	vec3 ndcPos = vec3(texcoord, depth) * 2.0 - 1.0;
  vec3 viewPos = txProjective(gbufferProjectionInverse, ndcPos);
	vec3 feetPlayerPos = txAffine(gbufferModelViewInverse, viewPos);
	vec3 shadowViewPos = txAffine(shadowModelView, feetPlayerPos);
  return shadowViewToScreen(shadowViewPos);
}

float pcfShadowTexture(sampler2DShadow shadowtex, vec3 shadowScreenPos) {
  vec4 accum = vec4(0.0);

  accum += textureGatherOffset(shadowtex, shadowScreenPos.xy, shadowScreenPos.z, ivec2(-1, -1));
  accum += textureGatherOffset(shadowtex, shadowScreenPos.xy, shadowScreenPos.z, ivec2(-1, +1));
  accum += textureGatherOffset(shadowtex, shadowScreenPos.xy, shadowScreenPos.z, ivec2(+1, -1));
  accum += textureGatherOffset(shadowtex, shadowScreenPos.xy, shadowScreenPos.z, ivec2(+1, +1));

  return dot(accum, vec4(1.0 / 16.0));
}

#endif