const Chunk = @import("chunk.zig").Chunk;
const Noise = @import("../noise.zig").Noise;

pub const World = struct {
    chunk: Chunk,
    height_noise: Noise(2),
    cave_noise: Noise(3),

    pub fn init() !@This() {
        return @This(){
            .chunk = Chunk.init(0, 0, 0),
            .height_noise = Noise(2).init(7, 0xeffc2cd2),
            .cave_noise = Noise(3).init(4, 0xbd191214),
        };
    }

    pub fn deinit(self: *@This()) void {
        self.chunk.deinit();
    }

    pub fn prepare(self: *@This()) void {
        var chunk_x: i32 = 0;
        while (chunk_x < Chunk.size) : (chunk_x += 1) {
            var chunk_y: i32 = 0;
            while (chunk_y < Chunk.size) : (chunk_y += 1) {
                var chunk_z: i32 = 0;
                while (chunk_z < Chunk.size) : (chunk_z += 1) {
                    if (self.cave_noise.getScaled(self.chunk.x + chunk_x, self.chunk.y + chunk_y, self.chunk.z + chunk_z, 2) == 1) {
                        const block_id = @import("../blocks/blocks.zig").findBlock(.stone).block_id;
                        self.chunk.setBlock(@intCast(u5, chunk_x), @intCast(u5, chunk_y), @intCast(u5, chunk_z), block_id);
                    }
                }
            }
        }
    }

    pub fn draw(self: *@This(), shader: anytype) void {
        self.chunk.draw(shader);
    }
};
