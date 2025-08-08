#version 410 compatibility

uniform sampler2D lightmap;

uniform float alphaTestRef = 0.1;

in vec4 glcolor;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightInfo;
layout(location = 2) out vec4 normInfo;

#include "/lib/common.glsl"
#include "/lib/sky/model.glsl"

float fogCurve(float x) {
  const float w = 0.05;
  return w / (x * x + w);
}

vec3 vanillaSky(vec3 eyePos) {
  float cosViewToUp = normalize(eyePos).y;
  return mix(skyColor, fogColor, fogCurve(max(cosViewToUp, 0.0)));
}

void main() {
  color = glcolor;
  if (renderStage == MC_RENDER_STAGE_STARS || color.a < 1.0) {
    return;
  }
  vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), 1.0);
  vec3 ndcPos = screenPos * 2.0 - 1.0;
  vec3 viewPos = txProjective(gbufferProjectionInverse, ndcPos);
  vec3 eyePos = txLinear(gbufferModelViewInverse, viewPos);
  color = vec4(vanillaSky(eyePos), 1.0);

  const uint lightFlags = LTG_SKY;

  lightInfo = vec4(0.0, 0.0, flagsToColor(lightFlags), 1.0);
  normInfo = COL_NORMAL_NONE;
}