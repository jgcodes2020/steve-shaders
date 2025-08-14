#ifndef PACK_GLSL_INCLUDED
#define PACK_GLSL_INCLUDED

// OCTAHEDRAL NORMAL PACKING
// ==================================

// https://knarkowicz.wordpress.com/2014/04/16/octahedron-normal-vector-encoding/
vec2 octaPackNormal(vec3 n) {
  n /= dot(abs(n), vec3(1.0));
  n.xy = (n.z >= 0.0)? n.xy : (1.0 - abs(n.yx)) * sign(n.xy);
  return fma(n.xy, 0.5, 0.5);
}

vec3 octaUnpackNormal(vec2 f) {
  f = fma(f, 2.0, -1.0);
  vec3 n = vec3(f.xy, 1.0 - dot(abs(f), vec2(1.0)));
  float t = clamp(-n.z, 0.0, 1.0);
  n.xy += mix(vec2(t), vec2(-t), greaterThan(n.xy, vec2(0.0)));
  return normalize(n);
}

// COLORTEX2 (LIGHTING INFO)
// ==================================

struct FragInfo {
  vec3 normal;

  vec2 vnLight;
  float ao;
  bool hand;

  float spAlpha;
  float spF0;
  float emission;
};

uvec4 packFragInfo(FragInfo i) {
  vec2 packedNormal = octaPackNormal(i.normal);
  uint r = packHalf2x16(packedNormal);
  
  uint g = packUnorm4x8(vec4(i.vnLight, ao, 0.0));
  g |= (hand)? 0x80000000u : 0;

  uint b = packUnorm4x8(vec4(spAlpha, spF0, emission));

  return uvec4(r, g, b, 0u);
}

FragInfo unpackFragInfo(uvec4 v) {
  vec2 packedNormal = unpackHalf2x16(v.r);
  vec3 normal = octaUnpackNormal(packedNormal);

  vec4 unpackG = unpackUnorm4x8(v.g & 0x00FFFFFFu);
  vec2 vnLight = unpackG.rg;
  float ao = unpackG.b;
  bool hand = (v.g & 0x80000000u) != 0u;

  vec4 unpackB = unpackUnorm4x8(v.b & 0x00FFFFFFu);
  float spAlpha = unpackB.r;
  float spF0 = unpackB.g;
  float emission = unpackB.b;

  return FragInfo(normal, vnLight, hand, ao, spAlpha, spF0, emission);
}

#endif