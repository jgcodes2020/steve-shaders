#ifndef SKY_MODEL_GLSL_INCLUDED
#define SKY_MODEL_GLSL_INCLUDED

const vec3 sunBaseColor = vec3(0.3, 0.6, 1.0);
const vec3 sunHorizonColor = vec3(1.0, 0.5, 0.2);

vec3 computeSimpleSky(vec3 viewDir, vec3 sunDir) {
  // east-west is along the x-axis, we want (sun dot x)^6
  float horizonFactor = sunDir.x * sunDir.x;
  horizonFactor *= horizonFactor * horizonFactor;

  float viewDeltaFactor = clamp(dot(viewDir, sunDir), 0.0, 1.0);
  viewDeltaFactor *= viewDeltaFactor * viewDeltaFactor;

  return mix(sunBaseColor, sunHorizonColor, horizonFactor * viewDeltaFactor);
}

#endif