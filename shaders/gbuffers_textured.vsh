#version 330 compatibility

/* Fallback untuk particles, items, dan geometry textured lain yang tidak
   punya gbuffers spesifik sendiri. Ditulis eksplisit agar Iris tidak
   melakukan auto-reconstruction (yang menyisipkan fog vanilla otomatis). */

out vec2 texCoord;
out vec4 vertexColor;
out float fogDistance;

void main() {
    gl_Position = ftransform();
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vertexColor = gl_Color;
    gl_FogFragCoord = 0.0;
    fogDistance = length((gl_ModelViewMatrix * gl_Vertex).xyz);
}
