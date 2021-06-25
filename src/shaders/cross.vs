#version 430

// Uniforms
layout (location = 0) uniform float aspect_ratio;

const float sz = 0.02;
const float d = 10;
const float xoff[12] = float[](-sz/d, sz/d, sz/d, sz/d,-sz/d,-sz/d,-sz,   sz,   sz,   sz,  -sz,  -sz);
const float yoff[12] = float[](-sz,  -sz,   sz,   sz,   sz,  -sz,  -sz/d,-sz/d, sz/d, sz/d, sz/d,-sz/d);

void main() {
    gl_Position = vec4(xoff[gl_VertexID] / aspect_ratio, yoff[gl_VertexID], 0.0, 1.0);
}
