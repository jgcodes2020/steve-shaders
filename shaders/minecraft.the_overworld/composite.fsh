#version 410 compatibility

// ===============================================
// LIGHTING PASS
// ===============================================

#include "/lib/lighting/model.glsl"
#include "/lib/lighting/shadow.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);
}