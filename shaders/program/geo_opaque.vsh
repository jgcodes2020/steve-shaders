#version 460 compatibility

#include "/lib/common.glsl"

out VertexData {
  vec4 color;
  vec2 uvTex;
  vec2 light;
  
  #ifndef NO_NORMAL
  vec3 normal;
  #endif

  #ifdef TERRAIN_OPAQUE
  float ao;
  #endif
} v;

void main() {
  gl_Position = ftransform();

  #ifdef TERRAIN_OPAQUE
  v.ao = gl_Color.a;
  v.color = vec4(gl_Color.rgb, 1.0);
  #else
  v.color = gl_Color;
  #endif
  
  #ifdef ENTITY_COLOR
  v.color.rgb = mix(v.color.rgb, entityColor.rgb, entityColor.a);
  #endif

  v.uvTex = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  v.light = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
  
  #ifndef NO_NORMAL
  v.normal = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal);
  #endif
}