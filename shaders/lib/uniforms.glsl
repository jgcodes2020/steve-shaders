#ifndef UNIFORMS_GLSL_INCLUDED
#define UNIFORMS_GLSL_INCLUDED

uniform sampler2D colortex0; // colour
uniform sampler2D colortex1; // light info
uniform sampler2D colortex2; // normal info

uniform sampler2D colortex4; // colour
uniform sampler2D colortex5; // light info
uniform sampler2D colortex6; // normal info

uniform sampler2D depthtex0; // depth
uniform sampler2D depthtex1; // depth (opaque)

uniform sampler2DShadow shadowtex0; // shadow distance
uniform sampler2DShadow shadowtex1; // shadow distance (opaque)
uniform sampler2D shadowcolor0; // shadow color

uniform mat4 gbufferModelView; // world -> view
uniform mat4 gbufferProjectionInverse; // NDC -> view
uniform mat4 gbufferModelViewInverse; // view -> world
uniform mat4 shadowModelView; // player -> shadow
uniform mat4 shadowProjection; // shadow -> shadow NDC

uniform vec3 shadowLightPosition; // sun/moon angle
uniform vec3 sunPosition; // sun angle

uniform float nightVision; // multiplier for night vision effect

uniform vec3 skyColor; // sky color


#endif