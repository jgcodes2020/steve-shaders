#version 460 compatibility

#define COMPUTE_SHADER
#include "/lib/common.glsl"
#include "/lib/pack.glsl"

layout (local_size_x = 16, local_size_y = 16) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);

void evalPixel(out vec3 color, ivec2 screenCoords) {
  LightInfo l = unpackLightInfo(imageLoad(colorimg2, screenCoords).xy);
  color = vec3(l.vanilla, 0.0);
}

void main() {
  ivec2 screenCoords = ivec2(gl_GlobalInvocationID.xy);

  vec3 color;
  evalPixel(color, screenCoords);
  imageStore(colorimg0, screenCoords, vec4(color, 1.0));
}