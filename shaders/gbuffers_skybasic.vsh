#version 330 compatibility

/* Prevent fallback fog on vanilla sky. */

out vec4 vertexColor;

void main() {
    gl_Position = ftransform();
    vertexColor = gl_Color;
    gl_FogFragCoord = 0.0;
}
