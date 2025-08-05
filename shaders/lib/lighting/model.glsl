#ifndef LIGHTING_MODEL_GLSL_INCLUDED
#define LIGHTING_MODEL_GLSL_INCLUDED

#include "/lib/common.glsl"
#include "/lib/lighting/shadow.glsl"

// sRGB: 252, 252, 222
const vec3 blockLightColor = vec3(0.974, 0.974, 0.737);
const vec3 ambientColor    = vec3(0.1);

const vec3 dayLightColor   = vec3(1.0, 1.0, 1.0);
const vec3 dayAmbientColor = vec3(0.15, 0.15, 0.15);

const vec3 nightLightColor   = vec3(0.02, 0.05, 0.1);
const vec3 nightAmbientColor = vec3(0.05, 0.05, 0.05);

const vec3 nightVisionAmbientColor = vec3(0.5, 0.5, 0.5);

// Angle cosines relative to the horizon where full
// brightness should be achieved.
// sin(25)  ~  0.258819
// sin(-10) ~ -0.173648
const float daySatAngle   = 0.258819;
const float nightSatAngle = -0.173648;

// notes from vanilla lighting implementation
// sunrise: 22800 to 1000
// sunset: 11300 to 13200
// -> night: sun is ~10 degrees below horizon (theta = 100)
// -> day: sun is ~25 degrees above horizon (theta = 75)

// SHADOW-SPACE TRANSFORMATIONS
// ===============================================

// LIGHTING MODEL
// ===============================================

struct LightingInfo {
  vec4 color;
  vec2 light;
  uint lightFlags;
  vec3 normal;
  float depth;
};

bool readLightInfo(vec2 texcoord, out LightingInfo info) {
  // Fetch data values
  vec4 color1Sample = texture(colortex1, texcoord);

  info = LightingInfo(
    texture(colortex0, texcoord),                 // color
    color1Sample.rg,                              // light
    colorToFlags(color1Sample.b),                 // lightFlags
    colorToNormal(texture(colortex2, texcoord)),  // normal
    texture(depthtex1, texcoord).r                // depth
  );

  // gamma corection
  info.color.rgb = pow(info.color.rgb, vec3(SRGB_GAMMA));
  info.light.rg  = pow(info.light.rg, vec2(SRGB_GAMMA));

  return info.depth == 1.0;
}

void getSkyColors(out vec3 skyAmbientColor, out vec3 skyLightColor) {
  float cosSunToUp  = dot(normalize(sunPosition), gbufferModelView[1].xyz);
  float dayFactor   = horizonStep(cosSunToUp, daySatAngle);
  float nightFactor = horizonStep(cosSunToUp, nightSatAngle);

  skyLightColor = dayFactor * dayLightColor + nightFactor * nightLightColor;
  skyAmbientColor =
    dayFactor * dayAmbientColor + nightFactor * nightAmbientColor;
  skyAmbientColor = mix(skyAmbientColor, nightVisionAmbientColor, nightVision);
}

vec3 approxLightModel(
  vec2 light, vec3 normal, vec3 lightDir, float shadow, vec3 skyAmbientColor,
  vec3 skyLightColor) {
  vec3 skyLight = skyLightColor;
  vec3 skyTotal =
    (skyAmbientColor + skyLight * shadow) * max(light.g, nightVision);
  vec3 blockTotal = blockLightColor * light.r;
  
  return skyTotal + blockTotal;
}

vec3 diffuseLightModel(
  vec2 light, vec3 normal, vec3 lightDir, float shadow, vec3 skyAmbientColor,
  vec3 skyLightColor) {
  vec3 skyLight = skyLightColor * clamp(dot(lightDir, normal), 0.0, 1.0);
  vec3 skyTotal =
    (skyAmbientColor + skyLight * shadow) * max(light.g, nightVision);
  vec3 blockTotal = blockLightColor * light.r;

  return skyTotal + blockTotal;
}

#endif