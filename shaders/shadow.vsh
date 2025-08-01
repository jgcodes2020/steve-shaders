#version 410 compatibility

in vec2 mc_midTexCoord;

out vec2 texcoord;
out vec4 glcolor;

#include "/lib/shadow.glsl"

void main() {
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  glcolor = gl_Color;

  // if this is one of those debug lines you can
  // just yeet that out the window
  if (mc_midTexCoord == vec2(0.0)) {
    gl_Position = vec4(-1.0);
    return;
  }

  // Position
  gl_Position = ftransform();
  gl_Position.xyz = shadowDistort(gl_Position.xyz);
}