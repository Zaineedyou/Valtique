#version 330 compatibility

/* Khusus untuk matahari, bulan, dan bintang (textured sky objects).
   Dipisah dari gbuffers_textured supaya TIDAK ikut kena fog — sky object
   dirender di jarak yang tidak representatif untuk perhitungan fog jarak
   biasa, sehingga kalau ikut fog, hasilnya bisa melebar/blur jadi
   lingkaran putih besar saat FOG_ENABLED dinyalakan. */

varying vec2 texCoord;
varying vec4 vertexColor;

void main() {
    gl_Position = ftransform();
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vertexColor = gl_Color;
}
