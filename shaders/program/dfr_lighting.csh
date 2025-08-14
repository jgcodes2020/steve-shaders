#version 460 compatibility

#define COMPUTE_SHADER
#include "/lib/common.glsl"
#include "/lib/pack.glsl"

#include "/lib/lighting/model.glsl"
#include "/lib/lighting/overworld.glsl"

layout (local_size_x = 16, local_size_y = 16) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);

void main() {
  ivec2 screenCoords = ivec2(gl_GlobalInvocationID.xy);

  vec4 color = imageLoad(colorimg0, screenCoords);
  
  color.rgb = pow(color.rgb, vec3(SRGB_GAMMA));

  imageStore(colorimg0, screenCoords, color);
}