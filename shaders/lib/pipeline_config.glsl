#ifndef PIPELINE_CONFIG_GLSL_INCLUDED
#define PIPELINE_CONFIG_GLSL_INCLUDED

#ifdef COMPUTE_SHADER
#define DECL_COLORTEX(format, n) layout(format) uniform image2D colorimg##n;
#define DECL_COLORTEX_U(format, n) layout(format) uniform uimage2D colorimg##n;
#else
#define DECL_COLORTEX(format, n) uniform sampler2D colortex##n;
#define DECL_COLORTEX_U(format, n) uniform usampler2D colortex##n;
#endif

// Composite colour buffer.
/*
const int colortex0Format = RGBA16F;
*/
DECL_COLORTEX(rgba16f, 0)


// Fragment information buffer.
// R
// 31:0  | f16x2 octa_normal; // world-space normal
// G
//    31 | bool hand;     // first-person hand, requires adjustments.
// 24:16 | u8 ao;         // ambient occlusion
// 15:0  | u8x2 vn_light; // vanilla block/sky lighting
// B
// 24:16 | u8 emission; // light sources, etc.
// 15:8  | u8 sp_f0;    // fresnel/metal
//  7:0  | u8 sp_alpha; // roughness
/*
const int colortex1Format = RGBA32UI;
const vec4 colortex1ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
*/
DECL_COLORTEX_U(rgba32ui, 1)

#undef DECL_COLORTEX