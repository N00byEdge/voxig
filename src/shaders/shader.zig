const zgl = @import("zgl");
const glm = @import("glm");
const std = @import("std");

const log = std.log.scoped(.shader);

pub const Shader = struct {
    vs: zgl.Shader,
    fs: zgl.Shader,
    prog: zgl.Program,

    pub fn init(comptime path: []const u8) !@This() {
        var retval: @This() = undefined;

        log.info("Loading shader '" ++ path ++ "'", .{});

        try retval.initWithSource(
            @embedFile(path ++ ".vert"),
            @embedFile(path ++ ".frag"),
        );
        errdefer retval.deinit();

        return retval;
    }

    pub fn initWithSource(self: *@This(), vert_source: []const u8, frag_source: []const u8) !void {
        self.vs = zgl.Shader.create(.vertex);
        errdefer self.vs.delete();

        log.info("Compiling vertex shader", .{});

        self.vs.source(1, &[_][]const u8{vert_source});
        self.vs.compile();

        self.fs = zgl.Shader.create(.fragment);
        errdefer self.fs.delete();

        log.info("Compiling fragment shader", .{});

        self.fs.source(1, &[_][]const u8{frag_source});
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

    pub fn assertLocation(self: *const @This(), expected: u32, name: [:0]const u8) void {
        if (std.debug.runtime_safety) {
            const actual = self.prog.uniformLocation(name).?;
            if (actual != expected)
                unreachable;
        }
    }

    pub fn deinit(self: *const @This()) void {
        self.prog.detach(self.fs);
        self.prog.detach(self.vs);
        self.prog.delete();
        self.fs.delete();
        self.vs.delete();
    }

    pub fn use(self: *const @This()) void {
        self.prog.use();
    }
};
