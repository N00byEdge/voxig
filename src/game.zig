const std = @import("std");
const glm = @import("glm");
const zgl = @import("zgl");
const config = @import("config");

const glfw = @import("bind/glfw.zig");
const textures = @import("textures.zig");
const blocks = @import("blocks/blocks.zig");

const CrossShader = @import("shaders/cross.zig").CrossShader;
const VoxelShader = @import("shaders/voxel.zig").VoxelShader;

const log = std.log.scoped(.game);

fn forward(look_x: f32, look_z: f32) glm.Vector(3) {
    return glm.Vector(3).init([_]f32{
        std.math.cos(look_x) * std.math.cos(look_z),
        std.math.sin(look_x) * std.math.cos(look_z),
        std.math.sin(look_z),
    });
}

fn configKeyPressed(window: anytype, comptime tag: anytype) bool {
    const key_name = @tagName(@field(config.keys, @tagName(tag)));
    const state = glfw.c.glfwGetKey(window, @field(glfw.c, key_name));
    return state == glfw.c.GLFW_PRESS;
}

fn updateMouse(window: anytype, look_x: *f32, look_z: *f32) void {
    const delta = glfw.getMouseDelta(window);

    look_x.* += @floatCast(f32, -delta.dx * config.mouse_sensitivity);
    look_z.* += @floatCast(f32, -delta.dy * config.mouse_sensitivity);

    look_x.* = @mod(look_x.*, 2 * @as(f32, std.math.pi));

    look_z.* = std.math.clamp(look_z.*, -@as(f32, std.math.pi) / 2, @as(f32, std.math.pi) / 2);
}

fn updateMovement(window: anytype, pos: *glm.Vector(3), look_x: f32) void {
    const forwards = forward(look_x, 0);
    const right = forward(look_x - @as(f32, std.math.pi) / 2, 0);

    var vel = glm.Vector(3).init([_]f32{ 0, 0, 0 });

    if (configKeyPressed(window, .forward)) vel.addAssign(forwards);
    if (configKeyPressed(window, .backward)) vel.subAssign(forwards);
    if (configKeyPressed(window, .left)) vel.subAssign(right);
    if (configKeyPressed(window, .right)) vel.addAssign(right);

    if (vel.values[0] != 0 or vel.values[1] != 0) vel.normalizeAssign();

    if (configKeyPressed(window, .down)) vel.values[2] -= 1;
    if (configKeyPressed(window, .up)) vel.values[2] += 1;

    // We just assume 60 fps here, should use the frame delta at some point
    vel.mulAssignScalar(config.movement_speed / @as(f32, 60));

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

    var voxel_shader = try VoxelShader.init(atlas);
    defer voxel_shader.deinit();

    var cross_shader = try CrossShader.init();
    defer cross_shader.deinit();

    glfw.c.glClearColor(0.1, 0.0, 0.0, 1.0);

    var position = glm.Vector(3).init([_]f32{ 0.5, -1.5, 2 });
    var look_z: f32 = -0.4;
    var look_x: f32 = @as(f32, std.math.pi) / 2;

    while (true) {
        if (glfw.windowShouldClose(game_window) or configKeyPressed(game_window, .quit)) {
            break;
        }

        updateMouse(game_window, &look_x, &look_z);
        updateMovement(game_window, &position, look_x);

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

        zgl.clear(.{
            .color = true,
            .depth = true,
        });

        voxel_shader.camera(camera);
        voxel_shader.draw(mesh);
        cross_shader.draw(aspect_ratio);

        glfw.swapBuffers(game_window);
        glfw.pollEvents();
    }
}
