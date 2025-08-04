#version 410 compatibility

out vec2 vtlight;
out vec2 texcoord;
out vec4 glcolor;

void main() {
  gl_Position = ftransform();
  texcoord    = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  vtlight     = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
  glcolor     = gl_Color;
}