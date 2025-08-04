out vec4 glcolor;
#ifdef GBUFFERS_USE_TEXTURE
out vec2 texcoord;
#endif

#ifdef GBUFFERS_PASS_LIGHT
out vec2 vtlight;
#endif

#ifdef GBUFFERS_PASS_NORMAL
out vec3 normal;
#endif

#include "/lib/util.glsl"

void main() {
  gl_Position = ftransform();
  glcolor     = gl_Color;

#ifdef GBUFFERS_USE_TEXTURE
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
#endif

#ifdef GBUFFERS_PASS_LIGHT
  vtlight = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
#endif

#ifdef GBUFFERS_PASS_NORMAL
  normal = gl_NormalMatrix * gl_Normal;
  normal = txLinear(gbufferModelViewInverse, normal);
#endif
}