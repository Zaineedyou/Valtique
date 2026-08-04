#version 330 compatibility

/* Program final: menutup pipeline, menampilkan hasil composite ke layar
   dengan alpha dipaksa opaque penuh */

uniform sampler2D colortex0;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
    vec3 color = texture(colortex0, texcoord).rgb;
    outColor0 = vec4(color, 1.0);
}
