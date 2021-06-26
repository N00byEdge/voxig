const Chunk = @import("chunk.zig").Chunk;

pub const World = struct {
    chunk: Chunk,

    pub fn init() !@This() {
        return @This(){
            .chunk = Chunk.init(0, 0, 0),
        };
    }

    pub fn deinit(self: *@This()) void {
        self.chunk.deinit();
    }

    pub fn draw(self: *@This(), shader: anytype) void {
        self.chunk.draw(shader);
    }
};
