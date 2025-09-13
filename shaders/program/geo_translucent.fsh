#version 460 compatibility

#include "/lib/common.glsl"
#include "/lib/buffers.glsl"

#include "/lib/math/easing.glsl"

#include "/lib/lighting/model.glsl"
#include "/lib/lighting/shadow.glsl"
#include "/lib/lighting/overworld.glsl"

uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;

in VertexData {
  vec4 color;
  vec2 uvTex;
  vec2 light;

  flat mat3 tbnMatrix;
}
v;

// naming scheme: bThing = buffer for thing
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 bColor;

void main() {
  bColor = texture(gtexture, v.uvTex) * v.color;
#ifdef ALPHA_TEST
  if (bColor.a < alphaTestRef)
    discard;
#endif
  // correct to linear premultiplied color
  bColor.rgb *= bColor.a;
  bColor.rgb = pow(bColor.rgb, vec3(SRGB_GAMMA));

  vec4 texSpecular = texture(specular, v.uvTex);
  vec4 texNormal = texture(normals, v.uvTex);
  
  FragInfo i = fragInfoFromTextures(texSpecular, texNormal, v.light, 1.0, v.tbnMatrix);

  vec2 screenCoords = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
  float depth = gl_FragCoord.z;

  // compute NDC; accounting for the hand being shifted during projection
  vec3 ndcPos = fma(vec3(screenCoords, depth), vec3(2.0), vec3(-1.0));
  if (i.hand) {
    const float invHandDepth = 1.0 / MC_HAND_DEPTH;
    ndcPos.z *= invHandDepth;
  }

  // derive other coordinates from NDC position
  vec3 viewPos = txInvProj(gbufferProjectionInverse, ndcPos);
  vec3 eyePos = mat3(gbufferModelViewInverse) * viewPos;

  // lighting
  if (!i.emissive) {
    // derive shadow space position
    vec3 feetPos = eyePos + gbufferModelViewInverse[3].xyz;
    vec3 shadowViewPos = txAffine(shadowModelView, feetPos);

    // direction from pixel to camera.
    vec3 viewDir = -normalize(mat3(gbufferModelViewInverse) * viewPos);

    // shadow clip-space position of this pixel.
    vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
    vec3 shadow = computeShadowSoft(shadowClipPos, i.normal, ivec2(gl_FragCoord.xy));

    vec3 ambientLight, skyLight;
    ltOverworld_skyColors(ambientLight, skyLight);

    bColor = pbrLightingTranslucent(bColor, i, viewDir, shadow, ambientLight, skyLight, blockLightColor);
  }

  // distance fog
  #ifdef CLOUDS
  float distFogFactor = linearStep(2048.0, 0.0, length(eyePos.xy));
  bColor *= distFogFactor;
  #else
  float distFogFactor = linearStep(far, far * 0.9, length(viewPos));
  bColor *= distFogFactor;
  #endif

}