#ifndef LIGHTING_MODEL_GLSL_INCLUDED
#define LIGHTING_MODEL_GLSL_INCLUDED

#include "/lib/lighting/brdf.glsl"
#include "/lib/math/misc.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/pack.glsl"

vec3 lt_pbrLighting(vec3 color, FragInfo i, vec3 viewDir, vec3 ambientLight, vec3 skyLight) {
  float spAlpha = pow2(1.0 - i.spSmoothness);
  float spF0 = i.spF0;

  vec3 result = vec3(0.0);

  vec3 sunDir = mat3(gbufferModelViewInverse) * (shadowLightPosition * 0.01);

  // Reflectance due to sunlight. 
  // Since incoming distribution of sunlight can be modelled as a Dirac delta 
  // function, we simply evaluate the term at the desired reflectance.
  {
    float nDotL = dot(sunDir, i.normal);
    vec3 radiance = skyLight;
    vec3 reflectance = brdf(i.normal, sunDir, viewDir, color, spAlpha, spF0);
    result += reflectance * radiance * nDotL;
  }

  // ambient light. 
  result += color * (ambientLight * i.ao);

  return result;
}

#endif