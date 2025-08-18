#ifndef LIGHTING_BRDF_GLSL_INCLUDED
#define LIGHTING_BRDF_GLSL_INCLUDED
#include "/lib/math/misc.glsl"

// D, F functions sourced from here: https://learnopengl.com/PBR/Theory
// G function from the PBR book:
// https://pbr-book.org/4ed/Reflection_Models/Roughness_Using_Microfacet_Theory#eq:microfacet-masking-shadowing-ross

// GGX distribution function
float brdfDistribution(float nDotH, float spAlpha) {
  float alpha2 = pow2(spAlpha);
  float nDotH2 = pow2(nDotH);

  float dotTerm = fma(nDotH2, alpha2, -nDotH2) + 1.0;
  float denom   = M_PI * pow2(dotTerm);

  return alpha2 / denom;
}

// GGX-Schlick geometry function
float brdfGeometry(float nDotL, float nDotV, float spAlpha) {
  float k = pow2(spAlpha + 1.0) * 0.125;

  float numerL = nDotL;
  float denomL = fma(nDotL, -k, nDotL) + k;

  float numerV = nDotV;
  float denomV = fma(nDotV, -k, nDotV) + k;

  return (numerL * numerV) / (denomL * denomV);
}

// Schlick's approximation (scalar F0)
float brdfFresnel(float vDotH, float spF0) {
  float rhsTerm  = 1.0 - vDotH;
  float rhsTerm2 = pow2(rhsTerm);
  float rhsTerm5 = rhsTerm2 * rhsTerm2 * rhsTerm;

  return spF0 + (1.0 - spF0) * rhsTerm5;
}

// Schlick's approximation (coloured F0)
vec3 brdfFresnelMetal(float vDotH, vec3 color) {
  float rhsTerm  = 1.0 - vDotH;
  float rhsTerm2 = pow2(rhsTerm);
  float rhsTerm5 = rhsTerm2 * rhsTerm2 * rhsTerm;

  return color + (1.0 - color) * rhsTerm5;
}

// Cook-Torrance BRDF for opaque surfaces. Note that this already includes
// the N dot L term, so this should not be multiplied in after.
vec3 brdfOpaque(
  vec3 normal, vec3 lightDir, vec3 viewDir, vec3 color, float spAlpha,
  float spF0) {
  const float metalThresh = 229.5 / 255.0;
  const float minNDotV    = 0.001;

  vec3 halfDir = normalize(lightDir + viewDir);

  float nDotL = clampDot(normal, lightDir);
  float nDotV = clampDot(normal, viewDir);
  float nDotH = clampDot(normal, halfDir);
  float vDotH = clampDot(viewDir, halfDir);

  float d = brdfDistribution(nDotH, spAlpha);
  float g = brdfGeometry(nDotL, nDotV, spAlpha);

  if (spF0 > metalThresh) {
    // metals do not have diffuse reflection.
    // only compute specular.
    vec3 f = brdfFresnelMetal(vDotH, color);
    return (d * g * f) / max(4.0 * nDotV, minNDotV);
  }
  else {
    // Assume all refracted light is eventually diffusely reflected or absorbed.
    float f       = brdfFresnel(vDotH, spF0);
    vec3 diffuse  = color * nDotL / M_PI;
    vec3 specular = vec3((d * g) / max(4.0 * nDotV, minNDotV));
    return mix(diffuse, specular, f);
  }
}

// Cook-Torrance BRDF for translucent surfaces. Note that this already includes
// the N dot L term, so this should not be multiplied in after.
// This is *super* rough and definitely not very accurate.
vec4 brdfTranslucent(
  vec3 normal, vec3 lightDir, vec3 viewDir, vec4 color, float spAlpha,
  float spF0) {
  const float metalThresh = 229.5 / 255.0;
  const float minNDotV    = 0.001;

  vec3 halfDir = normalize(lightDir + viewDir);

  float nDotL = clampDot(normal, lightDir);
  float nDotV = clampDot(normal, viewDir);
  float nDotH = clampDot(normal, halfDir);
  float vDotH = clampDot(viewDir, halfDir);

  float d = brdfDistribution(nDotH, spAlpha);
  float g = brdfGeometry(nDotL, nDotV, spAlpha);

  float f       = brdfFresnel(vDotH, spF0);
  vec4 diffuse  = vec4(color.rgb * nDotL / M_PI, color.a);
  vec4 specular = vec4(vec3((d * g) / max(4.0 * nDotV, minNDotV)), 1.0);
  return mix(diffuse, specular, f);
}


#endif