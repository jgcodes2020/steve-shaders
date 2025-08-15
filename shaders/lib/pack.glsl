#ifndef PACK_GLSL_INCLUDED
#define PACK_GLSL_INCLUDED

// OCTAHEDRAL NORMAL PACKING
// ==================================

// https://knarkowicz.wordpress.com/2014/04/16/octahedron-normal-vector-encoding/
vec2 octaPackNormal(vec3 n) {
  n /= dot(abs(n), vec3(1.0));
  n.xy = (n.z >= 0.0) ? n.xy : (1.0 - abs(n.yx)) * sign(n.xy);
  return fma(n.xy, vec2(0.5), vec2(0.5));
}

vec3 octaUnpackNormal(vec2 f) {
  f       = fma(f, vec2(2.0), vec2(-1.0));
  vec3 n  = vec3(f.xy, 1.0 - dot(abs(f), vec2(1.0)));
  float t = clamp(-n.z, 0.0, 1.0);
  n.xy += mix(vec2(t), vec2(-t), greaterThan(n.xy, vec2(0.0)));
  return normalize(n);
}

// COLORTEX1 (LIGHTING INFO)
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

uvec4 packFragInfo(FragInfo i) {
  uint r = packSnorm4x8(vec4(i.normal, 0.0));

  uint g = packUnorm4x8(vec4(i.vnLight, i.ao, 0.0));
  g |= (i.emissive) ? (1u << 30) : 0;
  g |= (i.hand) ? (1u << 31) : 0;

  uint b = packUnorm4x8(vec4(i.spSmoothness, i.spF0, i.emission, 0.0));

  return uvec4(r, g, b, 0u);
}

FragInfo unpackFragInfo(uvec4 v) {
  vec3 normal = unpackSnorm4x8(v.r).xyz;

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