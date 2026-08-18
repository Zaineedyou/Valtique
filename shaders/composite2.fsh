#version 330 compatibility

#define PERSISTENCE_ENABLED
#define PERSISTENCE_DECAY 0.72 // [0.55 0.65 0.72 0.8 0.88]
#define PERSISTENCE_THRESHOLD 0.72 // [0.5 0.6 0.72 0.85 1.0]

uniform sampler2D colortex0;
uniform sampler2D colortex2;

in vec2 texcoord;

/* RENDERTARGETS: 2 */
layout(location = 0) out vec4 outColor2;

const bool colortex2Clear = false;

void main() {
#ifdef PERSISTENCE_ENABLED
    vec3 current = texture(colortex0, texcoord).rgb;
    float luminance = dot(current, vec3(0.299, 0.587, 0.114));
    vec3 highlight = current * smoothstep(PERSISTENCE_THRESHOLD, 1.0, luminance);
    vec3 history = texture(colortex2, texcoord).rgb * PERSISTENCE_DECAY;
    outColor2 = vec4(max(highlight, history), 1.0);
#else
    outColor2 = vec4(0.0);
#endif
}
