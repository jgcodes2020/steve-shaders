#ifndef UNIFORMS_GLSL_INCLUDED
#define UNIFORMS_GLSL_INCLUDED

uniform mat4 gbufferModelViewInverse; // view -> player space

uniform vec4 entityColor; // overlay color for entities
uniform float alphaTestRef; // alpha testing threshold

#endif