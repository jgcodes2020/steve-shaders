#version 460 compatibility

#include "/lib/common.glsl"

out VertexData {
  vec4 color;

#ifdef UV_TEX
  vec2 uvTex;
#endif
}
v;


void main() {
  gl_Position = ftransform();

  v.color = gl_Color;

#ifdef UV_TEX
  v.uvTex = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
#endif
}