#version 460 compatibility

#include "/lib/buffers.glsl"
#include "/lib/common.glsl"

uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;

in VertexData {
  vec4 color;
  vec2 uvTex;
}
v;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 bColor;

void main() {
  bColor = texture(gtexture, v.uvTex) * v.color;

  vec2 ndcPos = fma(gl_FragCoord.xy, 2.0 / vec2(viewWidth, viewHeight), vec2(-1.0));
	vec3 viewPos = txInvProj(gbufferProjectionInverse, vec3(ndcPos, 1.0));
  vec3 viewDir = normalize(viewPos);

  float vDotU = dot(viewDir, gbufferModelView[1].xyz);
  float brightnessFactor = fma(vDotU, 0.5, 0.5);

  float vDotS = dot(viewDir, sunPosition * 0.01);
  float maxBrightness = (vDotS > 0.0)? 5.0 : 3.0;

  bColor.rgb *= mix(2.0, maxBrightness, brightnessFactor);
  bColor.a = 0.0;
}