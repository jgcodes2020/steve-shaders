#version 410 compatibility

// ===============================================
// LIGHTING PASS
// ===============================================

#include "/lib/lighting.glsl"
#include "/lib/shadow.glsl"
#include "/lib/util.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);

  // color = vec4(texcoord, 0.0, 1.0);
}