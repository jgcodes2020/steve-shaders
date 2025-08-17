#ifndef LIGHTING_MODEL_GLSL_INCLUDED
#define LIGHTING_MODEL_GLSL_INCLUDED

#include "/lib/lighting/brdf.glsl"
#include "/lib/math/misc.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/pack.glsl"

vec3 lt_pbrLighting(vec3 color, FragInfo i, vec3 viewDir, vec3 ambientLight, vec3 skyLight) {
  // This is empirically determined and can be tweaked as needed.
  const float minAlphaValue = 2.0e-2;

  float spAlpha = max(pow2(1.0 - i.spSmoothness), minAlphaValue);
  float spF0 = i.spF0;

  vec3 sunDir = mat3(gbufferModelViewInverse) * (shadowLightPosition * 0.01);

  vec3 reflected = vec3(0.0);

  {
    // sunlight reflection
    reflected += skyLight * brdf(i.normal, sunDir, viewDir, color, spAlpha, spF0);
    // ambient light
    reflected += color * (ambientLight * i.ao * i.vnLight.g);
  }

  vec3 emitted = color;

  return mix(reflected, emitted, i.emission);
}

#endif