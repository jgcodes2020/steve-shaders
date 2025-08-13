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

  vec3 color = imageLoad(colorimg0, screenCoords).xyz;
  vec3 normal = imageLoad(colorimg1, screenCoords).xyz;
  FragInfo info = unpackFragInfo(imageLoad(colorimg2, screenCoords).xy);

  // color = vec3(abs(normal.r));

  // convert to linear
  color.rgb = pow(color.rgb, vec3(SRGB_GAMMA));
  info.vtLight = pow(info.vtLight, vec2(SRGB_GAMMA));

  if (info.geoType != GEO_TYPE_SKY) {
    // compute light colours
    vec3 skyAmbientColor, skyLightColor;
    ltOverworld_skyColors(skyAmbientColor, skyLightColor);

    // organize lighting data
    LightPixelInfo lpInfo = LightPixelInfo(
      color.rgb, // color
      normal, // normal
      info.vtLight, // vtLight
      info.ao // ao
    );

    // apply lighting model
    color.rgb = lt_diffuseLighting(lpInfo, skyAmbientColor, skyLightColor, blockLightColor);
  }

  imageStore(colorimg0, screenCoords, vec4(color, 1.0));
}