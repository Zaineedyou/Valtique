#version 330 compatibility

in vec4 vertexColor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
    outColor0 = vertexColor;
}
