#version 460 compatibility

#include "/lib/buffers.glsl"
#include "/lib/common.glsl"

in vec4 at_tangent;

out VertexData {
#ifdef USE_VCOLOR
  vec4 color;
#endif

#ifdef USE_TEXTURE
  vec2 uvTex;
#endif
}
v;

void main() {
  gl_Position = ftransform();

#ifdef USE_VCOLOR
  #ifdef TRANSLUCENT
  v.color = gl_Color;
  #else
  v.color = vec4(gl_Color.rgb, 1.0);
  #endif

  #ifdef ENTITY_COLOR
  v.color.rgb = mix(v.color.rgb, entityColor.rgb, entityColor.a);
  #endif
#endif

#ifdef USE_TEXTURE
  v.uvTex = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
#endif
}