#version 460 compatibility

#include "/lib/common.glsl"
#include "/lib/pack.glsl"

uniform sampler2D gtexture;

in VertexData {
  vec4 color;

#ifdef UV_TEX
  vec2 uvTex;
#endif
}
v;

// naming scheme: bThing = buffer for thing
/* RENDERTARGETS: 0,1 */
layout(location = 0) out vec4 bColor;
layout(location = 1) out uvec4 bFragInfo;

void main() {
  bColor = v.color;
  bFragInfo = PACK_PURE_EMISSIVE;
}