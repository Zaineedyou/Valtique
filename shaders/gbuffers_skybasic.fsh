#version 330 compatibility

/* Preserve sky color without fallback fog. */

in vec4 vertexColor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
    outColor0 = vertexColor;
}
