#version 330 compatibility

/* Sky/horizon/void basic — warna vertex asli langsung ditulis, TIDAK ada
   pencampuran fog vanilla (gl_Fog) sama sekali. Ini mematikan sumber fog
   abu-abu yang sebelumnya muncul otomatis dari fallback built-in Iris. */

in vec4 vertexColor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
    outColor0 = vertexColor;
}
