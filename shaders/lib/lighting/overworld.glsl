#ifndef LIGHTING_OVERWORLD_GLSL_INCLUDED
#define LIGHTING_OVERWORLD_GLSL_INCLUDED

const vec3 blockLightColor = vec3(0.974, 0.974, 0.737);
const vec3 ambientColor    = vec3(0.1);

const vec3 dayLightColor   = vec3(2.0);
const vec3 dayAmbientColor = vec3(0.2);

const vec3 nightLightColor   = vec3(0.06, 0.08, 0.2);
const vec3 nightAmbientColor = vec3(0.02);

const vec3 nightVisionAmbientColor = vec3(0.5, 0.5, 0.5);

// Angle cosines relative to the horizon where full
// brightness should be achieved.
// sin(25)  ~  0.258819
// sin(-10) ~ -0.173648
const float daySatAngle   = 0.258819;
const float nightSatAngle = -0.173648;


// Quadratic ease out between 0 and satPoint.
float ltOverworld_horizonStep(float cosSunToUp, float satPoint) {
  float x = clamp(cosSunToUp / satPoint, 0.0, 1.0);
  // quadratic ease-out
  float xm1 = x - 1.0;
  return 1.0 - xm1 * xm1;
}

// Computation of sky colors for a given angle.
void ltOverworld_skyColors(out vec3 skyAmbientColor, out vec3 skyLightColor) {
  // dot against y-direction in world space, translated to view space
  float cosSunToUp  = dot(normalize(sunPosition), gbufferModelView[1].xyz);
  float dayFactor   = ltOverworld_horizonStep(cosSunToUp, daySatAngle);
  float nightFactor = ltOverworld_horizonStep(cosSunToUp, nightSatAngle);

  skyLightColor = dayFactor * dayLightColor + nightFactor * nightLightColor;
  skyAmbientColor = mix(nightAmbientColor, dayAmbientColor, smoothstep(nightSatAngle, daySatAngle, cosSunToUp));
  skyAmbientColor = mix(skyAmbientColor, nightVisionAmbientColor, nightVision);
}

#endif