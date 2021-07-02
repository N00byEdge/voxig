const Chunk = @import("chunk.zig").Chunk;
const Noise = @import("../noise.zig").Noise;
const Blocks = @import("../blocks/blocks.zig");

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

    fn worldgenChunk(self: *@This(), chunk: *Chunk) void {
        var iter = chunk.iterateCoords();

        while (iter.advanceXY()) {
            const height = self.height_noise.getScaled(iter.absX(), iter.absY(), 16) + 64;

            while (iter.advanceZ()) {
                if (self.cave_noise.getScaled(iter.absX(), iter.absY(), iter.absZ(), 2) == 0 or iter.absZ() > height) {
                    const block_id = Blocks.findBlock(.air).block_id;
                    chunk.setBlock(iter.chunkX(), iter.chunkY(), iter.chunkZ(), block_id);
                } else {
                    const block_id = Blocks.findBlock(.stone).block_id;
                    chunk.setBlock(iter.chunkX(), iter.chunkY(), iter.chunkZ(), block_id);
                }
            }
        }
    }

    pub fn prepare(self: *@This()) void {
        self.worldgenChunk(&self.chunk);
    }

    pub fn draw(self: *@This(), shader: anytype) void {
        self.chunk.draw(shader);
    }
};
