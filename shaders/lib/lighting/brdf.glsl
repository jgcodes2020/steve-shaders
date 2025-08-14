#ifndef LIGHTING_BRDF_GLSL_INCLUDED
#define LIGHTING_BRDF_GLSL_INCLUDED
#include "/lib/math/misc.glsl"

// Trowbridge-Reitz GGX distribution function
float brdfDistribution(vec3 normal, vec3 halfDir, float spAlpha) {
  float alpha2 = pow2(spAlpha);
  float nDotH  = dot(normal, halfDir);

  return alpha2 / (M_PI * pow2(pow2(nDotH) * pow2(alpha2 - 1.0) + 1.0));
}

// Schlick-GGX geometry function with Smith's method
float brdfGeometry(vec3 normal, vec3 lightDir, vec3 viewDir, float spAlpha) {
  float k     = pow2(spAlpha + 1.0) * 0.125;
  float nDotL = dot(normal, lightDir);
  float nDotV = dot(normal, viewDir);

  float numerL = nDotL;
  float denomL = nDotL * (1.0 - k) + k;

  float numerV = nDotV;
  float denomV = nDotV * (1.0 - k) + k;

  return (numerL * numerV) / (denomL * denomV);
}

float brdfFresnel(vec3 halfDir, vec3 viewDir, float spF0) {
  float rhsTerm = 1.0 - dot(halfDir, viewDir);

  float rhsTerm2 = rhsTerm * rhsTerm;
  float rhsTerm3 = rhsTerm2 * rhsTerm;
  float rhsTerm5 = rhsTerm2 * rhsTerm3;

  return mix(1.0, rhsTerm5, spF0);
}

// final Cook-Torrance BRDF
vec3 brdf(
  vec3 normal, vec3 lightDir, vec3 viewDir, vec3 color, float spAlpha,
  float spF0) {
  vec3 halfDir = normalize(lightDir + viewDir);

  float nDotL = dot(normal, lightDir);
  float nDotV = dot(normal, viewDir);

  float d = brdfDistribution(normal, halfDir, spAlpha);
  float g = brdfGeometry(normal, lightDir, viewDir, spAlpha);

  float f = brdfFresnel(halfDir, viewDir, spF0);

  vec3 diffuse  = color / M_PI;
  vec3 specular = vec3((d * g) / (4.0 * nDotL * nDotV));
  return mix(diffuse, specular, f);
}

#endif