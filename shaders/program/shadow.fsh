#version 460 compatibility

#include "/lib/common.glsl"
#include "/lib/pack.glsl"

uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;

in VertexData {
  vec4 color;
  vec2 uvTex;
}
v;

// naming scheme: bThing = buffer for thing
/* RENDERTARGETS: 0,1 */
layout(location = 0) out vec4 bColor;
layout(location = 1) out uvec4 bFragInfo;

void main() {
  bColor = texture(gtexture, v.uvTex) * v.color;
  if (bColor.a < alphaTestRef)
    discard;
}