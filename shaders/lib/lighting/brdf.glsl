#ifndef LIGHTING_BRDF_GLSL_INCLUDED
#define LIGHTING_BRDF_GLSL_INCLUDED
#include "/lib/math/misc.glsl"

// Trowbridge-Reitz GGX distribution function
float brdfDistribution(vec3 normal, vec3 halfDir, float spAlpha) {
  float alpha2 = pow2(spAlpha);
  float nDotH  = clampDot(normal, halfDir);

  return alpha2 / (M_PI * pow2(pow2(nDotH) * pow2(alpha2 - 1.0) + 1.0));
}

// Schlick-GGX geometry function with Smith's method
float brdfGeometry(vec3 normal, vec3 lightDir, vec3 viewDir, float spAlpha) {
  float k     = pow2(spAlpha + 1.0) * 0.125;
  float nDotL = clampDot(normal, lightDir);
  float nDotV = clampDot(normal, viewDir);

  float numerL = nDotL;
  float denomL = nDotL * (1.0 - k) + k;

  float numerV = nDotV;
  float denomV = nDotV * (1.0 - k) + k;

  return (numerL * numerV) / (denomL * denomV);
}

float brdfFresnel(vec3 viewDir, vec3 halfDir, float spF0) {
  float rhsTerm = 1.0 - clampDot(viewDir, halfDir);
  return spF0 + (1.0 - spF0) * pow(rhsTerm, 5.0);
}

// final Cook-Torrance BRDF. Note that this already includes
// the N dot L term, so this should not be multiplied in after.
vec3 brdf(
  vec3 normal, vec3 lightDir, vec3 viewDir, vec3 color, float spAlpha,
  float spF0) {
  vec3 halfDir = normalize(lightDir + viewDir);

  float nDotL = clampDot(normal, lightDir);
  float nDotV = clampDot(normal, viewDir);

  float d = brdfDistribution(normal, halfDir, spAlpha);
  float g = brdfGeometry(normal, lightDir, viewDir, spAlpha);

  float f = brdfFresnel(viewDir, halfDir, spF0);

  vec3 diffuse  = color * nDotL / M_PI;
  vec3 specular = vec3((d * g) / max(4.0 * nDotV, 0.1));
  return mix(diffuse, specular, f);
}

#endif