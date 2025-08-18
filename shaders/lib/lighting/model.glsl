#ifndef LIGHTING_MODEL_GLSL_INCLUDED
#define LIGHTING_MODEL_GLSL_INCLUDED

#include "/lib/lighting/brdf.glsl"
#include "/lib/math/misc.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/buffers.glsl"

vec3 pbrLightingOpaque(vec3 color, FragInfo i, vec3 viewDir, vec3 ambientLight, vec3 skyLight, vec3 blockLight) {
  // This is empirically determined and can be tweaked as needed.
  const float minAlphaValue = 2.0e-2;

  float spAlpha = max(pow2(1.0 - i.spSmoothness), minAlphaValue);
  float spF0 = i.spF0;

  vec3 sunDir = mat3(gbufferModelViewInverse) * (shadowLightPosition * 0.01);
  vec2 vnLight = pow(i.vnLight, vec2(SRGB_GAMMA));

  vec3 reflected = vec3(0.0);
  {
    // sunlight reflection
    reflected += skyLight * brdfOpaque(i.normal, sunDir, viewDir, color, spAlpha, spF0);
    // ambient light
    reflected += color * (ambientLight * i.ao * vnLight.g);
    // block light
    reflected += color * (blockLight * vnLight.r);
  }

  vec3 emitted = color;

  return mix(reflected, emitted, i.emission);
}

vec4 pbrLightingTranslucent(vec4 color, FragInfo i, vec3 viewDir, vec3 ambientLight, vec3 skyLight, vec3 blockLight) {
  // This is empirically determined and can be tweaked as needed.
  const float minAlphaValue = 2.0e-2;

  float spAlpha = max(pow2(1.0 - i.spSmoothness), minAlphaValue);
  float spF0 = i.spF0;

  vec3 sunDir = mat3(gbufferModelViewInverse) * (shadowLightPosition * 0.01);
  vec2 vnLight = pow(i.vnLight, vec2(SRGB_GAMMA));

  vec4 reflected = vec4(0.0);
  {
    // sunlight reflection
    vec4 skyReflectance = brdfTranslucent(i.normal, sunDir, viewDir, color, spAlpha, spF0);
    reflected += vec4(skyReflectance.rgb * skyLight, skyReflectance.a);
    // ambient light
    reflected.rgb += color.rgb * (ambientLight * i.ao * vnLight.g);
    // block light
    reflected.rgb += color.rgb * (blockLight * vnLight.r);
  }

  vec4 emitted = vec4(color.rgb, 1.0);

  return mix(reflected, emitted, i.emission);
}
#endif