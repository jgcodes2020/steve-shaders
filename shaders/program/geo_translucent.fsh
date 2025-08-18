#version 460 compatibility

#include "/lib/common.glsl"
#include "/lib/buffers.glsl"

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
  // correct gamma; then premultiply alpha
  bColor.rgb = pow(bColor.rgb, vec3(SRGB_GAMMA));
  bColor.rgb *= bColor.a;

  vec4 texSpecular = texture(specular, v.uvTex);
  vec4 texNormal = texture(normals, v.uvTex);
  
  FragInfo i = fragInfoFromTextures(texSpecular, texNormal, v.light, 1.0, v.tbnMatrix);

  if (!i.emissive) {
    vec2 screenCoords = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
    float depth = gl_FragCoord.z;

    // compute NDC; accounting for the hand being shifted during projection
    vec3 ndcPos = fma(vec3(screenCoords, depth), vec3(2.0), vec3(-1.0));
    if (i.hand) {
      ndcPos.z /= MC_HAND_DEPTH;
    }

    // derive other coordinates from NDC position
    vec3 viewPos = txProjective(gbufferProjectionInverse, ndcPos);
    vec3 feetPos = txAffine(gbufferModelViewInverse, viewPos);
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
}