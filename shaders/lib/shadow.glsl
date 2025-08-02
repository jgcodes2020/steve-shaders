#ifndef SHADOW_GLSL_INCLUDED
#define SHADOW_GLSL_INCLUDED

#include "/lib/util.glsl"

const float DISTORT_A = 0.2;
const float DISTORT_DU0_DX = DISTORT_A + (1 / DISTORT_A);

const float SHADOW_MIN_RADIUS = 0.5;
const float SHADOW_MAX_RADIUS = 1.5;
const float SHADOW_RADIUS_SCALE = 6.0;

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

  vec2 hpos = clipPos.xy;
  float denom = l4norm(hpos) + DISTORT_A;
  clipPos.xy = fma(hpos, vec2(DISTORT_A), hpos) / denom;

  // Reduce range in Z. This apparently helps when the sun is lower in the sky.
  clipPos.z *= 0.5;

  return clipPos;
}
// Computes the diagonal entries of the Jacobian of the distortion function.
// i.e. (du/dx), (dv/dy). This gives an approximate scaling for the box kernel.
vec2 distortJacobianDiag(vec2 clipPos) {
  // Partial derivative (wrt. x):
  //   (a + 1) * [a * (x^4 + y^4)^(3/4) + y^4]
  // -------------------------------------------
  // (x^4 + y^4)^(3/4) * [a + (x^4 + y^4)^(1/4)]

  vec2 posP2 = clipPos * clipPos;
  vec2 posP4 = posP2 * posP2;
  float sumP4 = dot(posP2, posP2);

  float sumP4Pow12 = sqrt(sumP4);
  float sumP4Pow14 = sqrt(sumP4Pow12);
  float sumP4Pow34 = sumP4Pow12 * sumP4Pow14;

  vec2 numer = fma(vec2(DISTORT_A), vec2(sumP4Pow34), posP4) * (DISTORT_A + 1.0);
  float denom = sumP4Pow34 * (DISTORT_A + sumP4Pow14);
  return numer / denom;
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
  return vec4[](vec4(fc1.x * fc0.y, fc0.y, 1.0, fc1.x),
                vec4(fc0.y, fc0.x * fc0.y, fc0.x, 1.0),
                vec4(1.0, fc0.x, fc0.x * fc1.y, fc1.y),
                vec4(fc1.x, 1.0, fc1.y, fc1.x * fc1.y));
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

  return vec4[](xWeights.xyyx * yWeights.wwzz, xWeights.zwwz * yWeights.wwzz,
                xWeights.zwwz * yWeights.yyxx, xWeights.xyyx * yWeights.yyxx);
}

// Samples a shadow texture using a precomputed 4x4 kernel.
// Kernel weights are multiplied by rcpSum.
float texture4x4Kernel(sampler2DShadow t, vec3 texcoord, vec4[4] kernel, float rcpSum) {
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
float texture4x4Kernel_a(sampler2D t, vec2 texcoord, vec4[4] kernel, float rcpSum) {
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
// This is pretty much a vectorized version of PCF. It does suffer from
// being pixelated.

float computeShadowSoft(vec3 shadowScreenPos) {
  vec2 clipXY = (shadowScreenPos.xy - 0.5) * 2.0;

  vec2 radiusScale = distortJacobianDiag(clipXY) / DISTORT_DU0_DX;
  vec2 radius = clamp(radiusScale * SHADOW_RADIUS_SCALE, SHADOW_MIN_RADIUS, SHADOW_MAX_RADIUS);
  float rcpSum = 1 / (2.0 * radius.x * radius.y);

  vec4[4] kernel = boxKernel(shadowScreenPos.xy, radius);
  float test = texture4x4Kernel(shadowtex1, shadowScreenPos, kernel, rcpSum);
  float tlTest = texture4x4Kernel(shadowtex0, shadowScreenPos, kernel, rcpSum);
  float alpha = texture4x4Kernel_a(shadowcolor0, shadowScreenPos.xy, kernel, rcpSum);
  return max(tlTest, max(test - alpha, 0.0));
}

float tlComputeShadowSoft(vec3 shadowScreenPos, float alpha) {
  vec2 clipXY = (shadowScreenPos.xy - 0.5) * 2.0;

  vec2 radiusScale = distortJacobianDiag(clipXY) / DISTORT_DU0_DX;
  vec2 radius = clamp(radiusScale * SHADOW_RADIUS_SCALE, SHADOW_MIN_RADIUS, SHADOW_MAX_RADIUS);
  float rcpSum = 1 / (2.0 * radius.x * radius.y);

  vec4[4] kernel = boxKernel(shadowScreenPos.xy, radius);
  float tlTest = texture4x4Kernel(shadowtex0, shadowScreenPos, kernel, rcpSum);
  return max(tlTest, 1.0 - alpha);
}

#endif