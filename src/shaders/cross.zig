const Shader = @import("shader.zig").Shader;

pub const CrossShader = struct {
    shader: Shader,

    pub fn init() !@This() {
        const retval: @This() = .{
            .shader = try Shader.init("cross"),
        };

        retval.shader.assertLocation(0, "aspect_ratio");

        return retval;
    }

    pub fn deinit(self: *@This()) void {
        self.shader.deinit();
    }

    pub fn use(self: *@This()) void {
        self.shader.use();
    }

    pub fn aspectRatio(self: *@This(), ratio: f32) void {
        self.shader.prog.uniform1f(0, ratio);
    }
};
