#ifndef SKY_OVERWORLD_GLSL_INCLUDED
  #define SKY_OVERWORLD_GLSL_INCLUDED

  #include "/lib/math/easing.glsl"
  #include "/lib/math/misc.glsl"

// Function computing the skybox semi-programmatically.
vec3 computeSkybox(vec3 viewDir) {
  const float midToUpLowEdge  = 8.7155742e-2;  // ~5 degrees over the horizon
  const float midToUpHighEdge = 1.7364818e-1;  // ~10 degrees over the horizon

  vec3 sunDir = sunPosition * 0.01;
  float sDotU = dot(sunDir, gbufferModelView[1].xyz);
  float vDotU = dot(viewDir, gbufferModelView[1].xyz);

  float midToUpFactor = smoothstep(midToUpLowEdge, midToUpHighEdge, vDotU);

  vec3 dayUpColor  = skyColor * 1.5;
  vec3 dayMidColor = mix(skyColor, vec3(1.0), 0.4) * 1.5;

  vec3 horizUpColor  = skyColor;
  vec3 horizMidColor = mix(skyColor, vec3(0.5), 0.2);

  vec3 nightUpColor  = vec3(0.0);
  vec3 nightMidColor = skyColor * 0.1;

  // vec3 upColor = mix(nightUpColor, dayUpColor, sunFactor);
  // vec3 midColor = mix(nightMidColor, dayMidColor, sunFactor);

  // 3-point interpolation
  vec3 upColor = mix(
    mix(
      nightUpColor, 
      horizUpColor, 
      linearStep(-1.0, 0.0, sDotU)
    ), 
    dayUpColor,
    linearStep(0.0, 1.0, sDotU)
  );
  vec3 midColor = mix(
    mix(
      nightMidColor, 
      horizMidColor, 
      linearStep(-1.0, 0.0, sDotU)
    ), 
    dayMidColor,
    linearStep(0.0, 1.0, sDotU)
  );

  return mix(midColor, upColor, midToUpFactor);
}

#endif