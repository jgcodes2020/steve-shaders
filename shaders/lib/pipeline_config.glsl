#ifndef PIPELINE_CONFIG_GLSL_INCLUDED
#define PIPELINE_CONFIG_GLSL_INCLUDED

#ifdef COMPUTE_SHADER
#define DECL_COLORTEX(format, n) layout(format) uniform image2D colorimg##n;
#define DECL_COLORTEX_U(format, n) layout(format) uniform uimage2D colorimg##n;
#else
#define DECL_COLORTEX(format, n) uniform sampler2D colortex##n;
#define DECL_COLORTEX_U(format, n) uniform usampler2D colortex##n;
#endif

/*
const int colortex0Format = RGBA16F;
*/
DECL_COLORTEX(rgba16f, 0);

/*
const int colortex1Format = RG8_SNORM;
const vec4 colortex1ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
*/
DECL_COLORTEX(rg8_snorm, 1);

/*
const int colortex2Format = RG32UI;
const vec4 colortex2ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
*/
DECL_COLORTEX_U(rg32ui, 2);

#undef DECL_COLORTEX