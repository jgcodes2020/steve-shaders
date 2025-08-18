#ifndef BUFFERS_GLSL_INCLUDED
#define BUFFERS_GLSL_INCLUDED

#include "/lib/math/misc.glsl"

// VERTEX SHADERS
// ==================================

// Derives the TBN matrix in a gbuffers-pass vertex shader.
// normalIn: gl_Normal
// tangentIn: at_tangent
// normalMatrix: gl_NormalMatrix
mat3 tbnMatrix(vec3 normalIn, vec4 tangentIn, mat3 normalMatrix, mat4 gbufferModelViewInverse) {
  vec3 normal = normalize(mat3(gbufferModelViewInverse) * normalMatrix * normalIn);
  vec3 tangent = normalize(mat3(gbufferModelViewInverse) * normalMatrix * tangentIn.xyz);
  vec3 bitangent = cross(tangent, normal) * sign(tangentIn.w);

  return mat3(tangent, bitangent, normal);
}

// FRAGMENT INFO
// ==================================

struct FragInfo {
  vec3 normal;
  bool emissive;
  bool hand;

  vec2 vnLight;
  float ao;

  float spSmoothness;
  float spF0;
  float emission;
};

const uvec4 PACK_PURE_EMISSIVE = uvec4(0x40000000u, 0u, 0u, 0u);

FragInfo fragInfoFromTextures(vec4 texSpecular, vec4 texNormal, vec2 vnLight, float ao, mat3 tbnMatrix) {
  vec2 tbnNormalXY = fma(texNormal.xy, vec2(2.0), vec2(-1.0));
  vec3 tbnNormal = vec3(tbnNormalXY, sqrt(1.0 - dot(tbnNormalXY, tbnNormalXY)));
  vec3 normal = tbnMatrix * tbnNormal;

  const bool emissive = false;
#ifdef HAND
  const bool hand = true;
#else
  const bool hand = false;
#endif

  ao = ao * pow(texNormal.b, SRGB_GAMMA_RCP);

  float spSmoothness = texSpecular.r;
  float spF0 = texSpecular.g;
  float emission = texSpecular.a;
  emission = (emission == 1.0)? 0.0 : emission * (255.0 / 254.0);

  return FragInfo(normal, emissive, hand, vnLight, ao, spSmoothness, spF0, emission);
}

// Packs a FragInfo into a uvec4.
uvec4 packFragInfo(FragInfo i) {
  uint r = packSnorm4x8(vec4(i.normal, 0.0));

  uint g = packUnorm4x8(vec4(i.vnLight, i.ao, 0.0));
  g |= (i.emissive) ? (1u << 30) : 0;
  g |= (i.hand) ? (1u << 31) : 0;

  uint b = packUnorm4x8(vec4(i.spSmoothness, i.spF0, i.emission, 0.0));

  return uvec4(r, g, b, 0u);
}

// Unpacks a FragInfo from a uvec4.
FragInfo unpackFragInfo(uvec4 v) {
  vec3 normal = normalize(unpackSnorm4x8(v.r).xyz);

  vec4 unpackG  = unpackUnorm4x8(v.g & 0x00FFFFFFu);
  vec2 vnLight  = unpackG.rg;
  float ao      = unpackG.b;
  bool emissive = (v.r & (1u << 30)) != 0u;
  bool hand     = (v.r & (1u << 31)) != 0u;

  vec4 unpackB       = unpackUnorm4x8(v.b & 0x00FFFFFFu);
  float spSmoothness = unpackB.r;
  float spF0         = unpackB.g;
  float emission     = unpackB.b;

  return FragInfo(normal, emissive, hand, vnLight, ao, spSmoothness, spF0, emission);
}

#endif