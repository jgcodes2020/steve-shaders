#ifndef MATH_MISC_GLSL_INCLUDED
#define MATH_MISC_GLSL_INCLUDED

// x^(2.2) and x^(1/2.2) are approximations of the sRGB
// transfer function, but it's good enough.

const float SRGB_GAMMA = 2.2;
const float SRGB_GAMMA_RCP = 1.0 / 2.2;

#endif