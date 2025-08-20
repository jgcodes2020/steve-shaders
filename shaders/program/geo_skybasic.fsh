#version 460 compatibility

#include "/lib/common.glsl"
#include "/lib/buffers.glsl"

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
	return mix(skyColor, fogColor, fogify(max(vDotUp, 0.0), 0.1));
}

void main() {
  if (v.color.a < 1.0 && renderStage == MC_RENDER_STAGE_SKY) {
    bColor = v.color;
    return;
  }

  vec2 ndcPos = fma(gl_FragCoord.xy, 2.0 / vec2(viewWidth, viewHeight), vec2(-1.0));

	vec3 viewPos = vec3(
		vec2(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y) * ndcPos,
		gbufferProjectionInverse[3].z
	) / (gbufferProjectionInverse[2].w + gbufferProjectionInverse[3].w);

	bColor = vec4(sky(normalize(viewPos)), 1.0);

  if (renderStage == MC_RENDER_STAGE_STARS) {
    bColor.rgb += v.color.rgb;
  }
}