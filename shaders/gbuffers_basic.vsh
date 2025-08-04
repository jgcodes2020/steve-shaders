#version 410 compatibility

out vec2 vtlight;
out vec4 glcolor;

void main() {
  gl_Position = ftransform();
  vtlight     = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
  glcolor     = gl_Color;
}