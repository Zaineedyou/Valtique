#version 330 compatibility

#define HALATION_ENABLED // Enables low-resolution warm halation.
#define HALATION_STRENGTH 0.25 // [0.0 0.15 0.25 0.35 0.5 0.7]
#define HALATION_RADIUS 0.75 // [0.5 0.75 1.0 1.5 2.0]
#define HALATION_WARMTH 0.65 // [0.0 0.35 0.65 0.85 1.0]

#define GODRAYS_ENABLED
#define GODRAYS_STRENGTH 0.50 // [0.0 0.15 0.25 0.35 0.50 0.70]

#define PERSISTENCE_ENABLED
#define PERSISTENCE_STRENGTH 0.06 // [0.0 0.06 0.14 0.22 0.35]
//#define POTATO_MODE

//#define OUTLINE_ENABLED
//#define OUTLINE_SCALED
#define OUTLINE_THICKNESS 1.0 // [1.0 2.0 3.0 4.0]
#define OUTLINE_INTENSITY 1.5 // [0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.5 3.0 3.5 4.0]
#define OUTLINE_GLOW 1.0 // [0.0 0.5 1.0 1.5 2.0 2.5]

//#define FIELD_CAMERA_ENABLED
#define FIELD_EXPOSURE 1.0 // [0.5 0.75 1.0 1.25 1.5]
#define FIELD_MONO 0.70 // [0.0 0.35 0.55 0.70 0.85 1.0]
#define FIELD_COMPRESSION 0.35 // [0.0 0.15 0.35 0.55 0.75 1.0]
#define FIELD_SENSOR_NOISE 0.06 // [0.0 0.03 0.06 0.10 0.15 0.22]
#define FIELD_INTERLACE 0.35 // [0.0 0.15 0.35 0.55 0.75 1.0]
//#define FIELD_OSD
#define FIELD_OSD_OPACITY 0.75 // [0.25 0.50 0.75 1.0]

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
uniform ivec3 currentTime;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

float sampleGodrays(vec2 uv) {
#ifdef GODRAYS_ENABLED
#ifndef POTATO_MODE
    return texture(colortex1, uv).a * GODRAYS_STRENGTH;
#else
    return 0.0;
#endif
#else
    return 0.0;
#endif
}

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

// Core world-outline logic adapted 1:1 from Complementary Unbound worldOutline.glsl.
void applyWorldOutline(inout vec3 color, vec2 texCoord, float linearZ0) {
#ifndef OUTLINE_SCALED
    vec2 scale = vec2(1.0 / vec2(viewWidth, viewHeight));
#else
    float dither = texture2DLod(noisetex, texCoord * vec2(viewWidth, viewHeight) / 128.0, 0.0).b;
    dither = fract(dither + 1.61803398875 * mod(float(frameCounter), 3600.0));
    float scm = 0.005;
    float fovScale = gbufferProjection[1][1];
    float distScale = max((far - near) * linearZ0 + near, 3.0);
    vec2 scale = vec2(scm / aspectRatio, scm) * fovScale / distScale;
    scale *= 0.99 + 0.2 * dither;
#endif

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
    color += vec3(outline * OUTLINE_GLOW * 0.20);
}

float fieldBox(vec2 point, vec2 center, vec2 halfSize) {
    vec2 delta = abs(point - center) - halfSize;
    return 1.0 - smoothstep(0.0, 0.04, max(delta.x, delta.y));
}

float fieldDigit(vec2 point, int digit) {
    float top = fieldBox(point, vec2(0.0,  0.88), vec2(0.36, 0.10));
    float upperRight = fieldBox(point, vec2(0.42,  0.44), vec2(0.10, 0.34));
    float lowerRight = fieldBox(point, vec2(0.42, -0.44), vec2(0.10, 0.34));
    float bottom = fieldBox(point, vec2(0.0, -0.88), vec2(0.36, 0.10));
    float lowerLeft = fieldBox(point, vec2(-0.42, -0.44), vec2(0.10, 0.34));
    float upperLeft = fieldBox(point, vec2(-0.42,  0.44), vec2(0.10, 0.34));
    float middle = fieldBox(point, vec2(0.0, 0.0), vec2(0.36, 0.10));

    if (digit == 0) return max(max(max(top, upperRight), max(lowerRight, bottom)), max(lowerLeft, upperLeft));
    if (digit == 1) return max(upperRight, lowerRight);
    if (digit == 2) return max(max(max(top, upperRight), middle), max(lowerLeft, bottom));
    if (digit == 3) return max(max(max(top, upperRight), middle), max(lowerRight, bottom));
    if (digit == 4) return max(max(upperLeft, middle), max(upperRight, lowerRight));
    if (digit == 5) return max(max(max(top, upperLeft), middle), max(lowerRight, bottom));
    if (digit == 6) return max(max(max(top, upperLeft), middle), max(lowerLeft, max(lowerRight, bottom)));
    if (digit == 7) return max(top, max(upperRight, lowerRight));
    if (digit == 8) return max(max(max(top, upperRight), max(lowerRight, bottom)), max(lowerLeft, max(upperLeft, middle)));
    return max(max(max(top, upperRight), max(lowerRight, bottom)), max(upperLeft, middle));
}

float fieldOSD(vec2 uv) {
    vec2 base = vec2(0.040, 0.940);
    vec2 size = vec2(0.010, 0.016);
    int hours = currentTime.x;
    int minutes = currentTime.y;
    int seconds = currentTime.z;

    float marks = 0.0;
    marks = max(marks, fieldDigit((uv - (base + vec2(0.000, 0.0))) / size, hours / 10));
    marks = max(marks, fieldDigit((uv - (base + vec2(0.025, 0.0))) / size, hours % 10));
    marks = max(marks, fieldDigit((uv - (base + vec2(0.058, 0.0))) / size, minutes / 10));
    marks = max(marks, fieldDigit((uv - (base + vec2(0.083, 0.0))) / size, minutes % 10));
    marks = max(marks, fieldDigit((uv - (base + vec2(0.116, 0.0))) / size, seconds / 10));
    marks = max(marks, fieldDigit((uv - (base + vec2(0.141, 0.0))) / size, seconds % 10));

    vec2 colonA = (uv - (base + vec2(0.046, 0.0))) / size;
    vec2 colonB = (uv - (base + vec2(0.104, 0.0))) / size;
    marks = max(marks, fieldBox(colonA, vec2(0.0, 0.35), vec2(0.08, 0.08)));
    marks = max(marks, fieldBox(colonA, vec2(0.0, -0.35), vec2(0.08, 0.08)));
    marks = max(marks, fieldBox(colonB, vec2(0.0, 0.35), vec2(0.08, 0.08)));
    marks = max(marks, fieldBox(colonB, vec2(0.0, -0.35), vec2(0.08, 0.08)));

    float recPoint = 1.0 - smoothstep(0.28, 0.36, length((uv - vec2(0.024, 0.940)) / size));
    return max(marks, recPoint);
}

void applyFieldCamera(inout vec3 color, vec2 uv) {
    color = clamp((color - vec3(0.5)) * FIELD_EXPOSURE + vec3(0.5), 0.0, 1.0);
    color = mix(color, vec3(dot(color, vec3(0.299, 0.587, 0.114))), FIELD_MONO);

    vec2 pixelCoord = uv * vec2(viewWidth, viewHeight);
    vec2 compressionCell = floor(pixelCoord * 0.125) / 128.0;
    float blockNoise = texture2D(noisetex, compressionCell).g - 0.5;
    float sensorNoise = fract(pixelCoord.x * 0.754877666 + pixelCoord.y * 0.569840291 + float(frameCounter) * 0.618033989) - 0.5;
    float levels = mix(64.0, 10.0, FIELD_COMPRESSION);
    color = floor(clamp(color + blockNoise * FIELD_COMPRESSION * 0.035, 0.0, 1.0) * levels + 0.5) / levels;
    color += vec3(sensorNoise * FIELD_SENSOR_NOISE);

    float fieldLine = mod(floor(pixelCoord.y) + float(frameCounter), 2.0);
    color *= 1.0 - fieldLine * FIELD_INTERLACE * 0.18;

#ifdef FIELD_OSD
    if (uv.x < 0.20 && uv.y > 0.90) {
        float osd = fieldOSD(uv) * FIELD_OSD_OPACITY;
        color = mix(color, vec3(0.88), osd);
    }
#endif
}

void main() {
    vec2 uv = texcoord;
    vec3 color = texture(colortex0, uv).rgb;

#ifdef FIELD_CAMERA_ENABLED
    applyFieldCamera(color, uv);
#endif

#ifdef OUTLINE_ENABLED
    applyWorldOutline(color, uv, GetLinearDepth(texture(depthtex0, uv).r));
#endif

#ifdef HALATION_ENABLED
    // Add after grayscale/compression so the orange highlight remains visible.
    vec3 warmTint = mix(vec3(1.0), vec3(1.0, 0.52, 0.18), HALATION_WARMTH);
    color += sampleHalation(uv) * warmTint * HALATION_STRENGTH;
    color += vec3(1.0, 0.80, 0.42) * sampleGodrays(uv);
#endif

#ifdef PERSISTENCE_ENABLED
    color += texture(colortex2, uv).rgb * PERSISTENCE_STRENGTH;
#endif

    outColor0 = vec4(color, 1.0);
}
