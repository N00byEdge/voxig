const std = @import("std");

const glfw = @import("bind/glfw.zig");
const textures = @import("textures.zig");
const blocks = @import("blocks/blocks.zig");
const shader = @import("shader.zig");

pub fn loop(game_window: anytype) !void {
    const atlas = textures.init();

    var mesh_builder: @import("chunk_mesh.zig").ChunkMeshBuilder = undefined;
    try mesh_builder.init(std.heap.page_allocator, 1);
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

    const mesh = try mesh_builder.finalize(std.heap.page_allocator);
    defer mesh.deinit(std.heap.page_allocator);

    var voxel_shader: shader.Shader = undefined;
    try voxel_shader.init("voxel", atlas);
    defer voxel_shader.deinit();

    voxel_shader.bind();

    glfw.c.glClearColor(0.1, 0.0, 0.0, 1.0);

    while (true) {
        if (glfw.windowShouldClose(game_window)) {
            break;
        }

        glfw.c.glClear(glfw.c.GL_COLOR_BUFFER_BIT | glfw.c.GL_DEPTH_BUFFER_BIT);

        mesh.draw();

        glfw.swapBuffers(game_window);
        glfw.pollEvents();
    }
}
