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
// R
// 16:0  | f16 color_r;
// G
// 16:0  | f16 color_g;
// B
// 16:0  | f16 color_b;
// A
// 16:0  | unused (f16)
/*
const int colortex0Format = RGBA16F;
*/
DECL_COLORTEX(rgba16f, 0)


// Fragment information buffer.
// R
//    31 | bool hand;     // first-person hand, requires shadow adjustment.
//    30 | bool emissive; // purely emissive, no lighting required.
// 23:0  | i8x3 normal;   // normal vector.
// G
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