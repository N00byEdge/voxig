const std = @import("std");

const chunk_mesh = @import("../chunk_mesh.zig");
const ChunkMeshBuilder = chunk_mesh.ChunkMeshBuilder;
const ChunkMesh = chunk_mesh.ChunkMesh;

const VoxelShader = @import("../shaders/voxel.zig").VoxelShader;

const config = @import("config");
const chunk_size = config.chunk.size;

const log = std.log.scoped(.chunk);

pub const Chunk = struct {
    x: i32,
    y: i32,
    z: i32,

    mesh: ?ChunkMesh,
    block_ids: [chunk_size][chunk_size][chunk_size]u8,

    mesh_data_alloc: std.heap.StackFallbackAllocator(config.chunk.mesh_data_inline_capacity),
    block_data_alloc: std.heap.StackFallbackAllocator(config.chunk.block_data_inline_capacity),

    pub fn init(x: i32, y: i32, z: i32) @This() {
        return @This(){
            .x = x,
            .y = y,
            .z = z,
            .mesh = null,
            .block_ids = undefined,
            .mesh_data_alloc = std.heap.stackFallback(config.chunk.mesh_data_inline_capacity, std.heap.page_allocator),
            .block_data_alloc = std.heap.stackFallback(config.chunk.block_data_inline_capacity, std.heap.page_allocator),
        };
    }

    pub fn deinit(self: *@This()) void {
        if (self.mesh) |*m| {
            m.deinit(self.mesh_data_alloc.get());
        }
    }

    pub fn invalidateMesh(self: *@This()) void {
        self.mesh = null;
    }

    pub fn generateMesh(self: *@This()) !void {
        var mesh_builder = try ChunkMeshBuilder.init(self.mesh_data_alloc.get(), 2);
        errdefer mesh_builder.deinit();

        @import("../blocks/blocks.zig").findBlock(.grass).block_type.addToMesh(.{
            .mesh = &mesh_builder,
            .x = 0,
            .y = 0,
            .z = 0,
            .draw_top = true,
            .draw_bottom = true,
            .draw_north = true,
            .draw_south = true,
            .draw_west = true,
            .draw_east = true,
        });

        @import("../blocks/blocks.zig").findBlock(.barrier).block_type.addToMesh(.{
            .mesh = &mesh_builder,
            .x = 2,
            .y = 0,
            .z = 0,
            .draw_top = true,
            .draw_bottom = true,
            .draw_north = true,
            .draw_south = true,
            .draw_west = true,
            .draw_east = true,
        });

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
