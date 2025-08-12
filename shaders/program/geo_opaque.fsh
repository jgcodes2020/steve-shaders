#version 460 compatibility

#include "/lib/common.glsl"
#include "/lib/pack.glsl"

uniform sampler2D gtexture;

in VertexData {
  vec4 color;
  vec2 uvTex;
  vec2 light;
  vec3 normal;
}
v;

// naming scheme: bThing = buffer for thing
/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 bColor;
layout(location = 1) out vec2 bNormal;
layout(location = 2) out uvec2 bLight;

void main() {
  bColor = texture(gtexture, v.uvTex) * v.color;
  #ifdef ALPHA_TEST
  if (bColor.a < alphaTestRef)
    discard;
  #endif

  #ifdef NO_NORMAL
  // z-direction in view space
  bNormal = packNormal(gbufferModelViewInverse[2].xyz);
  #else
  bNormal = packNormal(v.normal);
  #endif

  #ifdef HAND
  bLight = packLightInfo(LightInfo(v.light, GEO_TYPE_HAND));
  #else
  bLight = packLightInfo(LightInfo(v.light, GEO_TYPE_WORLD));
  #endif
}