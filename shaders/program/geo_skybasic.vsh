#version 460 compatibility

#include "/lib/common.glsl"

out VertexData {
  vec4 color;
}
v;


void main() {
  gl_Position = ftransform();
  v.color = gl_Color;
}