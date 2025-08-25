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

// TRANSLUCENT SHADOW DEPTH BUFFER
// ===============================================
// Since we can't simply disable the depth test, we have to
// emulate our own depth buffer using image atomics.

uint encodeShadowDepth(float x) {
  x = -x * 0.5 + 0.5;
  return uint(x * INT_MAX_F);
}

float decodeShadowDepth(uint u) {
  float x = float(u) / INT_MAX_F;
  return 1.0 - 2.0 * x;
}

// OCTAHEDRAL NORMAL PACKING
// ==================================

vec2 unitVectorToOcta(vec3 n) {
  n /= dot(abs(n), vec3(1.0));
  n.xy = (n.z >= 0.0)? n.xy : (1.0 - abs(n.yx)) * signNonzero(n.xy);
  return n.xy;
}
vec3 octaToUnitVector(vec2 e) {
  vec3 n = vec3(e.xy, 1.0 - dot(abs(e.xy), vec2(1.0)));
  float t = clamp(-n.z, 0.0, 1.0);
  n.xy += mix(vec2(t), vec2(-t), greaterThanEqual(n.xy, vec2(0.0)));
  return normalize(n);
}

// FRAGMENT INFO
// ==================================

struct FragInfo {
  vec3 normal;
  vec3 faceNormal;

  bool emissive;
  bool hand;
  vec2 vnLight;
  float ao;

  float spSmoothness;
  float spF0;
  float emission;
};

const uvec4 PACK_PURE_EMISSIVE = uvec4(0u, 0x40000000u, 0u, 0u);

FragInfo fragInfoFromTextures(vec4 texSpecular, vec4 texNormal, vec2 vnLight, float ao, mat3 tbnMatrix) {
  vec2 tbnNormalXY = fma(texNormal.xy, vec2(2.0), vec2(-1.0));
  vec3 tbnNormal = vec3(tbnNormalXY, sqrt(1.0 - dot(tbnNormalXY, tbnNormalXY)));
  vec3 normal = tbnMatrix * tbnNormal;

  vec3 faceNormal = tbnMatrix[2];

  const bool emissive = false;
#ifdef HAND
  const bool hand = true;
#else
  const bool hand = false;
#endif

  ao = pow(ao, SRGB_GAMMA) * texNormal.b;

  float spSmoothness = texSpecular.r;
  float spF0 = texSpecular.g;
  float emission = texSpecular.a;
  emission = (emission == 1.0)? 0.0 : emission * (255.0 / 254.0);

  return FragInfo(normal, faceNormal, emissive, hand, vnLight, ao, spSmoothness, spF0, emission);
}

// Packs a FragInfo into a uvec4.
uvec4 packFragInfo(FragInfo i) {
  vec2 normalOcta = unitVectorToOcta(i.normal);
  vec2 faceNormalOcta = unitVectorToOcta(i.faceNormal);
  uint r = packSnorm4x8(vec4(normalOcta, faceNormalOcta));

  uint g = packUnorm4x8(vec4(i.vnLight, i.ao, 0.0));
  g |= (i.emissive) ? (1u << 30) : 0;
  g |= (i.hand) ? (1u << 31) : 0;

  uint b = packUnorm4x8(vec4(i.spSmoothness, i.spF0, i.emission, 0.0));

  return uvec4(r, g, b, 0u);
}

// Unpacks a FragInfo from a uvec4.
FragInfo unpackFragInfo(uvec4 v) {
  vec4 unpackR = unpackSnorm4x8(v.r);
  vec3 normal = octaToUnitVector(unpackR.xy);
  vec3 faceNormal = octaToUnitVector(unpackR.zw);

  vec4 unpackG  = unpackUnorm4x8(v.g & 0x00FFFFFFu);
  vec2 vnLight  = unpackG.rg;
  float ao      = unpackG.b;
  bool emissive = (v.g & (1u << 30)) != 0u;
  bool hand     = (v.g & (1u << 31)) != 0u;

  vec4 unpackB       = unpackUnorm4x8(v.b & 0x00FFFFFFu);
  float spSmoothness = unpackB.r;
  float spF0         = unpackB.g;
  float emission     = unpackB.b;

  return FragInfo(normal, faceNormal, emissive, hand, vnLight, ao, spSmoothness, spF0, emission);
}

#endif