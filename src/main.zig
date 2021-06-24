const std = @import("std");
const glfw = @import("bind/glfw.zig");
const zgl = @import("zgl");
const game = @import("game.zig");

const log = std.log.scoped(.main);

pub fn main() anyerror!void {
    try glfw.init();
    defer glfw.terminate();

    const game_window = glfw.createWindow(640, 480, "Zig memes", null, null);
    defer glfw.destroyWindow(game_window);

    glfw.makeContextCurrent(game_window);
    glfw.swapInterval(1);

    try game.loop(game_window);
}
