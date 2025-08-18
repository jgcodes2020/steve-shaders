#version 460 compatibility

#include "/lib/common.glsl"
#include "/lib/buffers.glsl"

uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;

in VertexData {
  vec4 color;
  vec2 uvTex;
  vec2 light;
  float ao;

  flat mat3 tbnMatrix;
}
v;

// naming scheme: bThing = buffer for thing
/* RENDERTARGETS: 0,1 */
layout(location = 0) out vec4 bColor;
layout(location = 1) out uvec4 bFragInfo;

void main() {
  bColor = texture(gtexture, v.uvTex) * v.color;
#ifdef ALPHA_TEST
  if (bColor.a < alphaTestRef)
    discard;
#endif

  vec4 texSpecular = texture(specular, v.uvTex);
  vec4 texNormal = texture(normals, v.uvTex);
  
  FragInfo i = fragInfoFromTextures(texSpecular, texNormal, v.light, v.ao, v.tbnMatrix);
  bFragInfo = packFragInfo(i);
}