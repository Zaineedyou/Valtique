#version 330 compatibility

/* Keep textured sky objects outside distance fog. */

varying vec2 texCoord;
varying vec4 vertexColor;

void main() {
    gl_Position = ftransform();
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vertexColor = gl_Color;
}
