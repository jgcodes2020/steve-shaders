#ifndef PIPELINE_CONFIG_GLSL_INCLUDED
#define PIPELINE_CONFIG_GLSL_INCLUDED

// COMPOSITE COLOUR BUFFERS
// ==================================

#ifdef COMPUTE_SHADER
#define DECL_COLORTEX(format, n) layout(format) uniform image2D colorimg##n;
#define DECL_COLORTEX_U(format, n) layout(format) uniform uimage2D colorimg##n;
#else
#define DECL_COLORTEX(format, n) uniform sampler2D colortex##n;
#define DECL_COLORTEX_U(format, n) uniform usampler2D colortex##n;

#endif

#ifdef SHADOW_COMPUTE_SHADER
#define DECL_SHADOWCOLOR(format, n) layout(format) uniform image2D shadowcolorimg##n;
#else
#define DECL_SHADOWCOLOR(format, n) uniform sampler2D shadowcolor##n;
#endif

#ifdef LOOKUP_COMPUTE_SHADER
#define DECL_LOOKUPTEX(format, name) layout(format) uniform image2D img_##name;
#else
#define DECL_LOOKUPTEX(format, name) uniform sampler2D tex_##name;
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
const bool colortex0Clear = false;
*/
DECL_COLORTEX(rgba16f, 0)


// Fragment information buffer.
// R
// 31:16 | u8x2 octa_face_normal; // the normal (without normal mapping).
// 15:0  | u8x2 octa_normal;      // the normal (with normal mapping applied).
// G
//    31 | bool hand;     // first-person hand, requires shadow adjustment.
//    30 | bool emissive; // purely emissive, no lighting required.
// 24:16 | u8 ao;         // ambient occlusion
// 15:0  | u8x2 vn_light; // vanilla block/sky lighting
// B
// 24:16 | u8 emission; // light sources, etc.
// 15:8  | u8 sp_f0;    // fresnel/metal
//  7:0  | u8 sp_alpha; // roughness
// See PACK_PURE_EMISSIVE in buffers.glsl for the clear colour.
/*
const int colortex1Format = RGBA32UI;
const vec4 colortex1ClearColor = vec4(0.0, 1073741824.0, 0.0, 0.0);
*/
DECL_COLORTEX_U(rgba32ui, 1)


// SHADOW COLOUR BUFFERS
// ==================================

/*
const int shadowcolor0Format = RGBA16F;
*/
DECL_SHADOWCOLOR(rgba16f, 0)

// CUSTOM BUFFERS
// ==================================

DECL_LOOKUPTEX(rg16f, brdfLut)


#undef DECL_COLORTEX
#undef DECL_SHADOWCOLOR

// SHADOW DEPTH TEXTURES
// ==================================

const int shadowMapResolution      = 2048;
const float shadowDistance         = 160.0;
const bool shadowHardwareFiltering = true;

uniform sampler2DShadow shadowtex0;  // shadow distance
uniform sampler2DShadow shadowtex1;  // shadow distance (opaque)

// NOISE TEXTURE
// ==================================

const int noiseTextureResolution = 256;

uniform sampler2D noisetex;  // noise

// DEPTH BUFFERS
// ==================================
uniform sampler2D depthtex0;  // depth
uniform sampler2D depthtex1;  // depth (opaque)


#endif