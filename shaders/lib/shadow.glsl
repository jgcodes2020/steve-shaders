#ifndef SHADOW_GLSL_INCLUDED
#define SHADOW_GLSL_INCLUDED

#include "/lib/util.glsl"

const float SHADOW_DISTORTION = 0.1;

const float SHADOW_FAR_THRESH = 0.4;

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

vec4[4] shadowBilinearKernel(vec2 texcoord) {
	// Kernel:
	// fc1.x * fc0.y, fc0.y,         fc0.y,         fc0.x * fc0.y,
	// fc1.x,         1.0,           1.0,           fc0.x,
	// fc1.x,         1.0,           1.0,           fc0.x,
	// fc1.x * fc1.y, fc1.y,         fc1.y,         fc0.x * fc1.y,
	// textureGather order:
	// x y
	// w z
	// Factors are grouped by quadrant, since GPUs are much better
	// at sampling in 2x2 chunks.
	vec2 fc0 = fract(texcoord * float(shadowMapResolution) - 0.5);
	vec2 fc1 = vec2(1.0) - fc0;
	return vec4[](
		vec4(fc1.x * fc0.y, fc0.y, 1.0, fc1.x),
		vec4(fc0.y, fc0.x * fc0.y, fc0.x, 1.0),
		vec4(1.0, fc0.x, fc0.x * fc1.y, fc1.y),
		vec4(fc1.x, 1.0, fc1.y, fc1.x * fc1.y)
	);
}

// Samples a shadow texture using a precomputed 4x4 bilinear kernel.
// Kernel weights are expected to add to 9.
float texture4x4Kernel(sampler2DShadow t, vec3 texcoord, vec4[4] kernel) {
	const ivec2[4] offsets = ivec2[](
		ivec2(-1, +1),
		ivec2(+1, +1),
		ivec2(+1, -1),
		ivec2(-1, -1)
	);
	vec4 accum = vec4(0.0);
	accum += textureGatherOffset(t, texcoord.xy, texcoord.z, offsets[0]) * kernel[0];
	accum += textureGatherOffset(t, texcoord.xy, texcoord.z, offsets[1]) * kernel[1];
	accum += textureGatherOffset(t, texcoord.xy, texcoord.z, offsets[2]) * kernel[2];
	accum += textureGatherOffset(t, texcoord.xy, texcoord.z, offsets[3]) * kernel[3];
	return dot(accum, vec4(1.0 / 9.0));
}
// Samples the alpha component of a texture using a precomputed 4x4 bilinear kernel.
// Kernel weights are expected to add to 9.
float texture4x4Kernel_a(sampler2D t, vec2 texcoord, vec4[4] kernel) {
	const ivec2[4] offsets = ivec2[](
		ivec2(-1, +1),
		ivec2(+1, +1),
		ivec2(+1, -1),
		ivec2(-1, -1)
	);
	vec4 accum = vec4(0.0);
	accum += textureGatherOffset(t, texcoord, offsets[0], 3) * kernel[0];
	accum += textureGatherOffset(t, texcoord, offsets[1], 3) * kernel[1];
	accum += textureGatherOffset(t, texcoord, offsets[2], 3) * kernel[2];
	accum += textureGatherOffset(t, texcoord, offsets[3], 3) * kernel[3];
	return dot(accum, vec4(1.0 / 9.0));
}

// SOFT SHADOWS
// ===============================================
// This is pretty much a vectorized version of PCF. It does suffer from
// being pixelated.

float computeShadowSoft(vec3 shadowScreenPos) {
	float norm = l4norm((shadowScreenPos.xy - 0.5) * 2.0);
	// box blur kernel

	if (true) {
		// 4x4 bilinear PCF
		vec4[4] kernel = shadowBilinearKernel(shadowScreenPos.xy);
		float test = texture4x4Kernel(shadowtex1, shadowScreenPos, kernel);
		float tlTest = texture4x4Kernel(shadowtex0, shadowScreenPos, kernel);
		float alpha = texture4x4Kernel_a(shadowcolor0, shadowScreenPos.xy, kernel);
		return max(tlTest, max(test - alpha, 0.0));
	}
	else {
		// 2x2 PCF (built into GPU sampling)
		float test = texture(shadowtex1, shadowScreenPos);
		float tlTest = texture(shadowtex0, shadowScreenPos);
		float alpha = texture(shadowcolor0, shadowScreenPos.xy).a;

		return max(tlTest, max(test - alpha, 0.0));
	}
}

float tlComputeShadowSoft(vec3 shadowScreenPos, float alpha) {
	vec4 accum = vec4(0.0);
	float norm = l4norm((shadowScreenPos.xy - 0.5) * 2.0);

	if (norm < SHADOW_FAR_THRESH) {
		// 2x2 PCF
		vec4[4] kernel = shadowBilinearKernel(shadowScreenPos.xy);
		float tlTest = texture4x4Kernel(shadowtex0, shadowScreenPos, kernel);
		return max(tlTest, 1.0 - alpha);
	}
	else {
		// 2x2 PCF
		float tlTest = texture(shadowtex0, shadowScreenPos);
		return max(tlTest, 1.0 - alpha);
	}
}

#endif