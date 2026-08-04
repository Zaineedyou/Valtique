#version 330 compatibility

//#define FOG_ENABLED
#define FOG_DENSITY 3.0 // [0.5 1.0 1.5 2.0 3.0 4.0 5.0 7.0 10.0]

uniform sampler2D texture;
uniform vec3 fogColor;
uniform float far;

in vec2 texCoord;
in vec4 vertexColor;
in float fogDistance;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
    vec4 albedo = texture2D(texture, texCoord) * vertexColor;
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
