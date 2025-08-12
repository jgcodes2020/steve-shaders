#ifndef UNIFORMS_GLSL_INCLUDED
#define UNIFORMS_GLSL_INCLUDED

uniform sampler2D colortex0; // primary color buffer
uniform sampler2D colortex1; // primary normal buffer
uniform sampler2D colortex2; // lighting and auxiliary data

uniform mat4 gbufferModelViewInverse; // view -> player space

uniform vec4 entityColor; // overlay color for entities
uniform float alphaTestRef; // alpha testing threshold

#endif