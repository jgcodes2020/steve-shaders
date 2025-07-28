#ifndef LIGHTING_GLSL_INCLUDED
#define LIGHTING_GLSL_INCLUDED

// sRGB: 252, 252, 222
const vec3 blockLightColor = vec3(0.974, 0.974, 0.737);
const vec3 ambientColor = vec3(0.1);

const vec3 dayLightColor = vec3(1.0, 1.0, 1.0);
const vec3 nightLightColor = vec3(0.00, 0.01, 0.05);

const vec3 dayAmbientColor = vec3(0.15, 0.15, 0.15);
const vec3 nightAmbientColor = vec3(0.05, 0.05, 0.05);

// Angle cosines relative to the horizon where full
// brightness should be achieved.
// sin(25)  ~  0.258819
// sin(-10) ~ -0.173648
const float daySatAngle = 0.258819;
const float nightSatAngle = -0.173648;

// notes from vanilla lighting implementation
// sunrise: 22800 to 1000
// sunset: 11300 to 13200
// -> night: sun is ~10 degrees below horizon (theta = 100)
// -> day: sun is ~25 degrees above horizon (theta = 75)

// Ease-out transition between 0 and the saturation point.
float horizonStep(float cosSunToUp, float satPoint) {
	float x = clamp(cosSunToUp / satPoint, 0.0, 1.0);
	// quadratic ease-out
	float xm1 = x - 1.0;
	return 1.0 - xm1 * xm1;

}

#endif