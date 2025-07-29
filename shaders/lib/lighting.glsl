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

vec3 screenToShadowScreen(vec3 screenPos, vec3 worldNormal) {
	// Convert screen space to shadow view space
	vec3 ndcPos = screenPos * 2.0 - 1.0;
  vec3 viewPos = txProjective(gbufferProjectionInverse, ndcPos);
	vec3 feetPlayerPos = txAffine(gbufferModelViewInverse, viewPos);
	vec3 shadowViewPos = txAffine(shadowModelView, feetPlayerPos);

	// Convert to shadow clip space, adjust coordinates
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
	shadowClipPos.z -= 0.005; // shadow bias
	shadowClipPos.xyz = shadowDistort(shadowClipPos.xyz); // shadow distortion

	// Do perspective divide, convert to screen-space
	vec3 shadowNdcPos = shadowClipPos.xyz / shadowClipPos.w;
	return shadowNdcPos * 0.5 + 0.5;
}

/*
// This is the reference hard-shadow implementation.
float computeShadow(vec3 shadowScreenPos) {
	float test = texture(shadowtex1, shadowScreenPos);
	float tlTest = texture(shadowtex0, shadowScreenPos);

	if (test == 0.0) {
		return 0.0;
	}
	if (tlTest == 1.0) {
		return 1.0;
	}
	return 1.0 - texture(shadowcolor0, shadowScreenPos.xy).a;
}
*/

float computeShadow(vec3 shadowScreenPos) {
	float test = texture(shadowtex1, shadowScreenPos);
	float tlTest = texture(shadowtex0, shadowScreenPos);
	float alpha = texture(shadowcolor0, shadowScreenPos.xy).a;

	return max(tlTest, max(test - alpha, 0.0));
}

#endif