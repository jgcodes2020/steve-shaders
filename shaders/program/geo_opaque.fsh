#version 460 compatibility

#include "/lib/common.glsl"
#include "/lib/pack.glsl"

uniform sampler2D gtexture;

in VertexData {
  vec4 color;
  vec2 uvTex;
  vec2 light;
  vec3 normal;
} v;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec2 normal;
layout(location = 2) out uvec2 lightInfo;

void main() {
  color = texture(gtexture, v.uvTex) * v.color;
  if (color.a < alphaTestRef)
    discard;
  
  normal = packNormal(v.normal);
  
  lightInfo = packLightInfo(LightInfo(
    v.light,
    GEO_TYPE_WORLD
  ));
}