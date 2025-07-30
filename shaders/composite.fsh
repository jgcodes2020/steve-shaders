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
	// fetch other values
	color = texture(colortex0, texcoord);
	vec2 lightmap = texture(colortex1, texcoord).rg;
	vec3 normal = colorToNormal(texture(colortex2, texcoord));
	float depth = texture(depthtex1, texcoord).r;

	vec4 tlColor = texture(colortex4, texcoord);
	vec2 tlLightmap = texture(colortex5, texcoord).rg;
	vec3 tlNormal = colorToNormal(texture(colortex6, texcoord));
	float tlDepth = texture(depthtex0, texcoord).r;

	// skip this fragment if it's entirely sky
	if (depth + tlDepth == 2.0) {
		return;
	}
	
	// gamma corection
	color.rgb = pow(color.rgb, vec3(SRGB_GAMMA));
	lightmap.rg = pow(lightmap.rg, vec2(SRGB_GAMMA));

	tlColor.rgb = pow(tlColor.rgb, vec3(SRGB_GAMMA));
	tlLightmap.rg = pow(tlLightmap.rg, vec2(SRGB_GAMMA));

	// vector to sunlight
	vec3 lightDir = txLinear(
		gbufferModelViewInverse, 
		normalize(shadowLightPosition)
	);

	// SHADOW-SPACE CALCULATIONS
	// ===============================================
	vec3 shadowPos = screenToShadowScreen(vec3(texcoord, depth), normal);
	float shadow = computeShadowSoft(shadowPos);

	vec3 tlShadowPos = screenToShadowScreen(vec3(texcoord, tlDepth), tlNormal);
	float tlShadow = tlComputeShadowSoft(tlShadowPos, tlColor.a);

	// LIGHTING CONSTANTS
	// ===============================================

	float cosSunToUp = dot(normalize(sunPosition), gbufferModelView[1].xyz);
	float dayFactor = horizonStep(cosSunToUp, daySatAngle);
	float nightFactor = horizonStep(cosSunToUp, nightSatAngle);
	vec3 skyLightColor = dayFactor * dayLightColor + nightFactor * nightLightColor;
	vec3 skyAmbientColor = dayFactor * dayAmbientColor + nightFactor * nightAmbientColor;

	// OPAQUE LIGHTING
	// ===============================================

	if (depth < 1.0) {
		vec3 skyLight = skyLightColor * clamp(dot(lightDir, normal), 0.0, 1.0);
		vec3 skyTotal = skyAmbientColor * lightmap.g + skyLight * shadow;
		vec3 blockTotal = blockLightColor * lightmap.r;

		color.rgb *= (skyTotal + blockTotal);
	}

	// TRANSLUCENT LIGHTING
	// ===============================================

	if (tlDepth < 1.0) {
		vec3 tlSkyLight = skyLightColor * clamp(dot(lightDir, tlNormal), 0.0, 1.0);
		vec3 tlSkyTotal = skyAmbientColor * tlLightmap.g + tlSkyLight * tlShadow;
		vec3 tlBlockTotal = blockLightColor * tlLightmap.r;

		tlColor.rgb *= (tlSkyTotal + tlBlockTotal);
	}

	// COMPOSITE AND TONEMAP
	// ===============================================

	// composite translucent onto colour
	color.rgb = color.rgb * (1.0 - tlColor.a) + tlColor.rgb;
	
	// Reinhard-Jodie tonemap
	color.rgb = reinhardJodie(color.rgb);
	
	// inverse gamma correction
	color.rgb = pow(color.rgb, vec3(SRGB_GAMMA_INV));

	
}