#version 410 compatibility

#define GBUFFERS_USE_TEXTURE
#define GBUFFERS_PASS_LIGHT
#define GBUFFERS_PASS_NORMAL
#define GBUFFERS_LIGHT_FLAGS LTG_NO_SHADOW
#include "/program/gbuffers_deferred.fsh"