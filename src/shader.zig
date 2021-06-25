const zgl = @import("zgl");
const glm = @import("glm");
const std = @import("std");

const log = std.log.scoped(.shader);

pub const Shader = struct {
    vs: zgl.Shader,
    fs: zgl.Shader,
    prog: zgl.Program,

    pub fn init(self: *@This(), comptime path: []const u8) !void {
        log.info("Loading shader '" ++ path ++ "'", .{});

        self.vs = zgl.Shader.create(.vertex);
        errdefer self.vs.delete();

        log.info("Compiling vertex shader", .{});

        self.vs.source(1, &[_][]const u8{@embedFile("shaders/" ++ path ++ ".vs")});
        self.vs.compile();

        self.fs = zgl.Shader.create(.fragment);
        errdefer self.fs.delete();

        log.info("Compiling fragment shader", .{});

        self.fs.source(1, &[_][]const u8{@embedFile("shaders/" ++ path ++ ".fs")});
        self.fs.compile();

        log.info("Creating program", .{});

        self.prog = zgl.Program.create();
        errdefer self.prog.delete();

        self.prog.attach(self.vs);
        errdefer self.prog.detach(self.vs);

        self.prog.attach(self.fs);
        errdefer self.prog.detach(self.fs);

        log.info("Linking program", .{});

        self.prog.link();

        log.info("Linked program", .{});

        {
            const compilation_log = try self.prog.getCompileLog(std.heap.page_allocator);
            if (compilation_log.len > 0)
                log.info("Compilation log\n\n{s}", .{compilation_log});
            std.heap.page_allocator.free(compilation_log);
        }

        self.prog.use();
    }

    pub fn bindTexture(self: *@This(), texture: zgl.Texture) void {
        const text_slot = self.prog.uniformLocation("texture_sampler").?;
        log.info("Binding texture {} to {}", .{ texture, text_slot });
        texture.bindTo(text_slot);
    }

    pub fn deinit(self: *@This()) void {
        self.prog.detach(self.fs);
        self.prog.detach(self.vs);
        self.prog.delete();
        self.fs.delete();
        self.vs.delete();
    }

    pub fn bind(self: *@This()) void {
        self.prog.use();
    }

    pub fn camera(self: *@This(), cam: glm.Matrix(4)) void {
        self.prog.uniformMatrix4(1, false, &[_][4][4]f32{cam.values});
    }
};
