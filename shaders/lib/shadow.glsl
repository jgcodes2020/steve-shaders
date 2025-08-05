#ifndef SHADOW_GLSL_INCLUDED
#define SHADOW_GLSL_INCLUDED

#include "/lib/util.glsl"

const float DISTORT_A      = 0.2;
const float DISTORT_DU0_DX = DISTORT_A + (1 / DISTORT_A);

const float SHADOW_MIN_RADIUS   = 0.5;
const float SHADOW_MAX_RADIUS   = 1.5;
const float SHADOW_RADIUS_SCALE = 7.0;

// Distorts a position in clip space to capture more detail near the center
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

// Biases a position in clip space to avoid shadow acne.
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

// Converts screen-space coordinates to clip space.
vec4 screenToShadowClip(vec3 screenPos) {
  // Convert screen space to shadow view space
  vec3 ndcPos        = screenPos * 2.0 - 1.0;
  vec3 viewPos       = txProjective(gbufferProjectionInverse, ndcPos);
  vec3 feetPlayerPos = txAffine(gbufferModelViewInverse, viewPos);
  vec3 shadowViewPos = txAffine(shadowModelView, feetPlayerPos);

  // Convert to shadow clip space
  return shadowProjection * vec4(shadowViewPos, 1.0);
}

// SOFT SHADOWS
// ===============================================
// PCF with shadow distortion is by far the best way to get good-looking shadows
// in Iris's current pipeline. Ideally we'd be using other techniques but
// this is as good as it gets with one shadow pass.

// The shadow test for opaque surfaces.
// Takes into account the transparency of the surface but not its colour.
float testShadow(vec3 shadowScreenPos) {
  float test   = texture(shadowtex1, shadowScreenPos);
  float tlTest = texture(shadowtex0, shadowScreenPos);
  float alpha  = texture(shadowcolor0, shadowScreenPos.xy).a;

  return max(tlTest, max(test - alpha, 0.0));
}

// Function to perform PCF over an opaque surface.
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

// The shadow test for translucent surfaces.
float tlTestShadow(vec3 shadowScreenPos, float alpha) {
  float test = texture(shadowtex1, shadowScreenPos);
  return max(test, 1.0 - alpha);
}

// Function to perform PCF over a translucent surface.
float tlComputeShadowSoft(
  vec4 shadowClipPos, float alpha, vec3 normal, ivec2 pixelCoord) {
  const int sampleCount = ST_SHADOW_SAMPLES * ST_SHADOW_SAMPLES * 4;
  const float offsetMul =
    ST_SHADOW_RADIUS / (float(ST_SHADOW_SAMPLES) * shadowMapResolution);

  // float theta = sampleNoise(pixelCoord).r * MF_TWO_PI;
  // mat2 rot    = rotationMatrix(theta) * offsetMul;

  float accum = 0.0;
  for (int x = -ST_SHADOW_SAMPLES; x < ST_SHADOW_SAMPLES; x++) {
    for (int y = -ST_SHADOW_SAMPLES; y < ST_SHADOW_SAMPLES; y++) {
      // compute offset, divide by shadow map resolution to put it in pixels
      vec2 offset = offsetMul * vec2(x, y);
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