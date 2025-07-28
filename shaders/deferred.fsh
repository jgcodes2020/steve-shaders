#version 410 compatibility

// ===============================================
// OPAQUE LIGHTING PASS
// ===============================================

uniform sampler2D colortex0; // colour
uniform sampler2D colortex1; // light info
uniform sampler2D colortex2; // normal info

uniform sampler2D depthtex0; // depth
uniform sampler2D depthtex1; // depth (opaque)

uniform sampler2DShadow shadowtex0; // shadow distance
uniform sampler2DShadow shadowtex1; // shadow distance (opaque)

uniform vec3 shadowLightPosition; // sun/moon angle
uniform vec3 sunPosition; // sun angle

uniform mat4 gbufferModelView; // world -> view
uniform mat4 gbufferProjectionInverse; // NDC -> view
uniform mat4 gbufferModelViewInverse; // view -> world
uniform mat4 shadowModelView; // player -> shadow
uniform mat4 shadowProjection; // shadow -> shadow NDC

uniform vec3 skyLightColor; // skylight color (depending on moon, sun, and weather)

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

#include "/lib/util.glsl"
#include "/lib/lighting.glsl"
#include "/lib/shadow.glsl"

void main() {
	color = texture(colortex0, texcoord);

	// fetch other values
	vec2 lightmap = texture(colortex1, texcoord).rg;
	vec3 normal = colorToNormal(texture(colortex2, texcoord));
	float depth = texture(depthtex0, texcoord).r;

	if (depth == 1.0) {
		return;
	}
	
	// gamma corection
	color.rgb = pow(color.rgb, vec3(SRGB_GAMMA));
	// lightmap scaling
	lightmap.rg = (lightmap.rg - (1.0 / 32.0)) * 32.0 / 30.0;

	// vector to sunlight
	vec3 shadowLightVector = txLinear(
		gbufferModelViewInverse, 
		normalize(shadowLightPosition)
	);

	// SHADOW-SPACE TRANSFORMATION
	// ===============================================

	vec3 viewPos = screenToView(texcoord, depth);
	// vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 feetPlayerPos = txAffine(gbufferModelViewInverse, viewPos);
	vec3 shadowViewPos = txAffine(shadowModelView, feetPlayerPos);

	vec3 shadowScreenPos = shadowViewToScreen(shadowViewPos);
	
	float shadow = pcfShadowTexture(shadowtex1, shadowScreenPos);

	// LIGHTING
	// ===============================================

	float cosSunToUp = dot(normalize(sunPosition), gbufferModelView[1].xyz);
	float dayFactor = horizonStep(cosSunToUp, daySatAngle);
	float nightFactor = horizonStep(cosSunToUp, nightSatAngle);
	vec3 skyLightColor = dayFactor * dayLightColor + nightFactor * nightLightColor;
	vec3 skyAmbientColor = dayFactor * dayAmbientColor + nightFactor * nightAmbientColor;

	// diffuse sunlight + ambient (skylights)
	vec3 skyLight = skyLightColor * clamp(dot(shadowLightVector, normal), 0.0, 1.0);
	vec3 skyTotal = skyAmbientColor * lightmap.g + skyLight * shadow;

	// block lighting
	vec3 blockTotal = blockLightColor * lightmap.r;

	// combine lighting onto colour
	color.rgb = (skyTotal + blockTotal);
	
	// TONEMAPPING
	// ===============================================

	// inverse gamma correction
	color.rgb = pow(color.rgb, vec3(SRGB_GAMMA_INV));

	
}