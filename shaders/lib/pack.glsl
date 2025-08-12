#ifndef PACK_GLSL_INCLUDED
#define PACK_GLSL_INCLUDED

// COLORTEX1 (NORMALS)
// ==================================

// https://knarkowicz.wordpress.com/2014/04/16/octahedron-normal-vector-encoding/
vec2 packNormal(vec3 n) {
  n /= dot(abs(n), vec3(1.0));
  n.xy = (n.z >= 0.0)? n.xy : (1.0 - abs(n.yx)) * sign(n.xy);
  return n.xy;
}

vec3 unpackNormal(vec2 f) {
  vec3 n = vec3(f.xy, 1.0 - dot(abs(f), vec2(1.0)));
  float t = clamp(-n.z, 0.0, 1.0);
  n.xy += mix(vec2(t), vec2(-t), greaterThan(n.xy, vec2(0.0)));
  return normalize(n);
}

// COLORTEX2 (LIGHTING INFO)
// ==================================

struct LightInfo {
  // vanilla light values (r: block, g: sky)
  vec2 vanilla;
  // Classifies geometry that may need special constraints.
  uint geoType;
};

const uint GEO_TYPE_SKY = 0u;
const uint GEO_TYPE_WORLD = 1u;
const uint GEO_TYPE_HAND = 2u;

uvec2 packLightInfo(LightInfo info) {
  uint rComp = packUnorm4x8(vec4(info.vanilla, 0.0, 0.0)) & 0xFFFFu;
  rComp = bitfieldInsert(rComp, info.geoType, 16, 8);
  return uvec2(rComp, 0u);
}

LightInfo unpackLightInfo(uvec2 data) {
  uint vanillaPacked = data.r & 0xFFFFu;
  uint geoType = bitfieldExtract(data.r, 16, 8);

  vec2 vanilla = unpackUnorm4x8(vanillaPacked).rg;
  
  return LightInfo(vanilla, geoType);
}

#endif