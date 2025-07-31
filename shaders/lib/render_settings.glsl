#ifndef RENDER_SETTINGS_GLSL_INCLUDED
#define RENDER_SETTINGS_GLSL_INCLUDED

/*
const int colortex0Format = RGBF16;
const int colortex1Format = RGB8;
*/

const int shadowMapResolution = 2048;
const float shadowDistance = 160.0;
const bool shadowHardwareFiltering = true;

/*
// Setup transparent color buffer
const int colortex4Format = RGBA8;
const vec4 colortex4ClearColor = vec4(0.0, 0.0, 0.0, 0.0);

// Setup normal buffer
const int colortex1Format = RGB8;
const int colortex5Format = RGB8;

// clear normal buffers to empty normal
const vec4 colortex2ClearColor = vec4(0.5, 0.5, 0.5, 1.0);
const vec4 colortex6ClearColor = vec4(0.5, 0.5, 0.5, 1.0);
*/

#endif