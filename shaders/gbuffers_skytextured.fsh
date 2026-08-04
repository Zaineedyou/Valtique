#version 330 compatibility

uniform sampler2D texture;

varying vec2 texCoord;
varying vec4 vertexColor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
    vec4 albedo = texture2D(texture, texCoord) * vertexColor;
    if (albedo.a < 0.1) {
        discard;
    }
    outColor0 = albedo;
}
