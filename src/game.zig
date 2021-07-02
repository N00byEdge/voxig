const std = @import("std");
const glm = @import("glm");
const zgl = @import("zgl");
const config = @import("config");

const glfw = @import("bind/glfw.zig");
const textures = @import("textures.zig");
const blocks = @import("blocks/blocks.zig");

const CrossShader = @import("shaders/cross.zig").CrossShader;
const VoxelShader = @import("shaders/voxel.zig").VoxelShader;
const World = @import("world/world.zig").World;
const Player = @import("player.zig").Player;

const log = std.log.scoped(.game);

pub fn loop(game_window: anytype) !void {
    const atlas = textures.init();

    var world = try World.init();
    defer world.deinit();

    var voxel_shader = try VoxelShader.init(atlas);
    defer voxel_shader.deinit();

    var player = try Player.init(&world);
    defer player.deinit();

    var cross_shader = try CrossShader.init();
    defer cross_shader.deinit();

    glfw.c.glClearColor(0.1, 0.0, 0.0, 1.0);

    while (true) {
        if (game_window.shouldClose() or game_window.configKeyPressed(.quit)) {
            break;
        }

        zgl.clear(.{
            .color = true,
            .depth = true,
        });

        player.updateWithInput(game_window, 1.0 / 60.0);
        player.drawPlayerView(&voxel_shader);

        cross_shader.drawCross(game_window.aspect_ratio);

        game_window.swapBuffers();
        glfw.pollEvents();
    }
}
