pub const c = @cImport({
    @cInclude("epoxy/gl.h");
    @cInclude("GLFW/glfw3.h");
});

const std = @import("std");
const log = std.log.scoped(.glfw);
const textures = @import("../textures.zig");

fn errorCallback(err: c_int, desc: [*c]const u8) callconv(.C) void {
    log.err("Got GLFW error: 0x{X} with description {s}!", .{ err, desc });
    @panic("GLFW error");
}

pub fn init() !void {
    const ret = c.glfwInit();

    switch (ret) {
        c.GLFW_TRUE => {},
        c.GLFW_FALSE => return error.glfwInitError,
        else => unreachable,
    }

    _ = c.glfwSetErrorCallback(errorCallback);

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 2);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 0);

    log.info("Initialized", .{});
}

pub fn terminate() void {
    c.glfwTerminate();
}

fn framebufferSizeCallback(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    c.glViewport(0, 0, width, height);
}

pub fn createWindow(
    width: c_int,
    height: c_int,
    title: [*c]const u8,
    monitor: ?*c.GLFWmonitor,
    share: ?*c.GLFWwindow,
) *c.GLFWwindow {
    const window = @ptrCast(*c.GLFWwindow, c.glfwCreateWindow(width, height, title, monitor, share));
    _ = c.glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);
    return window;
}

pub fn destroyWindow(window: *c.GLFWwindow) void {
    c.glfwDestroyWindow(window);
}
pub fn makeContextCurrent(window: *c.GLFWwindow) void {
    c.glfwMakeContextCurrent(window);
}
pub fn windowShouldClose(window: *c.GLFWwindow) bool {
    return switch (c.glfwWindowShouldClose(window)) {
        c.GLFW_TRUE => true,
        c.GLFW_FALSE => false,
        else => unreachable,
    };
}
pub fn swapInterval(interval: c_int) void {
    c.glfwSwapInterval(interval);
}
pub fn swapBuffers(window: *c.GLFWwindow) void {
    c.glfwSwapBuffers(window);
}
pub fn pollEvents() void {
    c.glfwPollEvents();
}
pub fn getWindowSize(window: *c.GLFWwindow) [2]c_int {
    var result: [2]c_int = undefined;
    c.glfwGetWindowSize(window, &result[0], &result[1]);
    return result;
}
