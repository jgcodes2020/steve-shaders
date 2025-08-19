#ifndef LIGHTING_BRDF_GLSL_INCLUDED
#define LIGHTING_BRDF_GLSL_INCLUDED
#include "/lib/math/misc.glsl"

// D, F functions sourced from here: https://learnopengl.com/PBR/Theory
// G function from the PBR book:
// https://pbr-book.org/4ed/Reflection_Models/Roughness_Using_Microfacet_Theory#eq:microfacet-masking-shadowing-ross

const float brdfMetalThresh = 229.5 / 255.0;
  const float brdfMinNDotV    = 0.001;

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

// GGX-Schlick geometry function (IBL constant)
float brdfGeometryIBL(float nDotL, float nDotV, float spAlpha) {
  float k = pow2(spAlpha) * 0.5;

  float numerL = nDotL;
  float denomL = fma(nDotL, -k, nDotL) + k;

  float numerV = nDotV;
  float denomV = fma(nDotV, -k, nDotV) + k;

  return (numerL * numerV) / (denomL * denomV);
}

// Schlick's approximation (scalar F0)
float brdfFresnel(float vDotH, float spF0) {
  return spF0 + (1.0 - spF0) * pow5(1.0 - vDotH);
}

// Schlick's approximation (coloured F0)
vec3 brdfFresnelMetal(float vDotH, vec3 color) {
  return color + (1.0 - color) * pow5(1.0 - vDotH);
}

// Cook-Torrance BRDF for opaque surfaces. Note that this already includes
// the N dot L term, so this should not be multiplied in after.
vec3 brdfOpaque(
  vec3 normal, vec3 lightDir, vec3 viewDir, vec3 color, float spAlpha,
  float spF0) {

  vec3 halfDir = normalize(lightDir + viewDir);

  float nDotL = clampDot(normal, lightDir);
  float nDotV = clampDot(normal, viewDir);
  float nDotH = clampDot(normal, halfDir);
  float vDotH = clampDot(viewDir, halfDir);

  float d = brdfDistribution(nDotH, spAlpha);
  float g = brdfGeometry(nDotL, nDotV, spAlpha);

  if (spF0 > brdfMetalThresh) {
    // metals do not have diffuse reflection.
    // only compute specular.
    vec3 f = brdfFresnelMetal(vDotH, color);
    return (d * g * f) / max(4.0 * nDotV, brdfMinNDotV);
  }
  else {
    // Assume all refracted light is eventually diffusely reflected or absorbed.
    float f       = brdfFresnel(vDotH, spF0);
    vec3 diffuse  = color * nDotL / M_PI;
    vec3 specular = vec3((d * g) / max(4.0 * nDotV, brdfMinNDotV));
    return mix(diffuse, specular, f);
  }
}

// Cook-Torrance BRDF for translucent surfaces. Note that this already includes
// the N dot L term, so this should not be multiplied in after.
// This is *super* rough and definitely not very accurate.
vec4 brdfTranslucent(
  vec3 normal, vec3 lightDir, vec3 viewDir, vec4 color, float spAlpha,
  float spF0) {

  vec3 halfDir = normalize(lightDir + viewDir);

  float nDotL = clampDot(normal, lightDir);
  float nDotV = clampDot(normal, viewDir);
  float nDotH = clampDot(normal, halfDir);
  float vDotH = clampDot(viewDir, halfDir);

  float d = brdfDistribution(nDotH, spAlpha);
  float g = brdfGeometry(nDotL, nDotV, spAlpha);

  // Specular highlights only happen when we're within the normal hemisphere.
  // The diffuse term already accounts for the lack of lighting.
  float f = (nDotV > 0.0) ? brdfFresnel(vDotH, spF0) : 0.0;

  vec4 diffuse  = vec4(color.rgb * nDotL / M_PI, color.a);
  vec4 specular = vec4((d * g) / max(4.0 * nDotV, brdfMinNDotV));

  return mix(diffuse, specular, f);
}

#ifndef LOOKUP_COMPUTE_SHADER

// Schlick's approximation with roughness correction (scalar F0)
float brdfFresnelAmbient(float nDotV, float spAlpha, float spF0) {
  return spF0 + (max(1.0 - spAlpha, spF0) - spF0) * pow5(1.0 - nDotV);
}

// Schlick's approximation with roughness correction (coloured F0)
vec3 brdfFresnelMetalAmbient(float nDotV, vec3 color, float spAlpha) {
  return color + (max(vec3(1.0 - spAlpha), color) - color) * pow5(1.0 - nDotV);
}

// Total Reflectance Function for ambient light. This depends on the
// lookup table computed in /program/lut_brdf.csh
vec3 trfAmbient(
  vec3 normal, vec3 viewDir, vec3 color, float spAlpha, float spF0) {
  float nDotV = clampDot(normal, viewDir);
  vec2 brdfLut = texture(tex_brdfLut, vec2(nDotV, spAlpha)).rg;

  if (spF0 > brdfMetalThresh) {
    vec3 f = brdfFresnelMetalAmbient(nDotV, color, spAlpha);
    return f * brdfLut.x + brdfLut.y;
  }
  else {
    float f = brdfFresnelAmbient(nDotV, spAlpha, spF0);
    vec3 diffuse = color;
    vec3 specular = vec3(f * brdfLut.x + brdfLut.y);
    return mix(diffuse, specular, f);
  }
}

#endif

#endif