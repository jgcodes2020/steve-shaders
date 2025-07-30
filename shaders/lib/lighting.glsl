#ifndef LIGHTING_GLSL_INCLUDED
#define LIGHTING_GLSL_INCLUDED

#include "/lib/shadow.glsl"
#include "/lib/util.glsl"

// sRGB: 252, 252, 222
const vec3 blockLightColor = vec3(0.974, 0.974, 0.737);
const vec3 ambientColor = vec3(0.1);

const vec3 dayLightColor = vec3(1.0, 1.0, 1.0);
const vec3 nightLightColor = vec3(0.02, 0.05, 0.1);

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

const float SHADOW_MID_THRESH = 0.4;
const float SHADOW_FAR_THRESH = 0.95;

// SHADOW-SPACE TRANSFORMATIONS
// ===============================================

vec3 shadowBias(vec3 clipPos, vec3 worldNormal) {
	// project the normal into shadow space.
	vec3 shadowNormal = mat3(shadowProjection) * (mat3(shadowModelView) * worldNormal);
	// Multiply by the inverse of the distortion factor. This is an idea inspired by
	// Complementary, but adapted to my own shader.
	shadowNormal = shadowNormal * (SHADOW_DISTORTION + length(clipPos.xy)) / (SHADOW_DISTORTION + 1);
	return shadowNormal;
}

vec3 screenToShadowScreen(vec3 screenPos, vec3 normal) {
	// Convert screen space to shadow view space
	vec3 ndcPos = screenPos * 2.0 - 1.0;
  vec3 viewPos = txProjective(gbufferProjectionInverse, ndcPos);
	vec3 feetPlayerPos = txAffine(gbufferModelViewInverse, viewPos);
	vec3 shadowViewPos = txAffine(shadowModelView, feetPlayerPos);

	// Convert to shadow clip space, adjust coordinates
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
	shadowClipPos.xyz += shadowBias(shadowClipPos.xyz, normal); // shadow bias
	shadowClipPos.xyz = shadowDistort(shadowClipPos.xyz); // shadow distortion

	// Do perspective divide, convert to screen-space
	vec3 shadowNdcPos = shadowClipPos.xyz / shadowClipPos.w;
	return shadowNdcPos * 0.5 + 0.5;
}

// LIGHTING MODEL
// ===============================================

struct LightingInfo {
	vec4 color;
	vec2 lightmap;
	uint lightFlags;
	vec3 normal;
	float depth;

	vec4 tlColor;
	vec2 tlLightmap;
	uint tlLightFlags;
	vec3 tlNormal;
	float tlDepth;
};

bool readLightInfo(vec2 texcoord, out LightingInfo info) {
	// Fetch data values
	vec4 color1Sample = texture(colortex1, texcoord);
	vec4 color5Sample = texture(colortex5, texcoord);

	info = LightingInfo(
		texture(colortex0, texcoord), // color
		color1Sample.rg, // lightmap
		colorToFlags(color1Sample.b), // lightFlags
		colorToNormal(texture(colortex2, texcoord)), // normal
		texture(depthtex1, texcoord).r, // depth
		texture(colortex4, texcoord), // tlColor
		color5Sample.rg, // tlLightmap
		colorToFlags(color5Sample.b), // tlLightFlags
		colorToNormal(texture(colortex6, texcoord)), // tlNormal
		texture(depthtex0, texcoord).r // tlDepth
	);

	// Check if this fragment can be skipped
	if (info.depth + info.tlDepth == 2.0) {
		color = info.color;
		return true;
	}
	
	// gamma corection
	info.color.rgb = pow(info.color.rgb, vec3(SRGB_GAMMA));
	info.lightmap.rg = pow(info.lightmap.rg, vec2(SRGB_GAMMA));

	info.tlColor.rgb = pow(info.tlColor.rgb, vec3(SRGB_GAMMA));
	info.tlLightmap.rg = pow(info.tlLightmap.rg, vec2(SRGB_GAMMA));
	return false;
}

void diffuseLighting(inout LightingInfo info) {
	// SHADOW-SPACE CALCULATIONS
	// ===============================================

	// vector to sunlight
	vec3 lightDir = txLinear(
		gbufferModelViewInverse, 
		normalize(shadowLightPosition)
	);

	vec3 shadowPos = screenToShadowScreen(vec3(texcoord, info.depth), info.normal);
	float shadow = computeShadowSoft(shadowPos);
	if ((info.lightFlags & LTG_NO_SHADOW) != 0) {
		shadow = 1.0;
	}

	vec3 tlShadowPos = screenToShadowScreen(vec3(texcoord, info.tlDepth), info.tlNormal);
	float tlShadow = tlComputeShadowSoft(tlShadowPos, info.tlColor.a);
	if ((info.tlLightFlags & LTG_NO_SHADOW) != 0) {
		tlShadow = 1.0;
	}

	// LIGHTING CONSTANTS
	// ===============================================

	float cosSunToUp = dot(normalize(sunPosition), gbufferModelView[1].xyz);
	float dayFactor = horizonStep(cosSunToUp, daySatAngle);
	float nightFactor = horizonStep(cosSunToUp, nightSatAngle);
	vec3 skyLightColor = dayFactor * dayLightColor + nightFactor * nightLightColor;
	vec3 skyAmbientColor = dayFactor * dayAmbientColor + nightFactor * nightAmbientColor;

	// OPAQUE LIGHTING
	// ===============================================

	if (info.depth < 1.0) {
		vec3 skyLight = skyLightColor * clamp(dot(lightDir, info.normal), 0.0, 1.0);
		vec3 skyTotal = skyAmbientColor * info.lightmap.g + skyLight * shadow;
		vec3 blockTotal = blockLightColor * info.lightmap.r;

		info.color.rgb *= (skyTotal + blockTotal);
	}

	// TRANSLUCENT LIGHTING
	// ===============================================

	if (info.tlDepth < 1.0) {
		vec3 tlSkyLight = skyLightColor * clamp(dot(lightDir, info.tlNormal), 0.0, 1.0);
		vec3 tlSkyTotal = skyAmbientColor * info.tlLightmap.g + tlSkyLight * tlShadow;
		vec3 tlBlockTotal = blockLightColor * info.tlLightmap.r;

		info.tlColor.rgb *= (tlSkyTotal + tlBlockTotal);
	}
}

// SOFT SHADOWS
// ===============================================
// This is pretty much a vectorized version of PCF. It does suffer from
// being pixelated.

float computeShadowSoft(vec3 shadowScreenPos) {
	float norm = length((shadowScreenPos.xy - 0.5) * 2.0);
	// box blur kernel
	#define GATHER_OFFSET(x, y) \
		do { \
			vec4 test = textureGatherOffset(shadowtex1, shadowScreenPos.xy, shadowScreenPos.z, ivec2(x, y)); \
			vec4 tlTest = textureGatherOffset(shadowtex0, shadowScreenPos.xy, shadowScreenPos.z, ivec2(x, y)); \
			vec4 alpha = textureGatherOffset(shadowcolor0, shadowScreenPos.xy, ivec2(x, y), 3); \
			accum += max(tlTest, max(test - alpha, vec4(0.0))); \
		} while (false)

	if (norm < SHADOW_MID_THRESH) {
		// 4x4 PCF
		vec4 accum = vec4(0.0);
		GATHER_OFFSET(-1, -1);
		GATHER_OFFSET(-1, +1);
		GATHER_OFFSET(+1, -1);
		GATHER_OFFSET(+1, +1);
		return dot(accum, vec4(1.0 / 16.0));
	}
	else if (norm < SHADOW_FAR_THRESH) {
		// 2x2 PCF
		vec4 accum = vec4(0.0);
		GATHER_OFFSET(0, 0);
		return dot(accum, vec4(1.0 / 4.0));
	}
	else {
		// Interpolated texture sample
		float test = texture(shadowtex1, shadowScreenPos);
		float tlTest = texture(shadowtex0, shadowScreenPos);
		float alpha = texture(shadowcolor0, shadowScreenPos.xy).a;

		return max(tlTest, max(test - alpha, 0.0));
	}

	#undef GATHER_OFFSET
}

float tlComputeShadowSoft(vec3 shadowScreenPos, float alpha) {
	vec4 accum = vec4(0.0);
	float norm = l4norm(shadowScreenPos.xy);
	
	#define GATHER_OFFSET(x, y) \
		do { \
			vec4 tlTest = textureGatherOffset(shadowtex0, shadowScreenPos.xy, shadowScreenPos.z, ivec2(x, y)); \
			accum += mix(vec4(1.0 - alpha), vec4(1.0), equal(tlTest, vec4(1.0))); \
		} while (false)

	if (norm < SHADOW_MID_THRESH) {
		vec4 accum = vec4(0.0);
		GATHER_OFFSET(-1, -1);
		GATHER_OFFSET(-1, +1);
		GATHER_OFFSET(+1, -1);
		GATHER_OFFSET(+1, +1);
		return dot(accum, vec4(1.0 / 16.0));
	}
	else if (norm < SHADOW_FAR_THRESH) {
		vec4 accum = vec4(0.0);
		GATHER_OFFSET(0, 0);
		return dot(accum, vec4(1.0 / 4.0));
	}
	else {
		float tlTest = texture(shadowtex0, shadowScreenPos);
		return (tlTest == 1.0) ? 1.0 : 1.0 - alpha;
	}

	#undef GATHER_OFFSET
}

vec3 reinhardJodie(vec3 v) {
	float l = dot(v, LUMA_COEFFS);
	vec3 tv = v / (1.0 + v);
	return mix(v / (1.0 + l), tv, tv);
}


#endif