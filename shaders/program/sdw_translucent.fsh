#version 460 compatibility

#define LOOKUP_COMPUTE_SHADER
#include "/lib/common.glsl"
#include "/lib/buffers.glsl"
#include "/lib/props/block.glsl"

uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;

in VertexData {
  vec4 color;
  vec2 uvTex;
  flat int entityID;
}
v;

// naming scheme: bThing = buffer for thing
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 bColor;
layout(depth_unchanged) out float gl_FragDepth;

void main() {
  bColor = texture(gtexture, v.uvTex) * v.color;
// #ifdef ENTITY_COLOR
//   bColor = mix(bColor, entityColor.rgb, entityColor.a);
// #endif
  
  if (bColor.a < alphaTestRef) {
    discard;
  }
  if (bp_isTintedGlass(v.entityID)) {
    bColor.a = 1.0;
  }

  // custom depth buffer
  uint uDepth = encodeShadowDepth(gl_FragCoord.z);
  imageAtomicMax(img_tlShadow, ivec2(gl_FragCoord.xy), uDepth);
}