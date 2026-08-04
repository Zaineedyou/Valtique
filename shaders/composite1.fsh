#version 330 compatibility

/* CINEMATIC OLD FILM SHADER - composite pass 2/3
   Pass ini KHUSUS mengisi colortex1 (resolusi setengah layar) dengan warna
   untuk bloom di pass 3 (composite2.fsh). Outline TIDAK memakai downsample
   sama sekali — outline membaca depthtex0 langsung di resolusi penuh,
   persis logic asli shaderpack referensi, karena presisi depth penting
   untuk deteksi edge yang akurat dan downsampling depth berisiko
   menimbulkan artifact presisi rendah (banding/checkerboard) di beberapa
   GPU/driver.
*/

uniform sampler2D colortex0;

in vec2 texcoord;

/* RENDERTARGETS: 1 */
layout(location = 0) out vec4 outColor1;

void main() {
    vec3 color = texture(colortex0, texcoord).rgb;
    outColor1 = vec4(color, 1.0);
}
