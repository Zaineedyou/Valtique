#version 330 compatibility

/* Fog di sini dihitung sendiri berbasis jarak (depth-based exponential
   falloff), mengikuti tutorial resmi Iris. Default fog MATI (FOG_ENABLED
   off) - nyalakan lewat Shader Pack Settings. Sama seperti pendekatan
   yang sudah terbukti benar di versi 1.20.1. */

//#define FOG_ENABLED
#define FOG_DENSITY 3.0 // [0.5 1.0 1.5 2.0 3.0 4.0 5.0 7.0 10.0]

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform vec3 fogColor;
uniform float far;

in vec2 texCoord;
in vec2 lightMapCoord;
in vec4 vertexColor;
in float fogDistance;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
    vec4 albedo = texture(texture, texCoord) * vertexColor;
    vec3 light = texture(lightmap, lightMapCoord).rgb;
    albedo.rgb *= light;

    if (albedo.a < 0.1) {
        discard;
    }

#ifdef FOG_ENABLED
    float dist = fogDistance / far;
    float fogFactor = exp(-FOG_DENSITY * (1.0 - dist));
    fogFactor = clamp(fogFactor, 0.0, 1.0);
    albedo.rgb = mix(albedo.rgb, pow(fogColor, vec3(2.2)), fogFactor);
#endif

    outColor0 = albedo;
}
