const std = @import("std");
const config = @import("config");

const zgl = @import("zgl");

const gl = @import("bind/glfw.zig").c;

const log = std.log.scoped(.chunk_mesh);

const values_per_block = 6;

pub const ChunkMeshBuilder = struct {
    verts: std.ArrayListUnmanaged(i32),
    num: usize = 0,

    pub fn init(allocator: *std.mem.Allocator, block_capacity: usize) !@This() {
        return @This(){
            .verts = try std.ArrayListUnmanaged(i32).initCapacity(allocator, block_capacity * values_per_block * 4),
        };
    }

    pub fn deinit(self: *@This(), allocator: *std.mem.Allocator) void {
        self.verts.deinit(allocator);
    }

    pub fn add(self: *@This(), add_verts: []const i32) void {
        self.verts.appendSliceAssumeCapacity(add_verts);
        self.num += 1;
    }

    pub fn finalize(self: *@This(), allocator: *std.mem.Allocator) !ChunkMesh {
        var result: ChunkMesh = undefined;

        result.num = self.num;

        result.verts = self.verts.toOwnedSlice(allocator);
        errdefer self.verts.items = ArrayList(i32).fromOwnedSlice(result.verts).toUnmanaged();

        result.vao = zgl.createVertexArray();
        errdefer zgl.deleteVertexArray(result.vao);

        result.vao.bind();

        result.buffer = zgl.Buffer.create();
        errdefer result.buffer.delete();

        result.buffer.bind(.array_buffer);
        result.buffer.data(i32, result.verts, .static_draw);

        result.vao.enableVertexAttribute(0);
        result.vao.vertexBuffer(0, result.buffer, 0, 4);
        result.vao.attribIFormat(0, 1, .int, 0);
        result.vao.attribBinding(0, 0);
        gl.glVertexArrayBindingDivisor(@enumToInt(result.vao), 0, 1);

        //log.info("Finalized chunk mesh: {any}", .{result});

        return result;
    }
};

pub const ChunkMesh = struct {
    verts: []i32,
    num: usize,
    buffer: zgl.Buffer,
    vao: zgl.VertexArray,

    pub fn deinit(self: *const @This(), allocator: *std.mem.Allocator) void {
        self.buffer.delete();
        allocator.free(self.verts);
        zgl.deleteVertexArray(self.vao);
    }

    pub fn draw(self: *const @This()) void {
        self.vao.bind();
        gl.glDrawArraysInstanced(gl.GL_TRIANGLES, 0, 6, @intCast(gl.GLsizei, self.num));
    }
};
