#ifndef LIGHTING_MODEL_GLSL_INCLUDED
#define LIGHTING_MODEL_GLSL_INCLUDED

struct LightPixelInfo {
  vec3 color;
  vec3 normal;
  vec2 vtLight;
  float ao;
};

// basic diffuse lighting model.
vec3 lt_diffuseLighting(LightPixelInfo p, vec3 ambientLight, vec3 skyLight, vec3 blockLight) {
  vec3 sunL = mat3(gbufferModelViewInverse) * 0.01 * sunPosition;

  float sunNDotL = max(dot(p.normal, sunL), 0.0);

  vec3 skyAmbient = ambientLight * p.vtLight.g;
  vec3 skyDiffuse = skyLight * sunNDotL;

  vec3 skyTotal = skyAmbient + skyDiffuse;
  vec3 blockTotal = blockLight * p.vtLight.r;

  return p.color * (skyTotal + blockTotal);
}

#endif