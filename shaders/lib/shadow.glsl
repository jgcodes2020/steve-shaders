#ifndef SHADOW_GLSL_INCLUDED
#define SHADOW_GLSL_INCLUDED

#include "/lib/util.glsl"

const float SHADOW_DISTORTION = 0.1;

const float SHADOW_MID_THRESH = 0.4;
const float SHADOW_FAR_THRESH = 0.95;

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

#endif