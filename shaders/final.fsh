#version 330 compatibility

#define HALATION_ENABLED
#define HALATION_STRENGTH 0.35 // [0.0 0.15 0.25 0.35 0.5 0.7]
#define HALATION_RADIUS 1.0 // [0.5 0.75 1.0 1.5 2.0]
#define HALATION_WARMTH 0.65 // [0.0 0.35 0.65 0.85 1.0]

#define PERSISTENCE_ENABLED
#define PERSISTENCE_STRENGTH 0.14 // [0.0 0.06 0.14 0.22 0.35]
#define POTATO_MODE

//#define OUTLINE_ENABLED
//#define OUTLINE_SCALED
#define OUTLINE_THICKNESS 1.0 // [1.0 2.0 3.0 4.0]
#define OUTLINE_INTENSITY 1.5 // [0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.5 3.0 3.5 4.0]

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform sampler2D noisetex;
uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;
uniform float near;
uniform float far;
uniform int frameCounter;
uniform mat4 gbufferProjection;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

vec3 sampleHalation(vec2 uv) {
    vec2 pixel = 2.0 / vec2(viewWidth, viewHeight) * HALATION_RADIUS;
#ifdef POTATO_MODE
    return texture(colortex1, uv).rgb;
#else
    vec3 sum = texture(colortex1, uv + vec2(-pixel.x, -pixel.y)).rgb;
    sum += texture(colortex1, uv + vec2( pixel.x, -pixel.y)).rgb;
    sum += texture(colortex1, uv + vec2(-pixel.x,  pixel.y)).rgb;
    sum += texture(colortex1, uv + vec2( pixel.x,  pixel.y)).rgb;
    return sum * 0.25;
#endif
}

float GetLinearDepth(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

void applyWorldOutline(inout vec3 color, vec2 texCoord, float linearZ0) {
#ifndef OUTLINE_SCALED
    vec2 scale = vec2(1.0 / viewWidth, 1.0 / viewHeight);
#else
    float dither = texture2DLod(noisetex, texCoord * vec2(viewWidth, viewHeight) / 128.0, 0.0).b;
    dither = fract(dither + 1.61803398875 * mod(float(frameCounter), 3600.0));
    float fovScale = gbufferProjection[1][1];
    float distScale = max((far - near) * linearZ0 + near, 3.0);
    vec2 scale = vec2(0.005 / aspectRatio, 0.005) * fovScale / distScale;
    scale *= 0.99 + 0.2 * dither;
#endif

    vec2 direction = sign(texCoord - vec2(0.5));
    vec2 checkCoord = texCoord + scale * direction * OUTLINE_THICKNESS;
    float outlineMult = max(0.0, 0.5 - max(abs(checkCoord.x - 0.5), abs(checkCoord.y - 0.5)));
    outlineMult = min(1.0, outlineMult * 0.1 / (scale.x * OUTLINE_THICKNESS));
    if (outlineMult < 0.0001) return;

    float r0 = 1.0 / GetLinearDepth(texture(depthtex0, texCoord + vec2(-OUTLINE_THICKNESS, -OUTLINE_THICKNESS) * scale).r);
    float r1 = 1.0 / GetLinearDepth(texture(depthtex0, texCoord + vec2(-OUTLINE_THICKNESS,  OUTLINE_THICKNESS) * scale).r);
    float r2 = 1.0 / GetLinearDepth(texture(depthtex0, texCoord + vec2( OUTLINE_THICKNESS, -OUTLINE_THICKNESS) * scale).r);
    float r3 = 1.0 / GetLinearDepth(texture(depthtex0, texCoord + vec2( OUTLINE_THICKNESS,  OUTLINE_THICKNESS) * scale).r);
    float slope = (1.0 / linearZ0 - 0.25 * (r0 + r1 + r2 + r3)) * (linearZ0 * linearZ0);
    float outline = clamp(slope / (linearZ0 * OUTLINE_THICKNESS / 2000.0), 0.0, 1.0) * OUTLINE_INTENSITY;
    color += min(color * outline * outlineMult * 0.25, vec3(outline * outlineMult * 0.25));
}

void main() {
    vec2 uv = texcoord;
    vec3 color = texture(colortex0, uv).rgb;

#ifdef HALATION_ENABLED
    vec3 warmTint = mix(vec3(1.0), vec3(1.0, 0.42, 0.18), HALATION_WARMTH);
    color += sampleHalation(uv) * warmTint * HALATION_STRENGTH;
#endif

#ifdef PERSISTENCE_ENABLED
    color += texture(colortex2, uv).rgb * PERSISTENCE_STRENGTH;
#endif

#ifdef OUTLINE_ENABLED
    applyWorldOutline(color, uv, GetLinearDepth(texture(depthtex0, uv).r));
#endif

    outColor0 = vec4(color, 1.0);
}
