const std = @import("std");
const glm = @import("glm");
const config = @import("config");

const glfw = @import("bind/glfw.zig");
const textures = @import("textures.zig");
const blocks = @import("blocks/blocks.zig");
const shader = @import("shader.zig");

const log = std.log.scoped(.game);

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

fn fmod(f32: value) f32 {
    return value - std.math.floor(value);
}

fn update_mouse(window: anytype, comptime ignore: anytype, look_x: *f32, look_z: *f32) void {
    const delta = glfw.getMouseDelta(window);
    if (comptime (ignore == .ignore))
        return;

    look_x.* += @floatCast(f32, -delta.dx * config.mouse_sensitivity);
    look_z.* += @floatCast(f32, -delta.dy * config.mouse_sensitivity);

    look_x.* = @mod(look_x.*, 2 * @as(f32, std.math.pi));

    look_z.* = std.math.clamp(look_z.*, -@as(f32, std.math.pi) / 2, @as(f32, std.math.pi) / 2);
}

fn update_movement(window: anytype, pos: *glm.Vector(3), look_x: f32) void {
    const forwards = forward(look_x, 0);
    const right = forward(look_x - @as(f32, std.math.pi) / 2, 0);

    var vel = glm.Vector(3).init([_]f32{ 0, 0, 0 });

    if (config_key_pressed(window, .forward)) vel.addAssign(forwards);
    if (config_key_pressed(window, .backward)) vel.subAssign(forwards);
    if (config_key_pressed(window, .left)) vel.subAssign(right);
    if (config_key_pressed(window, .right)) vel.addAssign(right);

    if (vel.values[0] != 0 or vel.values[1] != 0) vel.normalizeAssign();

    if (config_key_pressed(window, .down)) vel.values[2] -= 1;
    if (config_key_pressed(window, .up)) vel.values[2] += 1;

    vel.divAssignScalar(20);

    pos.addAssign(vel);
}

pub fn loop(game_window: anytype) !void {
    const atlas = textures.init();

    var mesh_builder: @import("chunk_mesh.zig").ChunkMeshBuilder = undefined;
    try mesh_builder.init(std.heap.page_allocator, 2);
    defer mesh_builder.deinit(std.heap.page_allocator);

    @import("blocks/blocks.zig").findBlock(.grass).block_type.addToMesh(.{
        .mesh = &mesh_builder,
        .x = -1,
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
        .x = 1,
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

    var position = glm.Vector(3).init([_]f32{ 0.5, -1.5, 2 });
    var look_z: f32 = -0.4;
    var look_x: f32 = @as(f32, std.math.pi) / 2;

    while (true) {
        if (glfw.windowShouldClose(game_window) or config_key_pressed(game_window, .quit)) {
            break;
        }

        update_mouse(game_window, .do_not_ignore, &look_x, &look_z);
        update_movement(game_window, &position, look_x);

        const look_direction = forward(look_x, look_z);
        const up = forward(look_x, look_z + @as(f32, std.math.pi) / 2);

        const window_size = glfw.getWindowSize(game_window);
        const aspect_ratio = @intToFloat(f32, window_size[0]) / @intToFloat(f32, window_size[1]);

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
