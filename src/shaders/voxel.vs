#version 430

// Vertex attributes
layout (location = 0) in ivec4 face_position;

// Uniforms
layout (location = 1) uniform mat4 MVP;

//in vec3 float_position;
//in vec3 textCoord;

out vec3 shaded_text_coord;

//uniform vec3 float_translation;
//uniform ivec3 int_translation;

const vec3 vert_deltas[8] = vec3[8](
    vec3(0.0, 0.0, 0.0), //bottom_west_south
    vec3(0.0, 0.0, 1.0), //bottom_west_north
    vec3(0.0, 1.0, 0.0), //top_west_south
    vec3(0.0, 1.0, 1.0), //top_west_north
    vec3(1.0, 0.0, 0.0), //bottom_east_south
    vec3(1.0, 0.0, 1.0), //bottom_east_north
    vec3(1.0, 1.0, 0.0), //top_east_south
    vec3(1.0, 1.0, 1.0)  //top_east_north
);

const int delta_inds[6][6] = int[6][6](
    // Up
    int[6](
        3, // top_west_north
        2, // top_west_south
        6, // top_east_south
        6, // top_east_south
        7, // top_east_north
        3  // top_west_north
    ),

    // Down
    int[6](
        5, // bottom_east_north
        4, // bottom_east_south
        0, // bottom_west_south
        0, // bottom_west_south
        1, // bottom_west_north
        5  // bottom_east_north
    ),

    // West
    int[6](
        3, // top_west_north
        1, // bottom_west_north
        0, // bottom_west_south
        0, // bottom_west_south
        2, // top_west_south
        3  // top_west_north
    ),

    // East
    int[6](
        6, // top_east_south
        4, // bottom_east_south
        5, // bottom_east_north
        5, // bottom_east_north
        7, // top_east_north
        6  // top_east_south
    ),

    // North
    int[6](
        7, // top_east_north
        5, // bottom_east_north
        1, // bottom_west_north
        1, // bottom_west_north
        3, // top_west_north
        7  // top_east_north
    ),

    // South
    int[6](
        2, // top_west_south
        0, // bottom_west_south
        4, // bottom_east_south
        4, // bottom_east_south
        6, // top_east_south
        2  // top_west_south
    )
);

const float text_u_vals[6] = float[6](0,0,1,1,1,0);
const float text_v_vals[6] = float[6](0,1,1,1,0,0);

void main() {
    int face_vert_idx = gl_VertexID % 6;

    ivec3 int_pos = face_position.xyz /* + chunk_pos */;
    int attrib = face_position.w;
    int direction = attrib & 0xFF;
    int texture = (attrib >> 8) % 0xFF;

    //int_pos += int_translation;

    vec3 float_pos = vec3(float(int_pos.x), float(int_pos.y), float(int_pos.z));

    float_pos += vert_deltas[delta_inds[direction][face_vert_idx]];

    // float_pos += float_translation;

    gl_Position = MVP * vec4(float_pos, 1.0);

    shaded_text_coord = vec3(text_u_vals[face_vert_idx], text_v_vals[face_vert_idx], float(texture) + 0.5);
}
