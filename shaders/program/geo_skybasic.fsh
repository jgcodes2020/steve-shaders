#version 460 compatibility

#include "/lib/common.glsl"
#include "/lib/buffers.glsl"
#include "/lib/sky/current_dim.glsl"

uniform sampler2D gtexture;

in VertexData {
  vec4 color;
}
v;

// The sky renders first, so the specular buffer is already
// pre-cleared with the emissive flag.
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 bColor;

float fogify(float x, float w) {
	return w / (x * x + w);
}

vec3 sky(vec3 viewDir) {
	float vDotUp = dot(viewDir, gbufferModelView[1].xyz); // Not much, what's up with you?
	return mix(skyColor, fogColor, fogify(max(vDotUp, 0.0), 0.05));
}

vec3[7] rainbow = vec3[](
  vec3(1.0, 0.0, 0.0),
  vec3(1.0, 0.5, 0.0),
  vec3(1.0, 1.0, 0.0),
  vec3(0.0, 1.0, 0.0),
  vec3(0.0, 1.0, 0.5),
  vec3(0.0, 0.25, 1.0),
  vec3(0.5, 0.0, 1.0)
);

void main() {

  if (renderStage == MC_RENDER_STAGE_STARS || v.color.a < 1.0) {
    bColor = v.color;
    return;
  }

  vec2 ndcPos = fma(gl_FragCoord.xy, 2.0 / vec2(viewWidth, viewHeight), vec2(-1.0));

	vec3 viewPos = txInvProj(gbufferProjectionInverse, vec3(ndcPos, 1.0));
  vec3 viewDir = normalize(viewPos);

	// bColor = vec4(sky(normalize(viewPos)), 1.0);
	bColor = vec4(computeSkybox(viewDir), 1.0);

  if (renderStage == MC_RENDER_STAGE_STARS) {
    bColor.rgb += v.color.rgb;
  }
}