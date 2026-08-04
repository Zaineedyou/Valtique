#version 330 compatibility

/* Fallback dasar untuk berbagai geometry (block outline, fishing line, dll)
   yang tidak punya gbuffers spesifik sendiri. Ditulis eksplisit supaya Iris
   TIDAK melakukan auto-reconstruction vanilla shader untuk kategori ini
   (auto-reconstruction Iris menyisipkan fog vanilla exponential secara
   otomatis, itulah sumber "fog maksa" yang muncul sebelumnya). */

out vec4 vertexColor;

void main() {
    gl_Position = ftransform();
    vertexColor = gl_Color;
    gl_FogFragCoord = 0.0;
}
