#version 430

// Vertex attributes
layout (location = 0) in int attrib;

// Uniforms
layout (location = 1) uniform mat4 MVP;
layout (location = 2) uniform ivec3 chunk_pos;
layout (location = 3) uniform ivec3 int_translation;

//in vec3 float_position;
//in vec3 textCoord;

out vec3 shaded_text_coord;

out float light_intensity;

const vec3 vert_deltas[8] = vec3[8](
    vec3(0.0, 0.0, 0.0), //bottom_west_south
    vec3(1.0, 0.0, 0.0), //bottom_west_north
    vec3(0.0, 0.0, 1.0), //top_west_south
    vec3(1.0, 0.0, 1.0), //top_west_north
    vec3(0.0, 1.0, 0.0), //bottom_east_south
    vec3(1.0, 1.0, 0.0), //bottom_east_north
    vec3(0.0, 1.0, 1.0), //top_east_south
    vec3(1.0, 1.0, 1.0)  //top_east_north
);

const int delta_inds[6][6] = int[6][6](
    // Up
    int[6](
        6, // top_east_south
        2, // top_west_south
        3, // top_west_north
        3, // top_west_north
        7, // top_east_north
        6  // top_east_south
    ),

    // Down
    int[6](
        0, // bottom_west_south
        4, // bottom_east_south
        5, // bottom_east_north
        5, // bottom_east_north
        1, // bottom_west_north
        0  // bottom_west_south
    ),

    // West
    int[6](
        0, // bottom_west_south
        1, // bottom_west_north
        3, // top_west_north
        3, // top_west_north
        2, // top_west_south
        0  // bottom_west_south
    ),

    // East
    int[6](
        5, // bottom_east_north
        4, // bottom_east_south
        6, // top_east_south
        6, // top_east_south
        7, // top_east_north
        5  // bottom_east_north
    ),

    // North
    int[6](
        1, // bottom_west_north
        5, // bottom_east_north
        7, // top_east_north
        7, // top_east_north
        3, // top_west_north
        1  // bottom_west_north
    ),

    // South
    int[6](
        4, // bottom_east_south
        0, // bottom_west_south
        2, // top_west_south
        2, // top_west_south
        6, // top_east_south
        4  // bottom_east_south
    )
);

const float text_u_vals[6] = float[6](1,0,0,0,1,1);
const float text_v_vals[6] = float[6](1,1,0,0,0,1);
const float face_light[6] = float[6](1.0,0.9,0.95,0.95,0.95,0.95);

void main() {
    int direction = attrib & 0xFF;
    int texture = (attrib >> 8) & 0xFF;
    int x = (attrib >> 16) & 0x1F;
    int y = (attrib >> 21) & 0x1F;
    int z = (attrib >> 26) & 0x1F;

    ivec3 int_pos = ivec3(x, y, z) + chunk_pos;

    int_pos += int_translation;

    vec3 float_pos = vec3(float(int_pos.x), float(int_pos.y), float(int_pos.z));

    float_pos += vert_deltas[delta_inds[direction][gl_VertexID]];

    // float_pos += float_translation;

    gl_Position = MVP * vec4(float_pos, 1.0);

    light_intensity = face_light[direction];
    shaded_text_coord = vec3(text_u_vals[gl_VertexID], text_v_vals[gl_VertexID], float(texture));
}
