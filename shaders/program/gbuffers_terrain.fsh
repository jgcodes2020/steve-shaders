uniform sampler2D lightmap;
uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec4 glcolor;
in vec2 texcoord;
in vec2 vtlight;
in vec3 normal;

flat in int blockId;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightInfo;
layout(location = 2) out vec4 normInfo;

#include "/lib/common.glsl"
#include "/lib/props/block.glsl"

void main() {
  color = texture(gtexture, texcoord) * glcolor;

  if (color.a < alphaTestRef) {
    discard;
  }

  lightInfo = vec4(vtlight, 0.0, 1.0);

  vec3 shiftedNormal = normal;
  if (isPlant(blockId)) {
    shiftedNormal = normalize(normal + vec3(0.0, 0.5, 0.0));
  }
  normInfo  = normalToColor(shiftedNormal);

}