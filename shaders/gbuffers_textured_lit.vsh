#version 330 compatibility

/* Fallback untuk player hand, entities, weather (hujan/salju), particles
   berlighting, dll. Ini titik fallback paling krusial yang sebelumnya
   terlewat — banyak kategori geometry jatuh ke sini kalau tidak ada
   gbuffers spesifiknya sendiri. */

out vec2 texCoord;
out vec2 lightMapCoord;
out vec4 vertexColor;
out float fogDistance;

void main() {
    gl_Position = ftransform();
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lightMapCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vertexColor = gl_Color;
    gl_FogFragCoord = 0.0;
    fogDistance = length((gl_ModelViewMatrix * gl_Vertex).xyz);
}
