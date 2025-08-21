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
layout(depth_unchanged) out float gl_FragDepth;

void main() {
  // opaque surfaces don't need to do anything except
  // update the fragment depth
  vec4 color = texture(gtexture, v.uvTex) * v.color;
#ifdef ALPHA_TEST
  if (color.a < alphaTestRef) {
    discard;
  }
#endif
}