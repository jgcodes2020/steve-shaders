#version 460 compatibility

#include "/lib/common.glsl"
#include "/lib/buffers.glsl"

uniform sampler2D gtexture;

in VertexData {
  vec4 color;
}
v;

// The sky renders first, so the specular buffer is already
// pre-cleared with the emissive flag.
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 bColor;

void main() {
  bColor = v.color;
}