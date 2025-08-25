#version 460 compatibility

#include "/lib/buffers.glsl"
#include "/lib/common.glsl"

uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;

in VertexData {
#ifdef USE_VCOLOR
  vec4 color;
#endif

#ifdef USE_TEXTURE
  vec2 uvTex;
#endif
}
v;

#if defined(TRANSLUCENT) && !defined(WRITE_FRAG_INFO)
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 bColor;
#else
/* RENDERTARGETS: 0,1 */
layout(location = 0) out vec4 bColor;
layout(location = 1) out uvec4 bFragInfo;
#endif

void main() {
#ifdef USE_TEXTURE
  #ifdef USE_VCOLOR
  bColor = texture(gtexture, v.uvTex) * v.color;
  #else
  bColor = texture(gtexture, v.uvTex);
  #endif
  #ifndef TRANSLUCENT
  bColor.a = 1.0;
  #endif
#else
  #ifdef TRANSLUCENT
  bColor = v.color;
  #else
  bColor = vec4(v.color.rgb, 1.0);
  #endif
#endif
#ifdef ALPHA_TEST
  if (bColor.a < alphaTestRef)
    discard;
#endif

  #ifdef TRANSLUCENT
  // correct to linear premultiplied color
  bColor.rgb *= bColor.a;
  bColor.rgb = pow(bColor.rgb, vec3(SRGB_GAMMA));
  #endif

  // brighten the colour to compensate for tonemapping
  bColor.rgb *= 2.0;

  #if !defined(TRANSLUCENT) || defined(WRITE_FRAG_INFO)
  // send pure-emissive fragment info to lighting pass
  bFragInfo = PACK_PURE_EMISSIVE;
  #endif

  #ifdef DEBUG
  bColor = vec4(1.0, 0.0, 0.0, 1.0);
  #endif
}