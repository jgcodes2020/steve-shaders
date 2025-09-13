#ifndef UNIFORMS_GLSL_INCLUDED
#define UNIFORMS_GLSL_INCLUDED

uniform mat4 gbufferModelView;          // world -> view
uniform mat4 gbufferProjectionInverse;  // NDC -> view
uniform mat4 gbufferModelViewInverse;   // view -> world
uniform mat4 shadowModelView;           // player -> shadow
uniform mat4 shadowProjection;          // shadow -> shadow NDC

uniform vec3 shadowLightPosition;  // sun/moon angle
uniform vec3 sunPosition;          // sun angle
uniform float rainStrength;        // 0 for clear, 1 when raining

uniform float nightVision;  // multiplier for night vision effect
uniform float blindness;    // multiplier for blindness effect

uniform bool firstPersonCamera;  // whether the player is in first-person

uniform int renderStage;     // render stage
uniform int frameCounter;    // frame counter
uniform float alphaTestRef;  // maximum opacity that we can ignore
uniform vec4 entityColor;    // overlay color for entities
uniform vec3 skyColor;       // sky color

uniform vec3 fogColor;   // fog color
uniform float fogStart;  // linear fog: starting dist
uniform float fogEnd;    // linear fog: ending dist
uniform float far;       // a distance that's kinda far. yeah.

uniform float viewWidth;   // viewport width
uniform float viewHeight;  // viewport height

// CUSTOM UNIFORMS
// ============================
uniform vec3 waterColor; // a rough guess for the biome's water colour

#endif