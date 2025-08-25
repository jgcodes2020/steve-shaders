#ifndef LIGHTING_MODEL_GLSL_INCLUDED
#define LIGHTING_MODEL_GLSL_INCLUDED

#include "/lib/buffers.glsl"
#include "/lib/lighting/brdf.glsl"
#include "/lib/math/misc.glsl"
#include "/lib/uniforms.glsl"

// Linear roughness (alpha) cannot be too small or it'll screw up the
// distribution function. This minimum value is empirically determined to not
// cause issues.
const float pbrMinAlphaValue = 0.02;

vec3 pbrLightingOpaque(
  vec3 color, FragInfo i, vec3 viewDir, vec3 shadow, vec3 ambientLight,
  vec3 skyLight, vec3 blockLight) {
  float spAlpha = max(pow2(1.0 - i.spSmoothness), pbrMinAlphaValue);
  float spF0    = i.spF0;

  vec3 sunDir  = mat3(gbufferModelViewInverse) * (shadowLightPosition * 0.01);
  vec2 vnLight = pow(i.vnLight, vec2(SRGB_GAMMA));

  // account for skylight being blocked
  skyLight *= shadow;
  ambientLight *= i.ao * vnLight.g;
  blockLight *= vnLight.r;

  vec3 reflected = vec3(0.0);
  {
    // sunlight reflection
    reflected =
      skyLight * brdfOpaque(i.normal, sunDir, viewDir, color, spAlpha, spF0);

    vec3 ambientReflectance = trfAmbient(i.normal, viewDir, color, spAlpha, spF0);
    // ambient light
    reflected += ambientLight * ambientReflectance;
    // block light
    reflected += blockLight * ambientReflectance;
  }

  vec3 emitted = color;

  return mix(reflected, emitted, i.emission);
}

vec4 pbrLightingTranslucent(
  vec4 color, FragInfo i, vec3 viewDir, vec3 shadow, vec3 ambientLight, vec3 skyLight,
  vec3 blockLight) {
  float spAlpha = max(pow2(1.0 - i.spSmoothness), pbrMinAlphaValue);
  float spF0    = i.spF0;

  vec3 sunDir  = mat3(gbufferModelViewInverse) * (shadowLightPosition * 0.01);
  vec2 vnLight = pow(i.vnLight, vec2(SRGB_GAMMA));

  // account for skylight being blocked
  skyLight *= shadow;
  ambientLight *= i.ao * vnLight.g;
  blockLight *= vnLight.r;

  vec4 reflected = vec4(0.0);
  {
    // sunlight reflection
    vec4 skyReflectance =
      brdfTranslucent(i.normal, sunDir, viewDir, color, spAlpha, spF0);
    reflected = vec4(skyReflectance.rgb * skyLight, skyReflectance.a);

    vec3 ambientReflectance = trfAmbient(i.normal, viewDir, color.rgb, spAlpha, spF0);
    // ambient light
    reflected.rgb += ambientLight * ambientReflectance;
    // block light
    reflected.rgb += blockLight * ambientReflectance;
  }

  vec4 emitted = vec4(color.rgb, 1.0);

  return mix(reflected, emitted, i.emission);
}
#endif