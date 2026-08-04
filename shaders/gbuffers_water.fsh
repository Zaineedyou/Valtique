#version 330 compatibility

uniform sampler2D texture;
uniform sampler2D lightmap;

in vec2 texCoord;
in vec2 lightMapCoord;
in vec4 vertexColor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
    vec4 albedo = texture2D(texture, texCoord) * vertexColor;
    vec3 light = texture2D(lightmap, lightMapCoord).rgb;
    albedo.rgb *= light;

    if (albedo.a < 0.1) {
        discard;
    }

    outColor0 = albedo;
}
