#version 330 compatibility

/* Sky/horizon/void basic — dipertahankan sesuai vanilla, tapi TANPA fog vanilla.
   Fog abu-abu yang muncul di game sebelumnya berasal dari fallback bawaan
   Iris untuk program ini (karena file custom-nya belum ada), yang menerapkan
   fog vanilla otomatis lewat uniform fogColor/fogDensity Iris. */

out vec4 vertexColor;

void main() {
    gl_Position = ftransform();
    vertexColor = gl_Color;
    gl_FogFragCoord = 0.0;
}
