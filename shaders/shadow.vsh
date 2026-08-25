#version 330 compatibility

const float shadowMapBias = 0.90;

void main() {
    gl_Position = ftransform();

    float distort = length(gl_Position.xy) * shadowMapBias + (1.0 - shadowMapBias);
    gl_Position.xy /= distort;
    gl_Position.z *= 0.2;
}
