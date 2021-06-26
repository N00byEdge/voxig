const Shader = @import("shader.zig").Shader;

const glm = @import("glm");
const zgl = @import("zgl");

pub const VoxelShader = struct {
    shader: Shader,

    pub fn init() !@This() {
        const retval: @This() = .{
            .shader = try Shader.init("voxel"),
        };

        retval.shader.assertLocation(0, "texture_sampler");
        retval.shader.assertLocation(1, "MVP");

        return retval;
    }

    pub fn deinit(self: *@This()) void {
        self.shader.deinit();
    }

    pub fn use(self: *@This()) void {
        self.shader.use();
    }

    pub fn texture(self: *@This(), text: zgl.Texture) void {
        self.use();
        text.bindTo(0);
    }

    pub fn camera(self: *@This(), cam: glm.Matrix(4)) void {
        self.shader.prog.uniformMatrix4(1, false, &[_][4][4]f32{cam.values});
    }
};
