const std = @import("std");
const glfw = @import("bind/glfw.zig");
const zgl = @import("zgl");
const game = @import("game.zig");
const config = @import("config");

const log = std.log.scoped(.main);

pub fn main() anyerror!void {
    try glfw.init();
    defer glfw.terminate();

    var game_window: glfw.Window = undefined;
    game_window.init(
        config.default_resolution.width,
        config.default_resolution.height,
        "Zig memes",
    );
    defer game_window.deinit();

    game_window.makeContextCurrent();

    log.info("Enabling face culling", .{});
    glfw.c.glEnable(glfw.c.GL_CULL_FACE);

    log.info("Enabling depth testing", .{});
    glfw.c.glEnable(glfw.c.GL_DEPTH_TEST);
    glfw.c.glDepthFunc(glfw.c.GL_LESS);

    glfw.swapInterval(1);

    glfw.pollEvents();
    _ = game_window.getMouseDelta();

    try game.loop(&game_window);
}
