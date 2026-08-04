#version 330 compatibility

/* CINEMATIC OLD FILM SHADER - composite pass 3/3
   Bloom: diproses di colortex1 (setengah resolusi layar, downsampled) untuk
   performa lebih baik.
   Outline: diporting 1:1 dari Complementary Unbound (worldOutline.glsl),
   shader publik yang sudah tervalidasi dan terkenal. Disederhanakan dari
   bagian Distant Horizons/Voxy/scaled-mode yang tidak relevan untuk
   shaderpack ini, tapi rumus inti (slope, threshold, outline formula)
   TIDAK diubah sama sekali dari aslinya.
*/

#define BLOOM_STRENGTH 0.3 // [0.0 0.15 0.3 0.5 0.8]
//#define OUTLINE_ENABLED // Nyalakan outline block (default MATI)
//#define OUTLINE_SCALED // Ketebalan outline adaptif terhadap jarak & FOV, bukan pixel tetap (default MATI, sama seperti kode asli)
#define OUTLINE_THICKNESS 1.0 // [1.0 2.0 3.0 4.0]
#define OUTLINE_INTENSITY 1.5 // [0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.5 3.0 3.5 4.0]

uniform sampler2D colortex0;
uniform sampler2D colortex1;
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

// --- Bloom: baca colortex1 (lowres, downsampled) di sekitar titik ---
vec3 sampleBloom(vec2 uv, vec2 lowresPixelSize) {
    vec3 sum = vec3(0.0);
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 offset = vec2(float(x), float(y)) * lowresPixelSize * 2.0;
            vec3 s = texture(colortex1, uv + offset).rgb;
            float lum = dot(s, vec3(0.299, 0.587, 0.114));
            float weight = smoothstep(0.6, 1.0, lum);
            sum += s * weight;
        }
    }
    return sum / 9.0;
}

// --- COPY PASTE PERSIS dari Complementary Unbound (composite.glsl) ---
float GetLinearDepth(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

// --- DIPORTING 1:1 dari Complementary Unbound (worldOutline.glsl),
// DoWorldOutline(). Rumus inti (slope, threshold, formula outline) TIDAK
// diubah. Disederhanakan hanya dari bagian Distant Horizons/Voxy fade
// (tidak relevan, mod itu tidak ada di setup ini). Mode scaled (adaptif
// jarak+FOV) dan dither (anti-banding temporal) DIPORT LENGKAP, tidak
// diskip lagi. ---
void applyWorldOutline(inout vec3 color, vec2 texCoord, float linearZ0) {
#ifndef OUTLINE_SCALED
    vec2 scale = vec2(1.0 / viewWidth, 1.0 / viewHeight);
#else
    // Dither, persis kode asli: sample noisetex + golden ratio temporal offset
    float dither = texture2DLod(noisetex, texCoord * vec2(viewWidth, viewHeight) / 128.0, 0.0).b;
    const float goldenRatio = 1.61803398875;
    dither = fract(dither + goldenRatio * mod(float(frameCounter), 3600.0));

    float scm = 0.005;
    float fovScale = gbufferProjection[1][1];
    float distScale = max((far - near) * linearZ0 + near, 3.0);
    vec2 scale = vec2(scm / aspectRatio, scm) * fovScale / distScale;
    scale *= 0.99 + 0.2 * dither;
#endif

    // Fix screen edges (persis kode asli)
    vec2 texCoordDirection = sign(texCoord - vec2(0.5));
    vec2 checkCoord = texCoord + scale * vec2(texCoordDirection.x * OUTLINE_THICKNESS, texCoordDirection.y * OUTLINE_THICKNESS);
    vec2 absCheckCoord = abs(checkCoord - vec2(0.5));
    float outlineMult = max(0.0, 0.5 - max(absCheckCoord.x, absCheckCoord.y));
    outlineMult = min(1.0, outlineMult * 0.1 / (scale.x * OUTLINE_THICKNESS));

    if (outlineMult < 0.0001) return;

    outlineMult *= 0.25;

    float r0 = 1.0 / GetLinearDepth(texture(depthtex0, texCoord + vec2(-OUTLINE_THICKNESS, -OUTLINE_THICKNESS) * scale).r);
    float r1 = 1.0 / GetLinearDepth(texture(depthtex0, texCoord + vec2(-OUTLINE_THICKNESS,  OUTLINE_THICKNESS) * scale).r);
    float r2 = 1.0 / GetLinearDepth(texture(depthtex0, texCoord + vec2( OUTLINE_THICKNESS, -OUTLINE_THICKNESS) * scale).r);
    float r3 = 1.0 / GetLinearDepth(texture(depthtex0, texCoord + vec2( OUTLINE_THICKNESS,  OUTLINE_THICKNESS) * scale).r);
    float rA = 0.25 * (r0 + r1 + r2 + r3);
    float slope = (1.0 / linearZ0 - rA) * (linearZ0 * linearZ0);

    float threshold = linearZ0 / 2000.0 * OUTLINE_THICKNESS;
    float outline = clamp(slope / threshold, 0.0, 1.0) * OUTLINE_INTENSITY;

    outline *= outlineMult;

    color += min(color * outline, vec3(outline));
}

void main() {
    vec2 uv = texcoord;
    vec3 color = texture(colortex0, uv).rgb;

    // pixelSize untuk bloom dihitung dari resolusi colortex1 (setengah layar)
    vec2 lowresPixelSize = 2.0 / vec2(viewWidth, viewHeight);

    // Bloom (downsampled)
    vec3 bloom = sampleBloom(uv, lowresPixelSize);
    color += bloom * BLOOM_STRENGTH;

    // Outline (opsional, default mati). Full-resolution, algoritma
    // Complementary Unbound (worldOutline).
#ifdef OUTLINE_ENABLED
    float rawDepth = texture(depthtex0, uv).r;
    float linearZ0 = GetLinearDepth(rawDepth);
    applyWorldOutline(color, uv, linearZ0);
#endif

    outColor0 = vec4(color, 1.0);
}
