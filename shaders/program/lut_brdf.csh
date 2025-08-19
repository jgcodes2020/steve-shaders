#version 460 compatibility

#define LOOKUP_COMPUTE_SHADER
#include "/lib/common.glsl"
#include "/lib/buffers.glsl"

#include "/lib/math/integral.glsl"
#include "/lib/lighting/brdf.glsl"

layout (local_size_x = 16, local_size_y = 16) in;
const ivec3 workGroups = ivec3(32, 32, 1);

vec2 evalPixel(vec2 screenCoords) {
  float nDotV = screenCoords.x;
  float spAlpha = screenCoords.y;

  // select a view vector to fit nDotV
  vec3 viewDir = vec3(sqrt(1.0 - pow2(nDotV)), 0.0, nDotV);

  // This will accumulate our samples
  vec2 accum = vec2(0.0);

  const uint SAMPLE_COUNT = 1024u;
  for (uint i = 0u; i < SAMPLE_COUNT; i++) {
    // sample a halfway direction using our importance sampler
    vec2 rand = hammersley2D(i, SAMPLE_COUNT);
    vec3 halfDir = importanceSample(rand, spAlpha);

    // reflect viewDir about halfDir to get lightDir
    // reflect(u, v) = 2 * proj(v to u) - u
    //               = 2 * (u dot v) * v - u
    float vDotH = dot(viewDir, halfDir);
    vec3 lightDir = 2.0 * vDotH * halfDir - viewDir;

    // since our normal is implicitly along the z-axis, n dot x is just the z component
    float nDotL = max(lightDir.z, 0.0);
    float nDotH = max(halfDir.z, 0.0);
    vDotH = max(vDotH, 0.0);

    if (nDotL > 0.0) {
      // The Fresnel coefficient is separated as part of the derivation
      // of the split-sum integral, the distribution is accounted for in sampling,
      // so that leaves the geometry term.
      float g = brdfGeometryIBL(nDotL, nDotV, spAlpha);
      float gTerm = (g * vDotH) / (nDotH * nDotV);

      // Fresnel coefficient.
      float fc = pow5(1.0 - vDotH);

      // Split-sum terms.
      accum += vec2(1.0 - fc, fc) * gTerm;
    }

    // Divide by the number of samples for our average.
    return accum / float(SAMPLE_COUNT);
  }
}

void main() {
  ivec2 pixelCoords = ivec2(gl_GlobalInvocationID.xy);
  vec2 screenCoords = vec2(pixelCoords) / 512.0;

  vec2 lutValue = evalPixel(screenCoords);

  imageStore(img_brdfLut, pixelCoords, vec4(lutValue, 0.0, 0.0));
}