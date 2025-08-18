#version 460 compatibility

#include "/lib/common.glsl"
#include "/lib/props/block.glsl"
#include "/lib/lighting/shadow.glsl"


in vec2 mc_midTexCoord;
in vec3 mc_Entity;

out VertexData {
  vec4 color;
  vec2 uvTex;
  flat int entityID;
}
v;

void main() {
  v.color = gl_Color;
  v.uvTex = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  v.entityID = int(mc_Entity.x);

  // discard debug lines by noting they aren't textured
  if (mc_midTexCoord == vec2(0.0)) {
    gl_Position = vec4(-1.0);
    return;
  }

  vec3 vertex = gl_Vertex.xyz;
  vec3 normal = gl_Normal;

  // Adjust plant geometry to make shadows appear at noon.
  // This is done in model space before transformation occurs.
  if (bp_isPlant(v.entityID)) {
    const float PUSH_FACTOR = 0.2;
    vec2 uvTexMid = (gl_TextureMatrix[0] * vec4(mc_midTexCoord, 0.0, 1.0)).xy;
    vertex += normal * PUSH_FACTOR * sign(v.uvTex.y - uvTexMid.y);
  }

  // Transform to clip space and apply shadow distortion.
  gl_Position = gl_ModelViewProjectionMatrix * vec4(vertex, 1.0);
  gl_Position.xyz = shadowDistort(gl_Position.xyz);
}