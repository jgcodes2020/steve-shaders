#version 410 compatibility



// ===============================================
// LIGHTING PASS
// ===============================================

uniform sampler2D colortex0; // colour
uniform sampler2D colortex1; // light info
uniform sampler2D colortex2; // normal info

uniform sampler2D colortex4; // colour
uniform sampler2D colortex5; // light info
uniform sampler2D colortex6; // normal info

uniform sampler2D depthtex0; // depth
uniform sampler2D depthtex1; // depth (opaque)

uniform sampler2DShadow shadowtex0; // shadow distance
uniform sampler2DShadow shadowtex1; // shadow distance (opaque)
uniform sampler2D shadowcolor0; // shadow color

uniform vec3 shadowLightPosition; // sun/moon angle
uniform vec3 sunPosition; // sun angle

uniform mat4 gbufferModelView; // world -> view
uniform mat4 gbufferProjectionInverse; // NDC -> view
uniform mat4 gbufferModelViewInverse; // view -> world
uniform mat4 shadowModelView; // player -> shadow
uniform mat4 shadowProjection; // shadow -> shadow NDC

uniform float nightVision;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

#include "/lib/util.glsl"
#include "/lib/lighting.glsl"
#include "/lib/shadow.glsl"

void main() {
	LightingInfo info;
	if (readLightInfo(texcoord, info)) {
		return;
	}

	// SHADOW-SPACE CALCULATIONS
	// ===============================================

	// vector to sunlight
	vec3 lightDir = txLinear(
		gbufferModelViewInverse, 
		normalize(shadowLightPosition)
	);

	vec3 shadowPos = screenToShadowScreen(vec3(texcoord, info.depth), info.normal);
	float shadow = computeShadowSoft(shadowPos);
	if ((info.lightFlags & LTG_NO_SHADOW) != 0) {
		shadow = 1.0;
	}

	vec3 tlShadowPos = screenToShadowScreen(vec3(texcoord, info.tlDepth), info.tlNormal);
	float tlShadow = tlComputeShadowSoft(tlShadowPos, info.tlColor.a);
	if ((info.tlLightFlags & LTG_NO_SHADOW) != 0) {
		tlShadow = 1.0;
	}

	// LIGHTING CONSTANTS
	// ===============================================

	float cosSunToUp = dot(normalize(sunPosition), gbufferModelView[1].xyz);
	float dayFactor = horizonStep(cosSunToUp, daySatAngle);
	float nightFactor = horizonStep(cosSunToUp, nightSatAngle);
	vec3 skyLightColor = dayFactor * dayLightColor + nightFactor * nightLightColor;
	vec3 skyAmbientColor = dayFactor * dayAmbientColor + nightFactor * nightAmbientColor;

	// OPAQUE LIGHTING
	// ===============================================

	if (info.depth < 1.0) {
		vec3 skyLight = skyLightColor * clamp(dot(lightDir, info.normal), 0.0, 1.0);
		vec3 skyTotal = skyAmbientColor * info.lightmap.g + skyLight * shadow;
		vec3 blockTotal = blockLightColor * info.lightmap.r;

		info.color.rgb *= (skyTotal + blockTotal);
	}

	// TRANSLUCENT LIGHTING
	// ===============================================

	if (info.tlDepth < 1.0) {
		vec3 tlSkyLight = skyLightColor * clamp(dot(lightDir, info.tlNormal), 0.0, 1.0);
		vec3 tlSkyTotal = skyAmbientColor * info.tlLightmap.g + tlSkyLight * tlShadow;
		vec3 tlBlockTotal = blockLightColor * info.tlLightmap.r;

		info.tlColor.rgb *= (tlSkyTotal + tlBlockTotal);
	}

	// COMPOSITE AND TONEMAP
	// ===============================================

	// composite translucent onto colour
	info.color.rgb = info.color.rgb * (1.0 - info.tlColor.a) + info.tlColor.rgb;
	
	// Reinhard-Jodie tonemap
	info.color.rgb = reinhardJodie(info.color.rgb);
	
	// inverse gamma correction
	color.rgb = pow(info.color.rgb, vec3(SRGB_GAMMA_INV));	
}