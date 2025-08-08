#version 410 compatibility

#include "/lib/common.glsl"
#include "/lib/lighting/shadow.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);
  // float depth = texture(depthtex1, texcoord).r;
  
  // vec4 clipPos = screenToShadowClip(vec3(texcoord, depth));

  // float shadowDepth = (clipPos.z / clipPos.w) * 0.5 + 0.5;
  // color.rgb = vec3(shadowDepth);
  // color.a = 1.0;
}