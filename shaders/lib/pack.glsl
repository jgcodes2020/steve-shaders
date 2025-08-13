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

struct FragInfo {
  // vanilla light values (r: block, g: sky)
  vec2 vtLight;
  // Classifies geometry that may need special constraints.
  uint geoType;
  // vanilla ambient occlusion on blocks.
  float ao;
};

const uint GEO_TYPE_SKY = 0u;
const uint GEO_TYPE_WORLD = 1u;
const uint GEO_TYPE_HAND = 2u;

uvec2 packFragInfo(FragInfo info) {
  uint rComp = packUnorm4x8(vec4(info.vtLight, info.ao, 0.0));
  uint gComp = info.geoType;
  return uvec2(rComp, gComp);
}

FragInfo unpackFragInfo(uvec2 data) {
  vec4 rCompU = unpackUnorm4x8(data.r);

  vec2 vtLight = rCompU.rg;
  uint geoType = data.g;
  float ao = rCompU.b;
  
  return FragInfo(vtLight, geoType, ao);
}

#endif