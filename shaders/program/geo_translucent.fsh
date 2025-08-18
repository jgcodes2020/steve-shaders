#version 460 compatibility

#include "/lib/common.glsl"
#include "/lib/buffers.glsl"

#include "/lib/lighting/model.glsl"
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
  bColor.rgb = pow(bColor.rgb, vec3(SRGB_GAMMA));

  // premultiply alpha
  bColor.rgb *= bColor.a;

  vec4 texSpecular = texture(specular, v.uvTex);
  vec4 texNormal = texture(normals, v.uvTex);
  
  FragInfo i = fragInfoFromTextures(texSpecular, texNormal, v.light, 1.0, v.tbnMatrix);

  if (!i.emissive) {
    vec2 screenCoords = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
    float depth = gl_FragCoord.z;

    vec3 ndcPos = fma(vec3(screenCoords, depth), vec3(2.0), vec3(-1.0));
    vec3 viewPos = txProjective(gbufferProjectionInverse, ndcPos);
    vec3 viewDir = -normalize(mat3(gbufferModelViewInverse) * viewPos);

    vec3 ambientLight, skyLight;
    ltOverworld_skyColors(ambientLight, skyLight);

    bColor = pbrLightingTranslucent(bColor, i, viewDir, ambientLight, skyLight, blockLightColor);
  }
}