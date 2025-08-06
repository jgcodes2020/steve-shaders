#ifndef POST_FOG_GLSL_INCLUDED
#define POST_FOG_GLSL_INCLUDED

#include "/lib/common.glsl"

const int FOG_EXP = 2048;
const int FOG_EXP2 = 2049;
const int FOG_LINEAR = 9729;

const int FOG_SPHERE = 0;
const int FOG_CYLINDER = 1;

// Based on advice from Lura
// https://github.com/Luracasmus/Base-460C/blob/fd6cfc2129fb5a3b1bb2c09383697be623cf2746/shaders/prog/generic.fsh#L80-L88
float getFog(vec3 eyePos) {
  float sphereDist = length(eyePos);
  float cylDist = max(length(eyePos.xy), abs(eyePos.y));

  float environmentFog = linearStep(fogStart, fogEnd, sphereDist);
  float borderFog = linearStep(far * 0.9, far, cylDist);

  return max(environmentFog, borderFog);
}

#endif