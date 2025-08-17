#ifndef LIGHTING_BRDF_GLSL_INCLUDED
#define LIGHTING_BRDF_GLSL_INCLUDED
#include "/lib/math/misc.glsl"

// D, F and G functions sourced from here: https://learnopengl.com/PBR/Theory

// GGX distribution function
float brdfDistribution(float nDotH, float spAlpha) {
  float alpha2 = pow2(spAlpha);
  float nDotH2 = pow2(nDotH);

  float dotTerm = fma(nDotH2, alpha2, -nDotH2) + 1.0;
  float denom = M_PI * pow2(dotTerm);

  return alpha2 / denom;
}

// float brdfDistribution(float nDotH, float spAlpha) {
//   float alpha2 = pow2(spAlpha);

//   float power = 2.0 / alpha2 - 2.0;
//   float coeff = 1.0 / (M_PI * alpha2);

//   return coeff * pow(nDotH, power);
// }

// Schlick-GGX geometry function with Smith's method
float brdfGeometry(float nDotL, float nDotV, float spAlpha) {
  float k = pow2(spAlpha + 1.0) * 0.125;

  float numerL = nDotL;
  float denomL = nDotL * (1.0 - k) + k;

  float numerV = nDotV;
  float denomV = nDotV * (1.0 - k) + k;

  return (numerL * numerV) / (denomL * denomV);
}

float brdfFresnel(float vDotH, float spF0) {
  float rhsTerm  = 1.0 - vDotH;
  float rhsTerm2 = pow2(rhsTerm);
  float rhsTerm5 = rhsTerm2 * rhsTerm2 * rhsTerm;

  return spF0 + (1.0 - spF0) * rhsTerm5;
}

vec3 brdfFresnelMetal(float vDotH, vec3 color) {
  float rhsTerm  = 1.0 - vDotH;
  float rhsTerm2 = pow2(rhsTerm);
  float rhsTerm5 = rhsTerm2 * rhsTerm2 * rhsTerm;

  return color + (1.0 - color) * rhsTerm5;
}

// final Cook-Torrance BRDF. Note that this already includes
// the N dot L term, so this should not be multiplied in after.
vec3 brdf(
  vec3 normal, vec3 lightDir, vec3 viewDir, vec3 color, float spAlpha,
  float spF0) {
  const float metalThresh = 229.5 / 255.0;
  const float normCap     = 0.001;

  vec3 halfDir = normalize(lightDir + viewDir);

  float nDotL = clampDot(normal, lightDir);
  float nDotV = clampDot(normal, viewDir);
  float nDotH = clampDot(normal, halfDir);
  float vDotH = clampDot(viewDir, halfDir);

  float d = brdfDistribution(nDotH, spAlpha);
  float g = brdfGeometry(nDotL, nDotV, spAlpha);

  if (spF0 > metalThresh) {
    // metals do not have diffuse reflection
    vec3 f = brdfFresnelMetal(vDotH, color);
    return (d * g * f) / max(4.0 * nDotV, normCap);
  }
  else {
    float f       = brdfFresnel(vDotH, spF0);
    vec3 diffuse  = color * nDotL / M_PI;
    vec3 specular = vec3((d * g * f) / max(4.0 * nDotV, normCap));
    return diffuse * (1.0 - f) + specular;
  }
}

vec3 diffuse(
  vec3 normal, vec3 lightDir, vec3 viewDir, vec3 color, float spAlpha,
  float spF0) {
  float nDotL = clampDot(normal, lightDir);
  return color * nDotL / M_PI;
}

#endif