#version 460 compatibility

#define COMPUTE_SHADER
#include "/lib/common.glsl"
#include "/lib/buffers.glsl"

#include "/lib/math/easing.glsl"

#include "/lib/sky/current_dim.glsl"


layout (local_size_x = 16, local_size_y = 16) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);

void evalPixel(ivec2 pixelCoords, inout vec3 color) {
  uvec4 fragInfoPacked = imageLoad(colorimg1, pixelCoords);
  FragInfo i = unpackFragInfo(fragInfoPacked);

  vec2 screenCoords = vec2(pixelCoords) / vec2(viewWidth, viewHeight);
  float depth = texture(depthtex0, screenCoords).r;

  if (depth == 1.0) {
    return;
  }

  // compute NDC; accounting for the hand being shifted during projection
  vec3 ndcPos = fma(vec3(screenCoords, depth), vec3(2.0), vec3(-1.0));
  if (i.hand) {
    const float invHandDepth = 1.0 / MC_HAND_DEPTH;
    ndcPos.z *= invHandDepth;
  }

	vec3 viewPos = txInvProj(gbufferProjectionInverse, ndcPos);
  vec3 viewDir = normalize(viewPos);

	vec3 distFogColor = pow(computeSkybox(viewDir), vec3(SRGB_GAMMA));
  float distFogFactor = linearStep(far * 0.8, far * 0.95, length(viewPos));

  color = mix(color, distFogColor, distFogFactor);
}

void main() {
  ivec2 pixelCoords = ivec2(gl_GlobalInvocationID.xy);
  if (greaterThanEqual(pixelCoords, vec2(viewWidth, viewHeight)) != bvec2(false, false)) {
    return;
  }

  vec3 color = imageLoad(colorimg0, pixelCoords).rgb;
  evalPixel(pixelCoords, color);

  imageStore(colorimg0, pixelCoords, vec4(color, 1.0));
}