#version 330 compatibility

out vec2 texCoord;
out vec2 lightMapCoord;
out vec4 vertexColor;
out float fogDistance;

void main() {
    gl_Position = ftransform();
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lightMapCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vertexColor = gl_Color;

    // Matikan vanilla fixed-function fog secara eksplisit.
    gl_FogFragCoord = 0.0;

    // Kirim jarak eye-space ke fragment shader, dipakai untuk custom fog
    // manual yang jaraknya bisa kita dorong lebih jauh dari default vanilla.
    fogDistance = length((gl_ModelViewMatrix * gl_Vertex).xyz);
}
