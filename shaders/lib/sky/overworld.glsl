#ifndef SKY_OVERWORLD_GLSL_INCLUDED
  #define SKY_OVERWORLD_GLSL_INCLUDED

  #include "/lib/common.glsl"
  #include "/lib/math/easing.glsl"

// Function computing the skybox given a direction in view-space.
vec3 computeSkybox(vec3 viewDir) {
  const float midToUpLowEdge  = 8.7155742e-2;  // ~5 degrees over the horizon
  const float midToUpHighEdge = 1.7364818e-1;  // ~10 degrees over the horizon

  const float twilightLowEdge = -1.7364818e-1;  // ~10 degrees under the horizon
  const float twilightHighEdge = 3.4202014e-1;  // ~25 degrees over the horizon

  const float twilightNearEdge = 4.3619387e-2;   // ~2.5 degrees from the equator
  const float twilightFarEdge  = -4.3619387e-2;  // ~2.5 degrees from the equator

  vec3 sunDir = sunPosition * 0.01;
  float sDotU = dot(sunDir, gbufferModelView[1].xyz);
  float sDotE = dot(sunDir, gbufferModelView[0].xyz);
  float vDotU = dot(viewDir, gbufferModelView[1].xyz);

  float rainFactor    = pow2(rainStrength);
  float midToUpFactor = smoothstep(midToUpLowEdge, midToUpHighEdge, vDotU);

  // TWILIGHT GRADIENT
  // ====================================================

  float twilightFactor  = linearStep(twilightLowEdge, twilightHighEdge, sDotU);
  float twilightDirSign = signNonzero(sDotE);

  float twilightTheta = easeTempQuadratic(twilightFactor) * radians(10);
  vec3 twilightDir =
    mat3(gbufferModelView) * vec3(sin(twilightTheta) * twilightDirSign, -cos(twilightTheta), 0.0);

  float twilightVisFactor = easeTempQuadratic(twilightFactor);
  float twilightAngleFactor = linearStep(twilightFarEdge, twilightNearEdge, dot(viewDir, twilightDir));
  float twilightMixFactor = twilightVisFactor * twilightAngleFactor;

  const vec3 twilightBeginColor = vec3(0.976, 0.494, 0.447);
  const vec3 twilightEndColor   = vec3(0.976, 0.870, 0.447);
  vec3 twilightColor =
    mix(twilightBeginColor, twilightEndColor, twilightFactor);

  // CLEAR CURVE
  // ====================================================

  vec3 dayClearUpColor  = skyColor * 1.5;
  vec3 dayClearMidColor = mix(skyColor, vec3(1.0), 0.2) * 1.5;

  vec3 horizClearUpColor  = skyColor;
  vec3 horizClearMidColor = mix(skyColor, vec3(0.5), 0.2);

  vec3 nightClearUpColor  = vec3(0.0);
  vec3 nightClearMidColor = skyColor * 0.1;

  // RAIN CURVE
  // ====================================================

  vec3 dayRainUpColor  = mix(skyColor, vec3(1.0), 0.2);
  vec3 dayRainMidColor = skyColor * 1.2;

  vec3 horizRainUpColor  = mix(skyColor, vec3(0.5), 0.2);
  vec3 horizRainMidColor = skyColor * 1.1;

  vec3 nightRainUpColor  = vec3(0.0);
  vec3 nightRainMidColor = skyColor * 0.1;

  // COMBINED CURVE
  // ====================================================

  vec3 dayUpColor  = mix(dayClearUpColor, dayRainUpColor, rainFactor);
  vec3 dayMidColor = mix(dayClearMidColor, dayRainMidColor, rainFactor);

  vec3 horizUpColor  = mix(horizClearUpColor, horizRainUpColor, rainFactor);
  vec3 horizMidColor = mix(horizClearMidColor, horizRainMidColor, rainFactor);

  vec3 nightUpColor  = mix(nightClearUpColor, nightRainUpColor, rainFactor);
  vec3 nightMidColor = mix(nightClearMidColor, nightRainMidColor, rainFactor);

  // vec3 upColor = mix(nightUpColor, dayUpColor, sunFactor);
  // vec3 midColor = mix(nightMidColor, dayMidColor, sunFactor);

  // 3-point interpolation
  vec3 upColor = mix(
    mix(nightUpColor, horizUpColor, linearStep(-1.0, 0.0, sDotU)), dayUpColor,
    linearStep(0.0, 1.0, sDotU));
  vec3 midColor = mix(
    mix(nightMidColor, horizMidColor, linearStep(-1.0, 0.0, sDotU)),
    dayMidColor, linearStep(0.0, 1.0, sDotU));

  vec3 baseSkyColor = mix(midColor, upColor, midToUpFactor);

  return mix(baseSkyColor, twilightColor, twilightMixFactor);
}

#endif