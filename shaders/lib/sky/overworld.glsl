#ifndef SKY_OVERWORLD_GLSL_INCLUDED
#define SKY_OVERWORLD_GLSL_INCLUDED

// Function computing a vanilla-style skybox programmatically.
// Most of these computations should really be done CPU-side, but
// I'll get to that.
vec3 computeSkybox(vec3 viewDir) {
  const vec3 baseSkyColor = vec3(0.36, 0.57, 0.85);
  //
  const vec3 zenithDayColor = baseSkyColor * 1.75;
  const vec3 zenithNightColor = zenithDayColor * 0.05;

  const vec3 horizonDayColor = baseSkyColor * 2.0;
  const vec3 horizonNightColor = baseSkyColor * 0.1;

  const float twilightLow = -1.7364818e-1; // ~10 degrees under the horizon
  const float twilightHigh = 4.2261826e-1; // ~25 degrees over the horizon

  const float skyTransitionLow = 8.7155742e-2; // ~5 degrees over the horizon
  const float skyTransitionHigh = 1.7364818e-1; // ~10 degrees over the horizon
  
  vec3 sunDir = sunPosition * 0.01;
  float sDotU = dot(sunDir, gbufferModelView[1].xyz);
  float vDotU = dot(viewDir, gbufferModelView[1].xyz);
  
  float twilight = smoothstep(twilightLow, twilightHigh, sDotU);
  float transition = smoothstep(skyTransitionLow, skyTransitionHigh, vDotU);

  vec3 zenithColor = mix(zenithNightColor, zenithDayColor, twilight);
  vec3 horizonColor = mix(horizonNightColor, horizonDayColor, twilight);

  vec3 skyBaseColor = mix(horizonColor, zenithColor, transition);
  return skyBaseColor;
}

#endif