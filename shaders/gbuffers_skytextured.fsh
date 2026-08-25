#version 330 compatibility

#define ROUND_CELESTIAL_BODIES

uniform sampler2D texture;

varying vec2 texCoord;
varying vec2 rawTexCoord;
varying vec4 vertexColor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
    vec4 albedo = texture2D(texture, texCoord) * vertexColor;

#ifdef ROUND_CELESTIAL_BODIES
    // Mask in untransformed quad UV so texture-atlas transforms cannot turn the disk into a square.
    float diskRadius = length(rawTexCoord - vec2(0.5));
    float diskMask = 1.0 - smoothstep(0.492, 0.500, diskRadius);
    if (diskMask <= 0.0) discard;
    albedo.a *= diskMask;
#endif

    if (albedo.a < 0.1) discard;
    outColor0 = albedo;
}
