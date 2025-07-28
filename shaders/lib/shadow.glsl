vec3 distortShadowClipPos(vec3 shadowClipPos){
  // distort geometry by distance from player
  float distortionFactor = length(shadowClipPos.xy);
  // very small distances can cause issues so we add this to slightly reduce the distortion
  distortionFactor += 0.1;

  shadowClipPos.xy /= distortionFactor;
  // increases shadow distance on the Z axis, which helps when the sun is very low in the sky
  shadowClipPos.z *= 0.5;
  return shadowClipPos;
}

const int shadowMapResolution = 2048;

const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;
const bool shadowcolor0Nearest = true;