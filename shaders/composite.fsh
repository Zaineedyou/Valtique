#version 330 compatibility

/* CINEMATIC OLD FILM SHADER - composite pass 1/3
   Pass ini mengerjakan semua efek KECUALI bloom & outline. Bloom & outline
   diproses di composite1.fsh (isi buffer lowres) dan composite2.fsh
   (terapkan efeknya) — dipisah 3 pass karena Iris mensyaratkan satu
   program cuma bisa menulis ke buffer-buffer berukuran identik.
*/

#define LETTERBOX_SIZE 0.11 // [0.06 0.08 0.11 0.14 0.17]
#define GRAIN_STRENGTH 0.05 // [0.0 0.02 0.05 0.08 0.12]
#define DISTORT_STRENGTH 1.2 // [0.0 0.6 1.2 1.8 2.4]
#define SEPIA_STRENGTH 0.45 // [0.0 0.25 0.45 0.65 0.85]
#define SCRATCH_STRENGTH 0.45 // [0.0 0.25 0.45 0.6 0.8]
#define DUST_STRENGTH 0.45 // [0.0 0.25 0.45 0.6 0.8]
#define CRT_STRENGTH 0.15 // [0.0 0.05 0.15 0.25 0.4]
#define BORDER_FOG_STRENGTH 0.0 // [0.0 0.5 1.0 1.5 2.0 3.0 5.0]

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

// --- Pseudo-random noise ---
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

// --- Border fog buatan sendiri, pola dari shaderpack referensi (Tricked).
// Default 0.0 = TIDAK ADA border fog sama sekali. ---
float getBorderFogFactor(float dist01) {
    if (BORDER_FOG_STRENGTH <= 0.0001) return 0.0;
    float s = dist01;
    s *= s; s *= s; s *= s;
    return 1.0 - min(1.0, (1.0 - smoothstep(0.9, 1.5, s)) * exp(-3.0 * BORDER_FOG_STRENGTH * s));
}

// --- Linearisasi depth ---
float linearizeDepth(float depth) {
    float z = depth * 2.0 - 1.0;
    return (2.0 * near * far) / (far + near - z * (far - near));
}

// --- Gores film, lurus vertikal ---
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

// --- Bercak/dust ---
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
            float opacity = mix(1.0, 0.5, sizeBias);
            dust += smoothstep(radius, 0.0, d) * opacity;
        }
    }
    return clamp(dust, 0.0, 1.0);
}

// --- CRT dot mask ---
float crtDotMask(vec2 uv, float viewW, float viewH) {
    return sin(3.14159 * uv.x * 800.0 * viewW) * sin(3.14159 * uv.y * 800.0 * viewH);
}

void main() {
    vec2 uv = texcoord;
    vec2 pixelSize = 1.0 / vec2(viewWidth, viewHeight);

    vec2 centered = uv - 0.5;
    float dist = length(centered);

    // 1. Distorsi lensa
    vec2 distortOffset = centered * (0.15 + dist * DISTORT_STRENGTH) * pixelSize * 3.0;
    float r = texture(colortex0, uv + distortOffset).r;
    float g = texture(colortex0, uv).g;
    float b = texture(colortex0, uv - distortOffset).b;
    vec3 color = vec3(r, g, b);

    // 2b. Border fog (opsional, default mati)
    float rawDepthBF = texture(depthtex0, uv).r;
    if (rawDepthBF < 1.0 && BORDER_FOG_STRENGTH > 0.0001) {
        float linearDistBF = linearizeDepth(rawDepthBF);
        float borderFogFactor = getBorderFogFactor(clamp(linearDistBF / far, 0.0, 1.0));
        vec3 borderFogColor = vec3(0.35, 0.30, 0.22);
        color = mix(color, borderFogColor, borderFogFactor);
    }

    // 3. Sepia
    vec3 sepiaGraded = vec3(
        dot(color, vec3(0.393, 0.769, 0.189)),
        dot(color, vec3(0.349, 0.686, 0.168)),
        dot(color, vec3(0.272, 0.534, 0.131))
    );
    vec3 sepia = mix(color, sepiaGraded, 0.6);
    color = mix(color, sepia, SEPIA_STRENGTH);

    // 4. Film grain
    float grainNoise = rand(uv * vec2(viewWidth, viewHeight) + frameTimeCounter * 24.0);
    grainNoise = (grainNoise - 0.5) * 2.0;
    float edgeBoost = 1.0 + dist * 1.5;
    color += grainNoise * GRAIN_STRENGTH * edgeBoost;

    // 5. Gores + bercak film
    float scratch = filmScratches(uv, frameTimeCounter);
    color = mix(color, vec3(0.05), scratch * SCRATCH_STRENGTH);
    float dust = filmDust(uv, frameTimeCounter);
    color = mix(color, vec3(0.05), dust * DUST_STRENGTH);

    // 6. CRT dot mask
    float dotMask = crtDotMask(uv, viewWidth, viewHeight);
    color *= mix(1.0 - CRT_STRENGTH, 1.0, dotMask * 0.5 + 0.5);

    // 8. Letterbox bars
    float edgeSoftness = LETTERBOX_SIZE * 0.35;
    float topBar    = smoothstep(LETTERBOX_SIZE, LETTERBOX_SIZE - edgeSoftness, uv.y);
    float bottomBar = smoothstep(1.0 - LETTERBOX_SIZE, 1.0 - (LETTERBOX_SIZE - edgeSoftness), uv.y);
    float barMask = max(topBar, bottomBar);
    color = mix(color, vec3(0.0), barMask);

    outColor0 = vec4(color, 1.0);
}

