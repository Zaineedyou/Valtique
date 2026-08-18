#version 330 compatibility

out vec2 texCoord;
out vec2 lightMapCoord;
out vec4 vertexColor;
#ifdef FOG_ENABLED
out float fogDistance;
#endif

void main() {
    gl_Position = ftransform();
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lightMapCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vertexColor = gl_Color;
    gl_FogFragCoord = 0.0;
#ifdef FOG_ENABLED
    fogDistance = length((gl_ModelViewMatrix * gl_Vertex).xyz);
#endif
}
