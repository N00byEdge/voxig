#version 430

in vec3 shaded_text_coord;

uniform sampler2DArray texture_sampler;

void main() {
  gl_FragColor = texture(texture_sampler, shaded_text_coord);
  //gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
}
