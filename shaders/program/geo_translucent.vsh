#version 460 compatibility

#include "/lib/common.glsl"
#include "/lib/buffers.glsl"

in vec4 at_tangent;

out VertexData {
  vec4 color;
  vec2 uvTex;
  vec2 light;

  flat mat3 tbnMatrix;
}
v;

void main() {
  gl_Position = ftransform();

  v.color = gl_Color;

#ifdef ENTITY_COLOR
  v.color.rgb = mix(v.color.rgb, entityColor.rgb, entityColor.a);
  v.color.a += entityColor.a;
#endif

  v.uvTex = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  v.light = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

  v.tbnMatrix = tbnMatrix(gl_Normal, at_tangent, gl_NormalMatrix, gbufferModelViewInverse);
}