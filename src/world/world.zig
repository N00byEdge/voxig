const std = @import("std");
const config = @import("config");
const rbtree = @import("rbtree");

const Chunk = @import("chunk.zig").Chunk;
const Noise = @import("../noise.zig").Noise;
const Blocks = @import("../blocks/blocks.zig");

const log = std.log.scoped(.world);

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

const ChunkComparator = struct {
    pub fn compare(_: *const @This(), lhs: *const ChunkNode, rhs: *const ChunkNode) bool {
        if (lhs.chunk.x < rhs.chunk.x) return true;
        if (lhs.chunk.x > rhs.chunk.x) return false;

        if (lhs.chunk.y < rhs.chunk.y) return true;
        if (lhs.chunk.y > rhs.chunk.y) return false;

        if (lhs.chunk.z < rhs.chunk.z) return true;
        return false;
    }
};

const chunk_config = rbtree.Config{
    .augment_callback = null,
    .comparator = ChunkComparator,
    .features = chunks_features,
};

const ChunkFinder = struct {
    x: i32,
    y: i32,
    z: i32,

    pub fn init(x: i32, y: i32, z: i32) @This() {
        return .{
            .x = x,
            .y = y,
            .z = z,
        };
    }

    pub fn check(self: *const @This(), cn: *const ChunkNode) bool {
        return cn.chunk.x >= self.x and cn.chunk.y >= self.y and cn.chunk.z >= self.z;
    }
};

const ChunkTreeType = rbtree.Tree(ChunkNode, "node", chunk_config);

pub const World = struct {
    // Chunk rbtree
    chunks: ChunkTreeType,

    // Worldgen noises
    height_noise: Noise(2),
    cave_noise: Noise(3),

    chunk_allocator: std.heap.StackFallbackAllocator(config.world.world_inline_chunk_capacity),

    pub fn init() !@This() {
        return @This(){
            .chunks = ChunkTreeType.init(ChunkComparator{}, undefined),

            .height_noise = Noise(2).init(7, 0xeffc2cd2),
            .cave_noise = Noise(3).init(4, 0xbd191214),

            .chunk_allocator = std.heap.stackFallback(config.world.world_inline_chunk_capacity, std.heap.page_allocator),
        };
    }

    pub fn deinit(self: *@This()) void {
        // If there are any chunks left in the rbtree, something is wrong.
        if (self.chunks.root) |_| {
            @panic("World.deinit: Chunks still ref'd!");
        }
    }

    fn findLoadedChunk(self: *@This(), x: i32, y: i32, z: i32) ?*ChunkNode {
        const finder = ChunkFinder.init(x, y, z);

        const opt_node = self.chunks.lowerBound(ChunkFinder, &finder);

        if (opt_node) |chunk_node| {
            if (chunk_node.chunk.x == x and chunk_node.chunk.y == y and chunk_node.chunk.z == z) {
                return chunk_node;
            }
        }

        return null;
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
        const chunk_node = try self.chunk_allocator.get().create(ChunkNode);
        chunk_node.* = .{
            .chunk = Chunk.init(x, y, z),
        };

        self.worldgenChunk(&chunk_node.chunk);

        self.chunks.insert(chunk_node);
        return &chunk_node.chunk;
    }

    pub fn unrefChunk(self: *@This(), chunk: *Chunk) void {
        const chunk_node = @fieldParentPtr(ChunkNode, "chunk", chunk);
        const new_refcount = @atomicRmw(usize, &chunk_node.refcount, .Sub, 1, .AcqRel) - 1;
        if (new_refcount == 0) {
            self.chunks.remove(chunk_node);
            chunk_node.deinit();
            self.chunk_allocator.get().destroy(chunk_node);
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
