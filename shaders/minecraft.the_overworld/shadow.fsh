#version 410 compatibility

uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec2 texcoord;
in vec4 glcolor;

layout(location = 0) out vec4 color;

#include "/lib/lighting/shadow.glsl"

void main() {
  color = texture(gtexture, texcoord) * glcolor;
  if (color.a < alphaTestRef) {
    discard;
  }
}