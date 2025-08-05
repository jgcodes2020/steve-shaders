#version 410 compatibility

uniform sampler2D lightmap;

uniform float alphaTestRef = 0.1;

in vec4 glcolor;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightInfo;
layout(location = 2) out vec4 normInfo;

#include "/lib/common.glsl"

float fogCurve(float x) {
  const float w = 0.25;
  return w / (x * x + w);
}

vec3 vanillaSky(vec3 viewDir) {
  float cosViewToUp = dot(viewDir, gbufferModelView[1].xyz);
  return mix(skyColor, fogColor, fogCurve(max(cosViewToUp, 0.0)));
}

void main() {
  if (renderStage == MC_RENDER_STAGE_STARS) {
    color = glcolor;
    return;
  }

  vec2 ndcXY =
    fma(gl_FragCoord.xy, vec2(2.0) / vec2(viewWidth, viewHeight), vec2(-1.0));
  vec3 viewDir = txProjective(gbufferProjectionInverse, vec3(ndcXY, 1.0));
  viewDir      = normalize(viewDir);

  color = vec4(vanillaSky(viewDir), 1.0);

  lightInfo = vec4(0.0, 0.0, 0.0, 1.0);
  normInfo  = COL_NORMAL_NONE;
}