#version 430

in vec3 shaded_text_coord;
in float light_intensity;

layout(location = 0) out vec4 color;

uniform sampler2DArray texture_sampler;

void main() {
  color = texture(texture_sampler, shaded_text_coord);
  if(color.a < 0.5) {
  	discard;
  }
  color.xyz *= light_intensity;
}
