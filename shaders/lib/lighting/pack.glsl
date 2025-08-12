#ifndef LIGHTING_PACK_GLSL_INCLUDED
#define LIGHTING_PACK_GLSL_INCLUDED

// packing/unpacking data for colortex2.

struct LightInfo {
  // vanilla light values (r: block, g: sky)
  vec2 vanilla;
  // stores geometry type. See GEO_TYPE_* constants.
  uint geoType;
};

const uint GEO_TYPE_WORLD = 0u;
const uint GEO_TYPE_SKY = 1u;
const uint GEO_TYPE_HAND = 2u;

uvec2 packLightInfo(LightInfo info) {
  uint rComp = packUnorm4x8(vec4(info.vanilla, 0.0, 0.0)) & 0xFFFFu;
  rComp |= (geoType & 0xFFu) << 16;
  return uvec2(rComp, 0u);
}

LightInfo unpackLightInfo(uvec2 packed) {
  uint vanillaPacked = packed.r & 0xFFFFu;
  uint geoType = (packed.r >> 16) & 0xFFu;

  float vanilla = unpackUnorm(vanillaPacked).rg;
  
  return LightInfo(vanilla, geoType);
}

#endif