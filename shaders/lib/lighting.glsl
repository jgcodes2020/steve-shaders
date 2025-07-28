// sRGB: 252, 252, 222
const vec3 blockLightColor = vec3(0.974, 0.974, 0.737);
const vec3 ambientColor = vec3(0.1);

const vec3 dayLightColor = vec3(1.0, 1.0, 1.0);
const vec3 nightLightColor = vec3(0.00, 0.01, 0.05);

const vec3 dayAmbientColor = vec3(0.15, 0.15, 0.15);
const vec3 nightAmbientColor = vec3(0.05, 0.05, 0.05);

vec3 screenToView(vec2 texcoord, float depth) {
	vec3 ndcPos = vec3(texcoord, depth) * 2.0 - 1.0;
	return txProjective(gbufferProjectionInverse, ndcPos);
}

vec3 shadowViewToScreen(vec3 shadowViewPos) {
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
	shadowClipPos.z -= 0.001; // shadow bias
	shadowClipPos.xyz = distortShadowClipPos(shadowClipPos.xyz);
	vec3 shadowNdcPos = shadowClipPos.xyz / shadowClipPos.w;
	vec3 shadowScreenPos = shadowNdcPos * 0.5 + 0.5;
	return shadowScreenPos;
}
// notes from vanilla lighting implementation
// sunrise: 22800 to 1000
// sunset: 11300 to 13200
// -> night: sun is ~10 degrees below horizon (theta = 100)
// -> day: sun is ~25 degrees above horizon (theta = 75)

// 1 - (x - 1)^2
float easeOutStep(float x) {
	float xm1 = x - 1;
	return 1 - xm1 * xm1;
}

vec3 combineSunMoon(float cosSunToUp, vec3 day, vec3 night) {
	// cos(75)  ~  0.258819
	// cos(100) ~ -0.173648
	const float DAY_THRESH = 0.258819;
	const float NIGHT_THRESH = -0.173648;

	float scaleDayLinear = clamp(cosSunToUp / DAY_THRESH, 0.0, 1.0);
	float scaleNightLinear = clamp(cosSunToUp / NIGHT_THRESH, 0.0, 1.0);

	return day * easeOutStep(scaleDayLinear) + night * easeOutStep(scaleNightLinear);
}