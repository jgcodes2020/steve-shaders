#version 460 compatibility

#include "/lib/buffers.glsl"
#include "/lib/common.glsl"

uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;

in VertexData {
  vec4 color;
  vec2 uvTex;
}
v;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 bColor;

void main() {
  bColor = texture(gtexture, v.uvTex) * v.color;
  if (bColor.a < alphaTestRef) {
    discard;
  }

  #ifdef TRANSLUCENT
  // correct to linear premultiplied color
  bColor.rgb *= bColor.a;
  bColor.rgb = pow(bColor.rgb, vec3(SRGB_GAMMA));
  #endif

  // brighten the colour to compensate for tonemapping
  bColor.rgb *= 2.0;
}