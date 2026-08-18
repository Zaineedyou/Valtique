#version 330 compatibility

#define HALATION_ENABLED // Enables low-resolution warm halation.
#define HALATION_THRESHOLD 0.7 // [0.4 0.55 0.7 0.85 1.0]

uniform sampler2D colortex0;

in vec2 texcoord;

/* RENDERTARGETS: 1 */
layout(location = 0) out vec4 outColor1;

void main() {
#ifdef HALATION_ENABLED
    vec3 color = texture(colortex0, texcoord).rgb;
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    outColor1 = vec4(color * smoothstep(HALATION_THRESHOLD, 1.0, luminance), 1.0);
#else
    outColor1 = vec4(0.0);
#endif
}
