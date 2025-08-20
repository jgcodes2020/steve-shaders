#version 460 compatibility

#include "/lib/common.glsl"
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
  // This implements purely opaque shadowing with support for one transparent occluder.
  // Transparent shadows are handled by considering the frontmost surface.
  bColor = texture(gtexture, v.uvTex) * v.color;
  if (bColor.a < alphaTestRef) {
    discard;
  }
  if (bp_isTintedGlass(v.entityID)) {
    bColor.a = 1.0;
  }
}