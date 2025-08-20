#version 460 compatibility

#include "/lib/common.glsl"
#include "/lib/buffers.glsl"

in vec4 at_tangent;

out VertexData {
  vec4 color;
  vec2 uvTex;
  vec2 light;
  float ao;

  flat mat3 tbnMatrix;
}
v;

void main() {
  gl_Position = ftransform();

#ifdef TERRAIN_OPAQUE
  v.ao    = pow(gl_Color.a, SRGB_GAMMA);
  v.color = vec4(gl_Color.rgb, 1.0);
#else
  v.ao = 1.0;
  v.color = gl_Color;
#endif

#ifdef ENTITY_COLOR
  v.color.rgb = mix(v.color.rgb, entityColor.rgb, entityColor.a);
#endif

  v.uvTex = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  v.light = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

  // v.tbnMatrix = mat3(tangent, bitangent, normal);
  v.tbnMatrix = tbnMatrix(gl_Normal, at_tangent, gl_NormalMatrix, gbufferModelViewInverse);
}