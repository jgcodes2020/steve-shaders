#ifndef LIGHTING_BRDF_GLSL_INCLUDED
#define LIGHTING_BRDF_GLSL_INCLUDED
#include "/lib/math/misc.glsl"

// D, F, and G functions sourced from here: https://learnopengl.com/PBR/Theory

// Trowbridge-Reitz GGX distribution function
float brdfDistribution(float nDotH, float spAlpha) {
  float alpha2 = pow2(spAlpha);

  float numer = alpha2;
  float denom = M_PI * pow2(pow2(nDotH) * (alpha2 - 1.0) + 1.0);

  return numer / denom;
}

// Schlick-GGX geometry function with Smith's method
float brdfGeometry(float nDotL, float nDotV, float spAlpha) {
  float k     = pow2(spAlpha + 1.0) * 0.125;

  float numerL = nDotL;
  float denomL = nDotL * (1.0 - k) + k;

  float numerV = nDotV;
  float denomV = nDotV * (1.0 - k) + k;

  return (numerL * numerV) / (denomL * denomV);
}

float brdfFresnel(float vDotH, float spF0) {
  return spF0 + (1.0 - spF0) * pow(1.0 - vDotH, 5.0);
}

vec3 brdfFresnelMetal(float vDotH, vec3 color) {
  return color + (1.0 - color) * pow(1.0 - vDotH, 5.0);
}

// final Cook-Torrance BRDF. Note that this already includes
// the N dot L term, so this should not be multiplied in after.
vec3 brdf(
  vec3 normal, vec3 lightDir, vec3 viewDir, vec3 color, float spAlpha,
  float spF0) {
  const float metalThresh = 229.5 / 255.0;
  const float normCap = 0.01;

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
    float f = brdfFresnel(vDotH, spF0);
    vec3 diffuse  = color * nDotL / M_PI;
    vec3 specular = vec3((d * g) / max(4.0 * nDotV, normCap));
    return mix(diffuse, specular, f);
  }
}

#endif