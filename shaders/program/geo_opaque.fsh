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
/* RENDERTARGETS: 0,1 */
layout(location = 0) out vec4 bColor;
layout(location = 1) out uvec4 bFragInfo;

void main() {
  bColor = texture(gtexture, v.uvTex) * v.color;
  #ifdef ALPHA_TEST
  if (bColor.a < alphaTestRef)
    discard;
  #endif
}