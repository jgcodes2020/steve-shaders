in vec2 mc_midTexCoord;
in vec2 mc_Entity;

out vec2 texcoord;
out vec4 glcolor;

#include "/lib/common.glsl"
#include "/lib/lighting/shadow.glsl"
#include "/lib/props/block.glsl"

void main() {
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  glcolor  = gl_Color;

  // if this is one of those debug lines you can
  // just yeet that out the window
  if (mc_midTexCoord == vec2(0.0)) {
    gl_Position = vec4(-1.0);
    return;
  }

  vec3 vertex = gl_Vertex.xyz;
  vec3 normal = txLinear(gbufferModelViewInverse, gl_NormalMatrix * gl_Normal);

  // vertex shifting so that shadows appears at noon
  if (IsPlant(int(mc_Entity.x))) {
      const float PUSH_FACTOR = 0.3;
      vec2 midCoord = (gl_TextureMatrix[0] * vec4(mc_midTexCoord, 0.0, 1.0)).st;
      vertex += normal * PUSH_FACTOR * sign(texcoord.y - midCoord.y);
  }

  // Position
  gl_Position     = gl_ModelViewProjectionMatrix * vec4(vertex, gl_Vertex.w);
  gl_Position.xyz = shadowDistort(gl_Position.xyz);
}