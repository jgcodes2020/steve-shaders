#version 460 compatibility

#define COMPUTE_SHADER
#include "/lib/common.glsl"
#include "/lib/buffers.glsl"

#include "/lib/lighting/model.glsl"
#include "/lib/lighting/shadow.glsl"
#include "/lib/lighting/overworld.glsl"

layout (local_size_x = 16, local_size_y = 16) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);

void evalPixel(ivec2 pixelCoords, inout vec3 color) {
  uvec4 fragInfoPacked = imageLoad(colorimg1, pixelCoords);
  FragInfo i = unpackFragInfo(fragInfoPacked);

  if (!i.emissive) {
    vec2 screenCoords = vec2(pixelCoords) / vec2(viewWidth, viewHeight);
    float depth = texture(depthtex0, screenCoords).r;

    // compute NDC; accounting for the hand being shifted during projection
    vec3 ndcPos = fma(vec3(screenCoords, depth), vec3(2.0), vec3(-1.0));
    if (i.hand) {
      const float invHandDepth = 1.0 / MC_HAND_DEPTH;
      ndcPos.z *= invHandDepth;
    }

    // compute view and shadow view positions.
    vec3 viewPos = txProjective(gbufferProjectionInverse, ndcPos);
    vec3 feetPos = txAffine(gbufferModelViewInverse, viewPos);
    vec3 shadowViewPos = txAffine(shadowModelView, feetPos);

    // direction from pixel to camera.
    vec3 viewDir = -normalize(mat3(gbufferModelViewInverse) * viewPos);

    // shadow clip-space position of this pixel.
    vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
    vec3 shadow = computeShadowSoft(shadowClipPos, i.faceNormal, pixelCoords);
    // vec3 shadow = vec3(1.0);

    vec3 ambientLight, skyLight;
    ltOverworld_skyColors(ambientLight, skyLight);

    color = pbrLightingOpaque(color, i, viewDir, shadow, ambientLight, skyLight, blockLightColor);
  }
}

void main() {
  ivec2 pixelCoords = ivec2(gl_GlobalInvocationID.xy);
  if (greaterThanEqual(pixelCoords, vec2(viewWidth, viewHeight)) != bvec2(false, false)) {
    return;
  }

  vec3 color = imageLoad(colorimg0, pixelCoords).rgb;

  color = pow(color, vec3(SRGB_GAMMA));
  evalPixel(pixelCoords, color);

  imageStore(colorimg0, pixelCoords, vec4(color, 1.0));
}