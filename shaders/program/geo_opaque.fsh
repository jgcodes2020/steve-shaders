#version 460 compatibility

#include "/lib/common.glsl"
#include "/lib/pack.glsl"

uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;

in VertexData {
  vec4 color;
  vec2 uvTex;
  vec2 light;
  float ao;

  flat mat3 gbufferTangentInverse;
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

  vec2 tbnNormalXY = fma(texNormal.xy, vec2(2.0), vec2(-1.0));
  vec3 tbnNormal = vec3(tbnNormalXY, sqrt(1.0 - dot(tbnNormalXY, tbnNormalXY)));
  vec3 normal = v.gbufferTangentInverse * tbnNormal;

  vec2 vnLight = v.light;
  float ao = v.ao * texNormal.b;
  const bool hand = false;

  float spSmoothness = texSpecular.r;
  float spF0 = texSpecular.g;
  float emission = clamp(texSpecular.b * (255.0 / 254.0), 0.0, 1.0);

  FragInfo i = FragInfo(normal, vnLight, ao, hand, spSmoothness, spF0, emission);
  bFragInfo = packFragInfo(i);
}