uniform sampler2D lightmap;
uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec4 glcolor;
#ifdef GBUFFERS_USE_TEXTURE
in vec2 texcoord;
#endif
#ifdef GBUFFERS_PASS_LIGHT
in vec2 vtlight;
#endif
#ifdef GBUFFERS_PASS_NORMAL
in vec3 normal;
#endif

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightInfo;
layout(location = 2) out vec4 normInfo;

#include "/lib/util.glsl"

void main() {
  #ifdef GBUFFERS_USE_TEXTURE
  color = texture(gtexture, texcoord) * glcolor;
  #else
  color = glcolor;
  #endif

  if (color.a < alphaTestRef) {
    discard;
  }

  #ifdef GBUFFERS_LIGHT_FLAGS
  const float lightFlagsCol = float(int(GBUFFERS_LIGHT_FLAGS) & 0xFF) / 255.0;
  #else
  const float lightFlagsCol = 0.0;
  #endif

  #ifdef GBUFFERS_PASS_LIGHT
  lightInfo = vec4(vtlight, lightFlagsCol, 1.0);
  #else
  lightInfo = vec4(0.0, 0.0, lightFlagsCol, 1.0);
  #endif


  
  #ifdef GBUFFERS_PASS_NORMAL
  normInfo  = normalToColor(normal);
  #else
  normInfo = COL_NORMAL_NONE;
  #endif
}