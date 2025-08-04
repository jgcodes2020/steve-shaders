#version 410 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec2 vtlight;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightInfo;
layout(location = 2) out vec4 normInfo;

#include "/lib/lighting.glsl"
#include "/lib/util.glsl"

void main() {
  color = texture(gtexture, texcoord) * glcolor;
  if (color.a < alphaTestRef) {
    discard;
  }

  // Gamma correction
  color.rgb  = pow(color.rgb, vec3(SRGB_GAMMA));
  vec2 light = pow(vtlight, vec2(SRGB_GAMMA));

  // Compute screen-space coordinates
  vec2 fragCoord = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
  float depth    = gl_FragCoord.z;

  // color = vec4(fragCoord, 0.0, 1.0);
  // color.rgb = pow(color.rgb, vec3(SRGB_GAMMA));
  // return;

  // SHADOW-SPACE CALCULATIONS
  // ===============================================

  // vector to sunlight
  vec3 lightDir =
    txLinear(gbufferModelViewInverse, normalize(shadowLightPosition));

  // shadow calculation
  vec4 shadowClipPos = screenToShadowClip(vec3(fragCoord, depth));
  float shadow =
    tlComputeShadowSoft(shadowClipPos, 1.0, normal, ivec2(gl_FragCoord.xy));
  // float shadow = 0.0;

  // LIGHTING CONSTANTS
  // ===============================================

  vec3 skyAmbientColor, skyLightColor;
  getSkyColors(skyAmbientColor, skyLightColor);

  // LIGHTING
  // ===============================================

  vec3 lightMult = computeLightMult(
    light, normal, lightDir, shadow, skyAmbientColor, skyLightColor);
  color.rgb *= lightMult;

  lightInfo = vec4(light, 0.0, 1.0);
  normInfo  = normalToColor(normal);
}