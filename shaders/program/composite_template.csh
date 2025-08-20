#version 460 compatibility

#define COMPUTE_SHADER
#include "/lib/common.glsl"
#include "/lib/buffers.glsl"

layout (local_size_x = 16, local_size_y = 16) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);

void evalPixel(ivec2 pixelCoords, inout vec3 color) {
  vec2 screenCoords = vec2(pixelCoords) / vec2(viewWidth, viewHeight);
}

void main() {
  ivec2 pixelCoords = ivec2(gl_GlobalInvocationID.xy);
}