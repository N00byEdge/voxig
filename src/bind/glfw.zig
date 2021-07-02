pub const c = @cImport({
    @cInclude("epoxy/gl.h");
    @cInclude("GLFW/glfw3.h");
});

const std = @import("std");
const config = @import("config");

const log = std.log.scoped(.glfw);

const disable_mouse_input = false;

pub const Window = struct {
    win: *c.GLFWwindow,
    width: c_int,
    height: c_int,
    aspect_ratio: f32,

    fn framebufferSizeCallback(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
        if (window) |win| {
            const self = @ptrCast(*@This(), @alignCast(8, c.glfwGetWindowUserPointer(win)));

            self.makeContextCurrent();
            c.glViewport(0, 0, width, height);

            self.width = width;
            self.height = height;
            self.aspect_ratio = aspectRatio(width, height);

            _ = self.getMouseDelta();
        }
    }

    fn aspectRatio(width: c_int, height: c_int) f32 {
        return @intToFloat(f32, width) / @intToFloat(f32, height);
    }

    pub fn init(self: *@This(), width: c_int, height: c_int, title: [*:0]const u8) void {
        self.win = c.glfwCreateWindow(width, height, title, null, null).?;
        errdefer c.glfwDestroyWindow(self.win);

        self.width = width;
        self.height = height;
        self.aspect_ratio = aspectRatio(width, height);

        c.glfwSetWindowUserPointer(self.win, self);
        _ = c.glfwSetFramebufferSizeCallback(self.win, framebufferSizeCallback);

        if (comptime (!disable_mouse_input)) {
            c.glfwSetInputMode(self.win, c.GLFW_CURSOR, c.GLFW_CURSOR_DISABLED);

            if (c.glfwRawMouseMotionSupported() == c.GLFW_TRUE) {
                log.info("Raw mouse input enabled", .{});
                c.glfwSetInputMode(self.win, c.GLFW_RAW_MOUSE_MOTION, c.GLFW_TRUE);
            }
        }
    }

    pub fn deinit(self: *@This()) void {
        c.glfwDestroyWindow(self.win);
    }

    pub fn configKeyPressed(self: *@This(), comptime tag: anytype) bool {
        const key_name = @tagName(@field(config.keys, @tagName(tag)));
        const state = c.glfwGetKey(self.win, @field(c, key_name));
        return state == c.GLFW_PRESS;
    }

    pub fn getMouseDelta(self: *@This()) struct { dx: f64, dy: f64 } {
        if (comptime (disable_mouse_input)) {
            return .{
                .dx = 0,
                .dy = 0,
            };
        }

        var dx: f64 = undefined;
        var dy: f64 = undefined;
        c.glfwGetCursorPos(self.win, &dx, &dy);
        c.glfwSetCursorPos(self.win, 0, 0);

        return .{
            .dx = dx,
            .dy = dy,
        };
    }

    pub fn makeContextCurrent(self: *@This()) void {
        c.glfwMakeContextCurrent(self.win);
    }

    pub fn swapBuffers(self: *@This()) void {
        c.glfwSwapBuffers(self.win);
    }

    pub fn shouldClose(self: *@This()) bool {
        return switch (c.glfwWindowShouldClose(self.win)) {
            c.GLFW_TRUE => true,
            c.GLFW_FALSE => false,
            else => unreachable,
        };
    }
};

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
pub fn swapInterval(interval: c_int) void {
    c.glfwSwapInterval(interval);
}
pub fn pollEvents() void {
    c.glfwPollEvents();
}
