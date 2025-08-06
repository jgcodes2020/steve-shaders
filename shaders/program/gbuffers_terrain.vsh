in vec2 mc_Entity;

out vec4 glcolor;
out vec2 texcoord;
out vec2 vtlight;
out vec3 normal;

flat out int blockId;

#include "/lib/common.glsl"

void main() {
  gl_Position = ftransform();
  glcolor     = gl_Color;

  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

  vtlight = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

  normal = gl_NormalMatrix * gl_Normal;
  normal = txLinear(gbufferModelViewInverse, normal);

  blockId = int(mc_Entity.x);
}