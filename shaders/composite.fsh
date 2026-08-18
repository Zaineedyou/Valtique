#version 330 compatibility

#define LETTERBOX_SIZE 0.08 // [0.06 0.08 0.11 0.14 0.17]
#define GRAIN_STRENGTH 0.02 // [0.0 0.02 0.05 0.08 0.12]
#define DISTORT_STRENGTH 0.6 // [0.0 0.6 1.2 1.8 2.4]
#define BARREL_DISTORTION 0.08 // [0.0 0.02 0.05 0.08 0.12 0.15]
#define CRT_DESATURATION 0.15 // [0.0 0.15 0.35 0.5 0.65 0.8]
#define CRT_CONTRAST 1.1 // [1.0 1.05 1.1 1.15 1.2 1.3]
#define CRT_STRENGTH 0.15 // [0.0 0.05 0.15 0.25 0.4]
#define SCANLINE_SPEED 0.1 // [0.0 0.1 0.25 0.5 0.8]
#define CONVERGENCE_STRENGTH 0.3 // [0.0 0.3 0.6 1.0 1.5]
#define SCRATCH_STRENGTH 0.0 // [0.0 0.25 0.45 0.6 0.8]
#define DUST_STRENGTH 0.0 // [0.0 0.25 0.45 0.6 0.8]
#define BORDER_FOG_STRENGTH 0.0 // [0.0 0.5 1.0 1.5 2.0 3.0 5.0]

#define VHS_ENABLED
#define VHS_JITTER 0.3 // [0.0 0.3 0.6 1.0 1.5]
#define VHS_NOISE 0.06 // [0.0 0.06 0.12 0.2 0.3]
#define VHS_TRACKING_RATE 0.08 // [0.0 0.08 0.15 0.3 0.5]
#define POTATO_MODE

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;
uniform float near;
uniform float far;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float getBorderFogFactor(float dist01) {
    float s = dist01;
    s *= s; s *= s; s *= s;
    return 1.0 - min(1.0, (1.0 - smoothstep(0.9, 1.5, s)) * exp(-3.0 * BORDER_FOG_STRENGTH * s));
}

float linearizeDepth(float depth) {
    float z = depth * 2.0 - 1.0;
    return (2.0 * near * far) / (far + near - z * (far - near));
}

float filmScratches(vec2 uv, float time) {
    float scratch = 0.0;
    for (int i = 0; i < 6; i++) {
        float seed = float(i) * 17.0;
        float slot = floor(time * 1.2 + seed);
        float scratchX = rand(vec2(slot, seed));
        float scratchLife = rand(vec2(slot, seed + 5.0));
        if (scratchLife < 0.65) {
            float dist = abs(uv.x - scratchX);
            float width = 0.0012 + rand(vec2(slot, seed + 9.0)) * 0.0035;
            float scratchCenterY = rand(vec2(slot, seed + 17.0));
            float scratchLength = 0.15 + rand(vec2(slot, seed + 15.0)) * 0.5;
            float lengthMask = 1.0 - smoothstep(scratchLength * 0.5, scratchLength * 0.5 + 0.05, abs(uv.y - scratchCenterY));
            scratch += smoothstep(width, 0.0, dist) * lengthMask;
        }
    }
    return clamp(scratch, 0.0, 1.0);
}

float filmDust(vec2 uv, float time) {
    float dust = 0.0;
    for (int i = 0; i < 10; i++) {
        float seed = float(i) * 31.0;
        float slot = floor(time * 0.8 + seed);
        vec2 spotPos = vec2(rand(vec2(slot, seed)), rand(vec2(slot, seed + 3.0)));
        float spotLife = rand(vec2(slot, seed + 7.0));
        if (spotLife < 0.6) {
            float d = length(uv - spotPos);
            float sizeBias = rand(vec2(slot, seed + 11.0));
            float radius = 0.0015 + sizeBias * sizeBias * 0.008;
            dust += smoothstep(radius, 0.0, d) * mix(1.0, 0.5, sizeBias);
        }
    }
    return clamp(dust, 0.0, 1.0);
}

float scanlineMask() {
    float field = fract(gl_FragCoord.y * 0.5 + frameTimeCounter * SCANLINE_SPEED);
    return abs(field * 2.0 - 1.0);
}

void main() {
    vec2 uv = texcoord;

#ifdef VHS_ENABLED
    float vhsFrame = floor(frameTimeCounter * 20.0);
    float vhsLine = floor(uv.y * viewHeight * 0.125);
    float jitter = (rand(vec2(vhsLine, vhsFrame)) - 0.5) * VHS_JITTER * 4.0 / viewWidth;
    float headBand = smoothstep(0.92, 1.0, uv.y);
    uv.x += jitter * (1.0 + headBand * 4.0);
#ifndef POTATO_MODE
    float holdSlot = floor(frameTimeCounter * max(VHS_TRACKING_RATE, 0.001));
    if (VHS_TRACKING_RATE > 0.0 && rand(vec2(holdSlot, 91.0)) > 0.992) {
        float slipBand = smoothstep(0.30, 0.42, uv.y) * (1.0 - smoothstep(0.42, 0.54, uv.y));
        uv.y = fract(uv.y + slipBand * 0.035);
    }
#endif
#endif

    if (BARREL_DISTORTION > 0.0001) {
        vec2 signedUv = uv * 2.0 - 1.0;
        signedUv *= 1.0 + (dot(signedUv, signedUv) - 1.0) * BARREL_DISTORTION;
        uv = signedUv * 0.5 + 0.5;
    }

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        outColor0 = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    float edgeSoftness = LETTERBOX_SIZE * 0.35;
    float opaqueBarEnd = LETTERBOX_SIZE - edgeSoftness;
    if (uv.y <= opaqueBarEnd || uv.y >= 1.0 - opaqueBarEnd) {
        outColor0 = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    vec2 centered = uv - 0.5;
    float dist = length(centered);
    vec2 pixelSize = 1.0 / vec2(viewWidth, viewHeight);
    vec2 lensOffset = vec2(0.0);
    if (DISTORT_STRENGTH > 0.0001) {
        lensOffset = centered * (0.15 + dist * DISTORT_STRENGTH) * pixelSize * 3.0;
    }
    vec3 color;
    if (DISTORT_STRENGTH > 0.0001 || CONVERGENCE_STRENGTH > 0.0001) {
        vec2 convergenceOffset = centered * (dist * dist) * pixelSize * CONVERGENCE_STRENGTH;
        color = vec3(
            texture(colortex0, uv + lensOffset + convergenceOffset).r,
            texture(colortex0, uv).g,
            texture(colortex0, uv - lensOffset - convergenceOffset).b
        );
    } else {
        color = texture(colortex0, uv).rgb;
    }

    if (BORDER_FOG_STRENGTH > 0.0001) {
        float rawDepth = texture(depthtex0, uv).r;
        if (rawDepth < 1.0) {
            color = mix(color, vec3(0.35, 0.30, 0.22), getBorderFogFactor(clamp(linearizeDepth(rawDepth) / far, 0.0, 1.0)));
        }
    }

    if (CRT_DESATURATION > 0.0001) {
        color = mix(color, vec3(dot(color, vec3(0.299, 0.587, 0.114))), CRT_DESATURATION);
    }
    if (abs(CRT_CONTRAST - 1.0) > 0.0001) {
        color = (color - 0.5) * CRT_CONTRAST + 0.5;
    }
    color *= vec3(0.95, 0.98, 1.05);

#ifdef VHS_ENABLED
    if (VHS_NOISE > 0.0001) {
        float signalNoise = rand(vec2(floor(uv.y * viewHeight * 0.25), vhsFrame)) - 0.5;
        color += signalNoise * VHS_NOISE;
#ifndef POTATO_MODE
        float dropout = step(0.9975, rand(vec2(floor(uv.y * viewHeight * 0.08), floor(frameTimeCounter * 12.0))));
        color = mix(color, vec3(dot(color, vec3(0.299, 0.587, 0.114))), dropout * VHS_NOISE);
#endif
    }
#endif

    if (GRAIN_STRENGTH > 0.0001) {
        float grainNoise = rand(uv * vec2(viewWidth, viewHeight) + frameTimeCounter * 24.0);
        color += (grainNoise - 0.5) * 2.0 * GRAIN_STRENGTH * (1.0 + dist * 1.5);
    }
#ifndef POTATO_MODE
    if (SCRATCH_STRENGTH > 0.0001) {
        color = mix(color, vec3(0.05), filmScratches(uv, frameTimeCounter) * SCRATCH_STRENGTH);
    }
    if (DUST_STRENGTH > 0.0001) {
        color = mix(color, vec3(0.05), filmDust(uv, frameTimeCounter) * DUST_STRENGTH);
    }
#endif
    if (CRT_STRENGTH > 0.0001) {
        color *= 1.0 - CRT_STRENGTH * (1.0 - scanlineMask());
    }

    float topBar = 1.0 - smoothstep(opaqueBarEnd, LETTERBOX_SIZE, uv.y);
    float bottomBar = smoothstep(1.0 - LETTERBOX_SIZE, 1.0 - opaqueBarEnd, uv.y);
    outColor0 = vec4(mix(color, vec3(0.0), max(topBar, bottomBar)), 1.0);
}
