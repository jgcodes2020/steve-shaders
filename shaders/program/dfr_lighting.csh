#version 460 compatibility

#define COMPUTE_SHADER
#include "/lib/common.glsl"
#include "/lib/pack.glsl"

layout (local_size_x = 16, local_size_y = 16) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);

void evalPixel(inout vec3 color, ivec2 screenCoords) {
  vec3 normal = unpackNormal(imageLoad(colorimg1, screenCoords).xy);
  LightInfo light = unpackLightInfo(imageLoad(colorimg2, screenCoords).xy);
}

void main() {
  ivec2 screenCoords = ivec2(gl_GlobalInvocationID.xy);

  // convert to linear
  vec3 color = imageLoad(colorimg0, screenCoords).xyz;
  color = pow(color, vec3(SRGB_GAMMA));

  evalPixel(color, screenCoords);

  imageStore(colorimg0, screenCoords, vec4(color, 1.0));
}