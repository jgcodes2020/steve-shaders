#ifndef SHADOW_GLSL_INCLUDED
#define SHADOW_GLSL_INCLUDED

#include "/lib/util.glsl"

const float DISTORT_A      = 0.2;
const float DISTORT_DU0_DX = DISTORT_A + (1 / DISTORT_A);

const float SHADOW_MIN_RADIUS   = 0.5;
const float SHADOW_MAX_RADIUS   = 1.5;
const float SHADOW_RADIUS_SCALE = 7.0;

// Distorts positions in shadow space to enlarge shadows near the player
vec3 shadowDistort(vec3 clipPos) {
  // XY distortion function:
  //  (a + 1) * R
  // -------------
  // a + l4norm(R)
  // The extra (a + 1) factor on top improves usage of clip space by
  // stretching the furthest points to r = 1.
  // The use of the 4-norm also does, since the squircle shape makes
  // better use of the shadow map.

  vec2 hpos   = clipPos.xy;
  float denom = l4norm(hpos) + DISTORT_A;
  clipPos.xy  = fma(hpos, vec2(DISTORT_A), hpos) / denom;

  // Reduce range in Z. This apparently helps when the sun is lower in the sky.
  clipPos.z *= 0.5;

  return clipPos;
}

// Distorts the shadow position in XY only.
vec2 shadowDistortH(vec2 clipPos) {
  float denom = l4norm(clipPos) + DISTORT_A;
  return fma(clipPos, vec2(DISTORT_A), clipPos) / denom;
}

// Computes the Jacobian of the distortion function.
// If we define the distorted coordinates as (u, v) and undistorted as (x, y),
// this function compute (du/dx) and (dv/dy).
mat2 distortJacobian(vec2 clipPos) {
  // Expression for du/dx:
  //   (a + 1) * [a * (x^4 + y^4)^(3/4) + y^4]
  // -------------------------------------------
  // (x^4 + y^4)^(3/4) * [a + (x^4 + y^4)^(1/4)]
  // Expression for du/dy:
  //              (a+1) * x * y^3
  // -------------------------------------------
  // (x^4 + y^4)^(3/4) * [a + (x^4 + y^4)^(1/4)]

  vec2 posP2  = clipPos * clipPos;
  vec2 posP3  = posP2 * clipPos;
  vec2 posP4  = posP2 * posP2;
  float sumP4 = posP4.x + posP4.y;

  float sumP4Pow12 = sqrt(sumP4);
  float sumP4Pow14 = sqrt(sumP4Pow12);
  float sumP4Pow34 = sumP4Pow12 * sumP4Pow14;

  vec2 diagNumer =
    fma(vec2(DISTORT_A), vec2(sumP4Pow34), posP4.yx) * (DISTORT_A + 1.0);
  vec2 offDiagNumer = posP3.yx * clipPos.xy * (DISTORT_A + 1.0);
  float denom       = sumP4Pow34 * (DISTORT_A + sumP4Pow14);

  vec2 diagEntries    = diagNumer / denom;
  vec2 offDiagEntries = offDiagNumer / denom;
  return mat2(diagEntries.x, offDiagEntries.y, offDiagEntries.x, diagEntries.y);
}

vec3 shadowBias(vec3 clipPos, vec3 worldNormal) {
  // project the normal into shadow space.
  vec3 shadowNormal =
    mat3(shadowProjection) * (mat3(shadowModelView) * worldNormal);
  // Multiply by the inverse of the distortion factor. This is an idea inspired
  // by Complementary, but adapted to my own shader.
  shadowNormal =
    shadowNormal * (DISTORT_A + l4norm(clipPos.xy)) / (DISTORT_A + 1);
  return shadowNormal;
}

vec4 screenToShadowClip(vec3 screenPos) {
  // Convert screen space to shadow view space
  vec3 ndcPos        = screenPos * 2.0 - 1.0;
  vec3 viewPos       = txProjective(gbufferProjectionInverse, ndcPos);
  vec3 feetPlayerPos = txAffine(gbufferModelViewInverse, viewPos);
  vec3 shadowViewPos = txAffine(shadowModelView, feetPlayerPos);

  // Convert to shadow clip space
  return shadowProjection * vec4(shadowViewPos, 1.0);
}

vec3 screenToShadowScreen(vec3 screenPos, vec3 normal, out vec3 clipPos) {
  // Convert screen space to shadow view space
  vec3 ndcPos        = screenPos * 2.0 - 1.0;
  vec3 viewPos       = txProjective(gbufferProjectionInverse, ndcPos);
  vec3 feetPlayerPos = txAffine(gbufferModelViewInverse, viewPos);
  vec3 shadowViewPos = txAffine(shadowModelView, feetPlayerPos);

  // Convert to shadow clip space, adjust coordinates
  vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
  shadowClipPos.xyz += shadowBias(shadowClipPos.xyz, normal);  // shadow bias
  clipPos = shadowClipPos.xyz / shadowClipPos.w;

  shadowClipPos.xyz = shadowDistort(shadowClipPos.xyz);  // shadow distortion

  // Do perspective divide, convert to screen-space
  vec3 shadowNdcPos = shadowClipPos.xyz / shadowClipPos.w;
  return shadowNdcPos * 0.5 + 0.5;
}

vec4[4] boxKernel(vec2 texcoord, vec2 radius) {
  vec2 fracParts = fract(texcoord * float(shadowMapResolution) - 0.5);

  // For a given coordinate:
  // left weight:   u + 0.5 + r - x
  // right weight: -u + 0.5 + r + x
  // then clamp to [0, 1].
  vec4 xWeights = vec4(-0.5, +0.5, -0.5, -1.5) + radius.x +
    vec4(vec2(-fracParts.x), vec2(fracParts.x));
  vec4 yWeights = vec4(-0.5, +0.5, -0.5, -1.5) + radius.y +
    vec4(vec2(-fracParts.y), vec2(fracParts.y));

  xWeights = clamp(xWeights, 0.0, 1.0);
  yWeights = clamp(yWeights, 0.0, 1.0);

  return vec4[](
    xWeights.xyyx * yWeights.wwzz, xWeights.zwwz * yWeights.wwzz,
    xWeights.zwwz * yWeights.yyxx, xWeights.xyyx * yWeights.yyxx);
}

// Samples a shadow texture using a precomputed 4x4 kernel.
// Kernel weights are multiplied by rcpSum.
float texture4x4Kernel(
  sampler2DShadow t, vec3 texcoord, vec4[4] kernel, float rcpSum) {
  const ivec2[4] offsets =
    ivec2[](ivec2(-1, +1), ivec2(+1, +1), ivec2(+1, -1), ivec2(-1, -1));
  vec4 accum = vec4(0.0);
  accum +=
    textureGatherOffset(t, texcoord.xy, texcoord.z, offsets[0]) * kernel[0];
  accum +=
    textureGatherOffset(t, texcoord.xy, texcoord.z, offsets[1]) * kernel[1];
  accum +=
    textureGatherOffset(t, texcoord.xy, texcoord.z, offsets[2]) * kernel[2];
  accum +=
    textureGatherOffset(t, texcoord.xy, texcoord.z, offsets[3]) * kernel[3];
  return dot(accum, vec4(rcpSum));
}
// Samples the alpha component of a texture using a precomputed 4x4 kernel.
// Kernel weights are multiplied by rcpSum.
float texture4x4Kernel_a(
  sampler2D t, vec2 texcoord, vec4[4] kernel, float rcpSum) {
  const ivec2[4] offsets =
    ivec2[](ivec2(-1, +1), ivec2(+1, +1), ivec2(+1, -1), ivec2(-1, -1));
  vec4 accum = vec4(0.0);
  accum += textureGatherOffset(t, texcoord, offsets[0], 3) * kernel[0];
  accum += textureGatherOffset(t, texcoord, offsets[1], 3) * kernel[1];
  accum += textureGatherOffset(t, texcoord, offsets[2], 3) * kernel[2];
  accum += textureGatherOffset(t, texcoord, offsets[3], 3) * kernel[3];
  return dot(accum, vec4(rcpSum));
}

// SOFT SHADOWS
// ===============================================

float testShadow(vec3 shadowScreenPos) {
  float test   = texture(shadowtex1, shadowScreenPos);
  float tlTest = texture(shadowtex0, shadowScreenPos);
  float alpha  = texture(shadowcolor0, shadowScreenPos.xy).a;

  return max(tlTest, max(test - alpha, 0.0));
}

float computeShadowSoft(vec4 shadowClipPos, vec3 normal, ivec2 pixelCoord) {
  const int sampleCount = ST_SHADOW_SAMPLES * ST_SHADOW_SAMPLES * 4;
  const float offsetMul =
    ST_SHADOW_RADIUS / (float(ST_SHADOW_SAMPLES) * shadowMapResolution);

  float theta = sampleNoise(pixelCoord).r * MF_TWO_PI;
  mat2 rot    = rotationMatrix(theta) * offsetMul;

  float accum = 0.0;
  for (int x = -ST_SHADOW_SAMPLES; x < ST_SHADOW_SAMPLES; x++) {
    for (int y = -ST_SHADOW_SAMPLES; y < ST_SHADOW_SAMPLES; y++) {
      // compute offset, divide by shadow map resolution to put it in pixels
      vec2 offset = rot * vec2(x, y);
      // bias and distort the clip space position
      vec4 offsetShadowClipPos = shadowClipPos + vec4(offset, 0.0, 0.0);
      offsetShadowClipPos.xyz += shadowBias(offsetShadowClipPos.xyz, normal);
      offsetShadowClipPos.xyz = shadowDistort(offsetShadowClipPos.xyz);
      // convert to screen space
      vec3 shadowNdcPos    = offsetShadowClipPos.xyz;
      vec3 shadowScreenPos = fma(shadowNdcPos, vec3(0.5), vec3(0.5));
      // add the shadow test from this pixel
      accum += testShadow(shadowScreenPos);
    }
  }

  return accum / float(sampleCount);
}

float tlTestShadow(vec3 shadowScreenPos, float alpha) {
  float tlTest = texture(shadowtex0, shadowScreenPos);
  return tlTest;
}

float tlComputeShadowSoft(
  vec4 shadowClipPos, float alpha, vec3 normal, ivec2 pixelCoord) {
  const int sampleCount = ST_SHADOW_SAMPLES * ST_SHADOW_SAMPLES * 4;
  const float offsetMul =
    ST_SHADOW_RADIUS / (float(ST_SHADOW_SAMPLES) * shadowMapResolution);

  float theta = sampleNoise(pixelCoord).r * MF_TWO_PI;
  mat2 rot    = rotationMatrix(theta) * offsetMul;

  float accum = 0.0;
  for (int x = -ST_SHADOW_SAMPLES; x < ST_SHADOW_SAMPLES; x++) {
    for (int y = -ST_SHADOW_SAMPLES; y < ST_SHADOW_SAMPLES; y++) {
      // compute offset, divide by shadow map resolution to put it in pixels
      vec2 offset = rot * vec2(x, y);
      // bias and distort the clip space position
      vec4 offsetShadowClipPos = shadowClipPos + vec4(offset, 0.0, 0.0);
      offsetShadowClipPos.xyz += shadowBias(offsetShadowClipPos.xyz, normal);
      offsetShadowClipPos.xyz = shadowDistort(offsetShadowClipPos.xyz);
      // convert to screen space
      vec3 shadowNdcPos    = offsetShadowClipPos.xyz;
      vec3 shadowScreenPos = fma(shadowNdcPos, vec3(0.5), vec3(0.5));
      // add the shadow test from this pixel
      accum += tlTestShadow(shadowScreenPos, alpha);
    }
  }

  return accum / float(sampleCount);
}

#endif