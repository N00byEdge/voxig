const std = @import("std");
const glm = @import("glm");
const config = @import("config");

const glfw = @import("bind/glfw.zig");
const textures = @import("textures.zig");
const blocks = @import("blocks/blocks.zig");
const shader = @import("shader.zig");

fn forward(look_x: f32, look_z: f32) glm.Vector(3) {
    return glm.Vector(3).init([_]f32{
        std.math.cos(look_x) * std.math.cos(look_z),
        std.math.sin(look_x) * std.math.cos(look_z),
        std.math.sin(look_z),
    });
}

fn config_key_pressed(window: anytype, comptime tag: anytype) bool {
    const key_name = @tagName(@field(config.keys, @tagName(tag)));
    const state = glfw.c.glfwGetKey(window, @field(glfw.c, key_name));
    return state == glfw.c.GLFW_PRESS;
}

pub fn loop(game_window: anytype) !void {
    const atlas = textures.init();

    var mesh_builder: @import("chunk_mesh.zig").ChunkMeshBuilder = undefined;
    try mesh_builder.init(std.heap.page_allocator, 2);
    defer mesh_builder.deinit(std.heap.page_allocator);

    @import("blocks/blocks.zig").findBlock(.grass).block_type.addToMesh(.{
        .mesh = &mesh_builder,
        .x = 0,
        .y = 0,
        .z = 0,
        .draw_top = true,
        .draw_bottom = true,
        .draw_north = true,
        .draw_south = true,
        .draw_west = true,
        .draw_east = true,
    });

    @import("blocks/blocks.zig").findBlock(.barrier).block_type.addToMesh(.{
        .mesh = &mesh_builder,
        .x = 2,
        .y = 0,
        .z = 0,
        .draw_top = true,
        .draw_bottom = true,
        .draw_north = true,
        .draw_south = true,
        .draw_west = true,
        .draw_east = true,
    });

    const mesh = try mesh_builder.finalize(std.heap.page_allocator);
    defer mesh.deinit(std.heap.page_allocator);

    var voxel_shader: shader.Shader = undefined;
    try voxel_shader.init("voxel", atlas);
    defer voxel_shader.deinit();

    voxel_shader.bind();

    glfw.c.glClearColor(0.1, 0.0, 0.0, 1.0);

    var position = glm.Vector(3).init([_]f32{ 0, -1, 0 });
    var look_z: f32 = 0;
    var look_x: f32 = @as(f32, std.math.pi) / 2;

    while (true) {
        if (glfw.windowShouldClose(game_window) or config_key_pressed(game_window, .quit)) {
            break;
        }

        var vel = glm.Vector(3).init([_]f32{ 0, 0, 0 });

        if (config_key_pressed(game_window, .forward)) vel.values[1] += 1;
        if (config_key_pressed(game_window, .backward)) vel.values[1] -= 1;
        if (config_key_pressed(game_window, .left)) vel.values[0] -= 1;
        if (config_key_pressed(game_window, .right)) vel.values[0] += 1;

        if (vel.values[0] != 0 or vel.values[2] != 0) vel.normalizeAssign();

        if (config_key_pressed(game_window, .down)) vel.values[2] -= 1;
        if (config_key_pressed(game_window, .up)) vel.values[2] += 1;

        vel.divAssignScalar(20);

        position.addAssign(vel);

        const window_size = glfw.getWindowSize(game_window);
        const aspect_ratio = @intToFloat(f32, window_size[0]) / @intToFloat(f32, window_size[1]);

        const look_side = std.math.cos(look_z);

        const look_direction = forward(look_x, look_z);
        const up = forward(look_x, look_z + @as(f32, std.math.pi) / 2);

        const perspective = glm.perspective(
            config.fov,
            aspect_ratio,
            config.near,
            config.far,
        );

        const look = glm.lookAt(
            position,
            position.add(look_direction),
            up,
        );
        const camera = perspective.mul(look);

        voxel_shader.camera(camera);

        glfw.c.glClear(glfw.c.GL_COLOR_BUFFER_BIT | glfw.c.GL_DEPTH_BUFFER_BIT);

        mesh.draw();

        glfw.swapBuffers(game_window);
        glfw.pollEvents();
    }
}
