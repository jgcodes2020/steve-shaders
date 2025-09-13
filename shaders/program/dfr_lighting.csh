#version 460 compatibility

#define COMPUTE_SHADER
#include "/lib/common.glsl"
#include "/lib/buffers.glsl"

#include "/lib/sky/current_dim.glsl"

#include "/lib/lighting/model.glsl"
#include "/lib/lighting/shadow.glsl"
#include "/lib/lighting/overworld.glsl"

layout (local_size_x = 16, local_size_y = 16) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);

vec3 lightPixel(ivec2 pixelCoords, vec4 color, FragInfo i, vec3 viewPos, vec3 skyColor) {
  // // Get fragment info.
  // uvec4 fragInfoPacked = imageLoad(colorimg1, pixelCoords);
  // FragInfo i = unpackFragInfo(fragInfoPacked);
  
  // // evaluate screen space position.
  // vec2 screenCoords = vec2(pixelCoords) / vec2(viewWidth, viewHeight);
  // float depth = texture(depthtex0, screenCoords).r;

  // // compute NDC; accounting for the hand being shifted during projection
  // vec3 ndcPos = fma(vec3(screenCoords, depth), vec3(2.0), vec3(-1.0));
  // if (i.hand) {
  //   const float invHandDepth = 1.0 / MC_HAND_DEPTH;
  //   ndcPos.z *= invHandDepth;
  // }

  // // compute view position.
  // vec3 viewPos = txInvProj(gbufferProjectionInverse, ndcPos);
  // vec3 viewSpaceViewDir = normalize(viewPos);

  vec3 outColor = skyColor;

  if (i.emissive) {
    outColor = outColor * (1.0 - color.a) + color.rgb;
  }
  else {
    // compute shadow view position.
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

    outColor = pbrLightingOpaque(color.rgb, i, viewDir, shadow, ambientLight, skyLight, blockLightColor);
  }

  return outColor;
}

vec3 fogPixel(vec3 color, FragInfo i, vec3 viewPos, float depth, vec3 skyColor) {
  // distance fog
  if (!(depth == 1.0 && i.emissive)) {
    float distFogFactor = linearStep(far * 0.9, far, length(viewPos));
    color = mix(color, skyColor, distFogFactor);
  }

  return color;
}

vec3 evalPixel(ivec2 pixelCoords, vec4 color) {
  // Get fragment info.
  uvec4 fragInfoPacked = imageLoad(colorimg1, pixelCoords);
  FragInfo i = unpackFragInfo(fragInfoPacked);
  
  // evaluate screen space position.
  vec2 screenCoords = vec2(pixelCoords) / vec2(viewWidth, viewHeight);
  float depth = texture(depthtex0, screenCoords).r;

  // compute NDC; accounting for the hand being shifted during projection
  vec3 ndcPos = fma(vec3(screenCoords, depth), vec3(2.0), vec3(-1.0));
  if (i.hand) {
    const float invHandDepth = 1.0 / MC_HAND_DEPTH;
    ndcPos.z *= invHandDepth;
  }

  // compute view position.
  vec3 viewPos = txInvProj(gbufferProjectionInverse, ndcPos);
  vec3 viewSpaceViewDir = normalize(viewPos);

  // evaluate skybox.
  vec3 skyColor = computeSkybox(viewSpaceViewDir);
  skyColor = pow(skyColor, vec3(SRGB_GAMMA));

  // apply passes
  vec3 outColor = lightPixel(pixelCoords, color, i, viewPos, skyColor);
  outColor = fogPixel(outColor, i, viewPos, depth, skyColor);
  return outColor;
}

void main() {
  ivec2 pixelCoords = ivec2(gl_GlobalInvocationID.xy);
  if (greaterThanEqual(pixelCoords, vec2(viewWidth, viewHeight)) != bvec2(false, false)) {
    return;
  }

  vec4 color = imageLoad(colorimg0, pixelCoords);
  color.rgb = pow(color.rgb, vec3(SRGB_GAMMA));

  vec3 outColor = evalPixel(pixelCoords, color);

  imageStore(colorimg0, pixelCoords, vec4(outColor, 1.0));
}