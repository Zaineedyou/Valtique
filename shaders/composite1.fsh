#version 330 compatibility

#define HALATION_ENABLED // Enables low-resolution warm halation.
#define HALATION_THRESHOLD 0.7 // [0.4 0.55 0.7 0.85 1.0]
//#define POTATO_MODE

#define GODRAYS_ENABLED
#define GODRAYS_STRENGTH 0.50 // [0.0 0.15 0.25 0.35 0.50 0.70]

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform vec3 sunPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

const float shadowMapBias = 0.90;

in vec2 texcoord;

/* RENDERTARGETS: 1 */
layout(location = 0) out vec4 outColor1;

vec3 viewToShadow(vec3 viewPos) {
    vec4 playerPos = gbufferModelViewInverse * vec4(viewPos, 1.0);
    vec4 shadowClip = shadowProjection * shadowModelView * playerPos;
    vec3 shadowPos = shadowClip.xyz / shadowClip.w;
    float distort = length(shadowPos.xy) * shadowMapBias + (1.0 - shadowMapBias);
    shadowPos.xy /= distort;
    shadowPos.z *= 0.2;
    return shadowPos * 0.5 + 0.5;
}

float terrainLightVisibility(vec3 viewPos) {
    vec3 shadowPos = viewToShadow(viewPos);
    if (length(shadowPos.xy * 2.0 - 1.0) >= 1.0 || shadowPos.z <= 0.0 || shadowPos.z >= 1.0) return 1.0;

    float mapDepth = texture(shadowtex0, shadowPos.xy).r;
    return clamp((mapDepth - shadowPos.z) * 65536.0, 0.0, 1.0);
}

float godrayOcclusion(vec2 uv) {
#ifdef GODRAYS_ENABLED
#ifndef POTATO_MODE
    float depth = texture(depthtex0, uv).r;
    vec4 viewPosition4 = gbufferProjectionInverse * vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec3 viewPos = viewPosition4.xyz / viewPosition4.w;
    vec3 viewDir = normalize(viewPos);
    float rayLength = min(length(viewPos), 72.0);

    // Three terrain-shadow samples are enough at half resolution and cannot make radial silhouette copies.
    float light0 = terrainLightVisibility(viewDir * (rayLength * 0.18));
    float light1 = terrainLightVisibility(viewDir * (rayLength * 0.42));
    float light2 = terrainLightVisibility(viewDir * (rayLength * 0.74));
    float terrainLit = light0 * 0.50 + light1 * 0.30 + light2 * 0.20;

    // Global ambient scattering remains visible off-screen; looking toward the sun only boosts it.
    float sunFacing = pow(max(dot(viewDir, normalize(sunPosition)), 0.0), 2.0);
    float skyFactor = smoothstep(0.995, 1.0, depth);
    return terrainLit * mix(0.16, 1.0, sunFacing) * mix(0.72, 1.0, skyFactor);
#else
    return 0.0;
#endif
#else
    return 0.0;
#endif
}

void main() {
    vec3 color = texture(colortex0, texcoord).rgb;
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    vec3 halation = vec3(0.0);

#ifdef HALATION_ENABLED
    halation = color * smoothstep(HALATION_THRESHOLD, 1.0, luminance);
#endif

    float godrays = godrayOcclusion(texcoord) * GODRAYS_STRENGTH;

    outColor1 = vec4(halation, godrays);
}
