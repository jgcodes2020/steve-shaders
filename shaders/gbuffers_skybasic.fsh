#version 410 compatibility

uniform sampler2D lightmap;

uniform float alphaTestRef = 0.1;

in vec4 glcolor;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightInfo;
layout(location = 2) out vec4 normInfo;

#include "/lib/util.glsl"

void main() {
  if (renderStage == MC_RENDER_STAGE_STARS) {
    color = glcolor;
    return;
  }

  color.rgb = skyColor * 1.2;

  lightInfo = vec4(0.0, 0.0, 0.0, 1.0);
  normInfo = COL_NORMAL_NONE;
}