#version 460 compatibility

#include "/lib/common.glsl"
#include "/lib/lighting/pack.glsl"

uniform sampler2D gtexture;

in VertexData {
  vec4 color;
  vec2 uvTex;
  vec2 light;
  vec3 normal;
} v;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;
// layout(location = 1) out vec3 normal;
// layout(location = 2) out uvec2 lightInfo;

void main() {
  color = texture(gtexture, v.uvTex) * v.color;
  if (color.a < alphaTestRef)
    discard;
}