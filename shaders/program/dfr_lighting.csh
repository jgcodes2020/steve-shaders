#version 460 compatibility

#define COMPUTE_SHADER
#include "/lib/common.glsl"
#include "/lib/buffers.glsl"

#include "/lib/lighting/model.glsl"
#include "/lib/lighting/overworld.glsl"

layout (local_size_x = 16, local_size_y = 16) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);

void evalPixel(ivec2 pixelCoords, inout vec3 color) {
  uvec4 fragInfoPacked = imageLoad(colorimg1, pixelCoords);
  FragInfo i = unpackFragInfo(fragInfoPacked);

  if (!i.emissive) {
    vec2 screenCoords = vec2(pixelCoords) / vec2(viewWidth, viewHeight);
    float depth = texture(depthtex0, screenCoords).r;

    vec3 ndcPos = fma(vec3(screenCoords, depth), vec3(2.0), vec3(-1.0));
    vec3 viewPos = txProjective(gbufferProjectionInverse, ndcPos);
    vec3 viewDir = -normalize(mat3(gbufferModelViewInverse) * viewPos);

    vec3 ambientLight, skyLight;
    ltOverworld_skyColors(ambientLight, skyLight);

    color = pbrLightingOpaque(color, i, viewDir, ambientLight, skyLight);
  }
}

void main() {
  ivec2 pixelCoords = ivec2(gl_GlobalInvocationID.xy);

  vec3 color = imageLoad(colorimg0, pixelCoords).rgb;

  color = pow(color, vec3(SRGB_GAMMA));
  evalPixel(pixelCoords, color);

  imageStore(colorimg0, pixelCoords, vec4(color, 1.0));
}