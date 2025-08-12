#version 460 compatibility

#include "/lib/common.glsl"

out VertexData {
  vec4 color;
  vec2 uvTex;
  vec2 light;
  vec3 normal;
} v;

void main() {
  gl_Position = ftransform();
  v.color = gl_Color;
  v.uvTex = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  v.light = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
  v.normal = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal);
}