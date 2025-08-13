#version 460 compatibility

#include "/lib/common.glsl"
#include "/lib/pack.glsl"

uniform sampler2D gtexture;

in VertexData {
  vec4 color;
  vec2 uvTex;
  vec2 light;

  #ifndef NO_NORMAL
  vec3 normal;
  #endif

  #ifdef TERRAIN_OPAQUE
  float ao;
  #endif
}
v;

// naming scheme: bThing = buffer for thing
/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 bColor;
layout(location = 1) out vec3 bNormal;
layout(location = 2) out uvec2 bLight;

void main() {
  bColor = texture(gtexture, v.uvTex) * v.color;
  #ifdef ALPHA_TEST
  if (bColor.a < alphaTestRef)
    discard;
  #endif

  #ifdef NO_NORMAL
  // view-space z-direction in model space
  bNormal = gbufferModelViewInverse[2].xyz;
  #else
  bNormal = v.normal;
  #endif

  #ifdef HAND
  const uint geoType = GEO_TYPE_HAND;
  #else
  const uint geoType = GEO_TYPE_WORLD;
  #endif

  #ifdef TERRAIN_OPAQUE
  float ao = v.ao;
  #else
  const float ao = 1.0;
  #endif

  bLight = packFragInfo(FragInfo(v.light, geoType, ao));
}