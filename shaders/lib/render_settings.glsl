#ifndef RENDER_SETTINGS_GLSL_INCLUDED
#define RENDER_SETTINGS_GLSL_INCLUDED

/*
const int colortex0Format = RGB16F;
const int colortex1Format = RGB8;
const int colortex2Format = RGB8;
*/

const vec4 colortex2ClearColor = vec4(0.5, 0.5, 0.5, 1.0);

const int shadowMapResolution      = 2048;
const float shadowDistance         = 160.0;
const bool shadowHardwareFiltering = true;

const int noiseTextureResolution = 256;

#endif