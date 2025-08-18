#version 460 compatibility

#define SHADOW_COMPUTE_SHADER
#include "/lib/common.glsl"

layout (local_size_x = 16, local_size_y = 16) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);

void main() {
  ivec2 pixelCoords = ivec2(gl_GlobalInvocationID.xy);

  vec4 color = imageLoad(shadowcolorimg0, pixelCoords);

  // correct gamma
  color.rgb = pow(color.rgb, vec3(SRGB_GAMMA));

  imageStore(shadowcolorimg0, pixelCoords, color);
}