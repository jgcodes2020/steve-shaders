#ifndef RENDER_SETTINGS_GLSL_INCLUDED
#define RENDER_SETTINGS_GLSL_INCLUDED

/*
const int colortex0Format = RGB16F;
const int colortex1Format = RGB8;
const int colortex2Format = RGB8;
const int colortex4Format = RGBA16F;
const int colortex5Format = RGB8;
const int colortex6Format = RGB8;
*/

// const bool shadowcolor0Nearest = true;
// const bool shadowtex0Nearest = true;
// const bool shadowtex1Nearest = true;

const vec4 colortex2ClearColor = vec4(0.5, 0.5, 0.5, 1.0);
const vec4 colortex4ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const vec4 colortex6ClearColor = vec4(0.5, 0.5, 0.5, 1.0);

const int shadowMapResolution = 2048;
const float shadowDistance = 160.0;
const bool shadowHardwareFiltering = true;

#endif