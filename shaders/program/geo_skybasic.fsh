#version 460 compatibility

#include "/lib/common.glsl"
#include "/lib/pack.glsl"

uniform sampler2D gtexture;

in VertexData {
  vec4 color;
}
v;

// naming scheme: bThing = buffer for thing
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 bColor;

const vec4[6] lut = vec4[](
  vec4(1.0, 0.0, 0.0, 1.0),
  vec4(1.0, 0.5, 0.0, 1.0),
  vec4(1.0, 1.0, 0.0, 1.0),
  vec4(0.0, 0.7, 0.0, 1.0),
  vec4(0.0, 0.0, 1.0, 1.0),
  vec4(0.5, 0.0, 1.0, 1.0)
);

void main() {
  bColor = v.color;
}