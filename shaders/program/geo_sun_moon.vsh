#version 460 compatibility

#include "/lib/buffers.glsl"
#include "/lib/common.glsl"

in vec4 at_tangent;

out VertexData {
  vec4 color;
  vec2 uvTex;
}
v;

void main() {
  gl_Position = ftransform();
  v.color = gl_Color;
  v.uvTex = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}