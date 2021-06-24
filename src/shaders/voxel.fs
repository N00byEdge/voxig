#version 430

in vec3 shaded_text_coord;

layout(location = 0) out vec4 color;

uniform sampler2DArray texture_sampler;

void main() {
  color = texture(texture_sampler, shaded_text_coord);
}
