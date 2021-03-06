const std = @import("std");
const config = @import("config");
const rbtree = @import("rbtree");

const Chunk = @import("chunk.zig").Chunk;
const Noise = @import("../noise.zig").Noise;
const Blocks = @import("../blocks/blocks.zig");

const log = std.log.scoped(.world);

var chunk_allocator = std.heap.GeneralPurposeAllocator(.{
    .thread_safe = false,
}){
    .backing_allocator = std.heap.page_allocator,
};

const chunks_features = rbtree.Features{
    .enable_iterators_cache = false,
    .enable_kth_queries = false,
    .enable_not_associatve_augment = false,
};

const ChunkNode = struct {
    node: rbtree.Node(chunks_features) = undefined,
    refcount: usize = 1,
    chunk: Chunk,

    pub fn deinit(self: *@This()) void {
        self.chunk.deinit();
    }
};

const chunk_config = rbtree.Config{
    .augment_callback = null,
    .comparator = Chunk.ChunkComparator(ChunkNode),
    .features = chunks_features,
};

const ChunkTreeType = rbtree.Tree(ChunkNode, "node", chunk_config);

pub const World = struct {
    // Chunk rbtree
    chunks: ChunkTreeType = ChunkTreeType.init(chunk_config.comparator{}, undefined),

    // Worldgen noises
    height_noise: Noise(2) = Noise(2).init(7, 0xeffc2cd2),
    cave_noise: Noise(3) = Noise(3).init(4, 0xbd191214),

    pub fn init() !@This() {
        return @This(){};
    }

    pub fn deinit(self: *@This()) void {
        // If there are any chunks left in the rbtree, something is wrong.
        if (self.chunks.root) |_| {
            @panic("World.deinit: Chunks still ref'd!");
        }
    }

    fn findLoadedChunk(self: *@This(), x: i32, y: i32, z: i32) ?*ChunkNode {
        const finder = Chunk.ChunkFinder(ChunkNode).init(x, y, z);

        const opt_node = self.chunks.lowerBound(@TypeOf(finder), &finder);

        if (opt_node) |chunk_node| {
            if (chunk_node.chunk.x == x and chunk_node.chunk.y == y and chunk_node.chunk.z == z) {
                return chunk_node;
            }
        }

        return null;
    }

    fn notify(unchanged: *Chunk, changed: ?*Chunk, firstToSecond: fn (*Chunk, ?*Chunk) void, secondToFirst: fn (*Chunk, ?*Chunk) void) void {
        firstToSecond(unchanged, changed);
        if (changed) |started_existing| {
            secondToFirst(started_existing, unchanged);
        }
    }

    fn notifyAdjacentChunks(self: *@This(), x: i32, y: i32, z: i32, changed: ?*Chunk) void {
        if (self.findLoadedChunk(x + 32, y, z)) |eastern| notify(&eastern.chunk, changed, Chunk.notifyChunkWest, Chunk.notifyChunkEast);
        if (self.findLoadedChunk(x - 32, y, z)) |western| notify(&western.chunk, changed, Chunk.notifyChunkEast, Chunk.notifyChunkWest);
        if (self.findLoadedChunk(x, y - 32, z)) |northern| notify(&northern.chunk, changed, Chunk.notifyChunkNorth, Chunk.notifyChunkSouth);
        if (self.findLoadedChunk(x, y + 32, z)) |southern| notify(&southern.chunk, changed, Chunk.notifyChunkSouth, Chunk.notifyChunkNorth);
        if (self.findLoadedChunk(x, y, z - 32)) |below| notify(&below.chunk, changed, Chunk.notifyChunkAbove, Chunk.notifyChunkBelow);
        if (self.findLoadedChunk(x, y, z + 32)) |above| notify(&above.chunk, changed, Chunk.notifyChunkBelow, Chunk.notifyChunkAbove);
    }

    pub fn refChunk(self: *@This(), x: i32, y: i32, z: i32) !*Chunk {
        if (self.findLoadedChunk(x, y, z)) |chunk_node| {
            // Found existing chunk
            const new_refcount = @atomicRmw(usize, &chunk_node.refcount, .Add, 1, .AcqRel) + 1;
            if (new_refcount < 2) {
                @panic("World.refChunk: new_refcount too low!");
            }
            return &chunk_node.chunk;
        }

        // Make a new one
        const chunk_node = try chunk_allocator.allocator.create(ChunkNode);
        chunk_node.* = .{
            .chunk = Chunk.init(x, y, z),
        };

        self.worldgenChunk(&chunk_node.chunk);

        self.notifyAdjacentChunks(chunk_node.chunk.x, chunk_node.chunk.y, chunk_node.chunk.z, &chunk_node.chunk);

        self.chunks.insert(chunk_node);
        return &chunk_node.chunk;
    }

    pub fn unrefChunk(self: *@This(), chunk: *Chunk) void {
        const chunk_node = @fieldParentPtr(ChunkNode, "chunk", chunk);
        const new_refcount = @atomicRmw(usize, &chunk_node.refcount, .Sub, 1, .AcqRel) - 1;
        if (new_refcount == 0) {
            self.notifyAdjacentChunks(chunk_node.chunk.x, chunk_node.chunk.y, chunk_node.chunk.z, null);
            self.chunks.remove(chunk_node);
            chunk_node.deinit();
            chunk_allocator.allocator.destroy(chunk_node);
        }
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
};
