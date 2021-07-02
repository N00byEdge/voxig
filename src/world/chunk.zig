const std = @import("std");

const chunk_mesh = @import("../chunk_mesh.zig");
const ChunkMeshBuilder = chunk_mesh.ChunkMeshBuilder;
const ChunkMesh = chunk_mesh.ChunkMesh;

const VoxelShader = @import("../shaders/voxel.zig").VoxelShader;

const config = @import("config");
const chunk_size = config.chunk.size;

const log = std.log.scoped(.chunk);

const CoordIterator = struct {
    abs_x: i32,
    abs_y: i32,
    abs_z: i32,

    chunk_x: i32,
    chunk_y: i32,
    chunk_z: i32,

    pub fn init(abs_x: i32, abs_y: i32, abs_z: i32) @This() {
        return .{
            .abs_x = abs_x,
            .abs_y = abs_y,
            .abs_z = abs_z,

            .chunk_x = 0,
            .chunk_y = 0,
            .chunk_z = 0,
        };
    }

    pub fn advanceZ(self: *@This()) bool {
        self.chunk_z += 1;
        self.abs_z += 1;
        if (self.chunk_z == chunk_size) {
            self.abs_z -= self.chunk_z;
            self.chunk_z = 0;
            return false;
        }
        return true;
    }

    pub fn advanceY(self: *@This()) bool {
        self.chunk_y += 1;
        self.abs_y += 1;
        if (self.chunk_y == chunk_size) {
            self.abs_y -= self.chunk_y;
            self.chunk_y = 0;
            return false;
        }
        return true;
    }

    pub fn advanceX(self: *@This()) bool {
        self.chunk_x += 1;
        self.abs_x += 1;
        if (self.chunk_x == chunk_size) {
            self.abs_x -= self.chunk_x;
            self.chunk_x = 0;
            return false;
        }
        return true;
    }

    pub fn advanceXYZ(self: *@This()) bool {
        return self.advanceX() or self.advanceY() or self.advanceZ();
    }

    pub fn advanceXY(self: *@This()) bool {
        return self.advanceX() or self.advanceY();
    }

    pub fn chunkX(self: *const @This()) u5 {
        return @intCast(u5, self.chunk_x);
    }

    pub fn chunkY(self: *const @This()) u5 {
        return @intCast(u5, self.chunk_y);
    }

    pub fn chunkZ(self: *const @This()) u5 {
        return @intCast(u5, self.chunk_z);
    }

    pub fn absX(self: *const @This()) i32 {
        return self.abs_x;
    }

    pub fn absY(self: *const @This()) i32 {
        return self.abs_y;
    }

    pub fn absZ(self: *const @This()) i32 {
        return self.abs_z;
    }
};

pub const Chunk = struct {
    x: i32,
    y: i32,
    z: i32,

    mesh: ?ChunkMesh,
    block_ids: [chunk_size][chunk_size][chunk_size]u8,

    mesh_data_alloc: std.heap.StackFallbackAllocator(config.chunk.mesh_data_inline_capacity),
    //block_data_alloc: std.heap.StackFallbackAllocator(config.chunk.block_data_inline_capacity),

    pub const size = chunk_size;

    pub fn init(x: i32, y: i32, z: i32) @This() {
        return @This(){
            .x = x,
            .y = y,
            .z = z,
            .mesh = null,
            .block_ids = undefined,
            .mesh_data_alloc = std.heap.stackFallback(config.chunk.mesh_data_inline_capacity, std.heap.page_allocator),
            //.block_data_alloc = std.heap.stackFallback(config.chunk.block_data_inline_capacity, std.heap.page_allocator),
        };
    }

    pub fn setBlock(self: *@This(), x: u5, y: u5, z: u5, block_id: u8) void {
        self.block_ids[x][y][z] = block_id;
    }

    pub fn deinit(self: *@This()) void {
        if (self.mesh) |*m| {
            m.deinit(self.mesh_data_alloc.get());
        }
    }

    pub fn invalidateMesh(self: *@This()) void {
        self.mesh = null;
    }

    pub fn iterateCoords(self: *@This()) CoordIterator {
        return CoordIterator.init(self.x, self.y, self.z);
    }

    pub fn generateMesh(self: *@This()) !void {
        var mesh_builder = try ChunkMeshBuilder.init(self.mesh_data_alloc.get(), chunk_size * chunk_size * chunk_size);
        errdefer mesh_builder.deinit();

        var chunk_x: usize = 0;
        while (chunk_x < chunk_size) : (chunk_x += 1) {
            var chunk_y: usize = 0;
            while (chunk_y < chunk_size) : (chunk_y += 1) {
                var chunk_z: usize = 0;
                while (chunk_z < chunk_size) : (chunk_z += 1) {
                    const id = self.block_ids[chunk_x][chunk_y][chunk_z];
                    const blocks = @import("../blocks/blocks.zig").blocks;

                    // https://github.com/ziglang/zig/issues/7224
                    inline for (blocks) |blk| {
                        if (blk.block_id == id) {
                            blk.block_type.addToMesh(.{
                                .mesh = &mesh_builder,
                                .x = @intCast(u5, chunk_x),
                                .y = @intCast(u5, chunk_y),
                                .z = @intCast(u5, chunk_z),
                                .draw_top = true,
                                .draw_bottom = true,
                                .draw_north = true,
                                .draw_south = true,
                                .draw_west = true,
                                .draw_east = true,
                            });
                        }
                    }
                }
            }
        }

        self.mesh = try mesh_builder.finalize(self.mesh_data_alloc.get());
    }

    pub fn draw(self: *@This(), shader: VoxelShader) void {
        if (self.mesh == null) {
            self.generateMesh() catch |err| {
                log.err("Chunk mesh generation failed: {}", .{err});
                if (@errorReturnTrace()) |trace| {
                    std.debug.dumpStackTrace(trace.*);
                } else {
                    log.err("No error trace.", .{});
                }
                return;
            };
        }

        if (self.mesh) |m| {
            shader.chunkPos(self.x, self.y, self.z);
            m.draw();
        }
    }
};
