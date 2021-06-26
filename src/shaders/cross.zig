const Shader = @import("shader.zig").Shader;

const zgl = @import("zgl");

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

    pub fn draw(self: *@This(), aspect_ratio: f32) void {
        self.shader.use();
        self.shader.prog.uniform1f(0, aspect_ratio);
        zgl.drawArrays(.triangles, 0, 12);
    }
};
