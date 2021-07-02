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
        var iter = self.chunk.iterateCoords();

        while (iter.next()) {
            if (self.cave_noise.getScaled(iter.absX(), iter.absY(), iter.absZ(), 2) == 1) {
                const block_id = @import("../blocks/blocks.zig").findBlock(.stone).block_id;
                self.chunk.setBlock(iter.chunkX(), iter.chunkY(), iter.chunkZ(), block_id);
            }
        }
    }

    pub fn draw(self: *@This(), shader: anytype) void {
        self.chunk.draw(shader);
    }
};
