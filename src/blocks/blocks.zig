const std = @import("std");
const config = @import("config");
const textures = @import("../textures.zig");

const Mesh = @import("../chunk_mesh.zig").ChunkMeshBuilder;

const log = std.log.scoped(.blocks);

fn genQuad(mesh: *Mesh, attribute: i32, x: i32, y: i32, z: i32) callconv(.Inline) void {
    mesh.add(&[_]i32{
        x, y, z, attribute,
    });
}

fn BlockFace(comptime tag: anytype, comptime lighting: f32) type {
    const texture = textures.findTexture(tag);

    return struct {
        pub fn generate(
            mesh: *Mesh,
            comptime side: anytype,
            x: i32,
            y: i32,
            z: i32,
        ) callconv(.Inline) void {
            const direction: u8 = switch (comptime side) {
                .top => 0,
                .bottom => 1,
                .west => 2,
                .east => 3,
                .north => 4,
                .south => 5,
                else => @compileError("Invalid face"),
            };

            const attribute: i32 = 0 //
            | (@intCast(u32, @intCast(u8, texture.index)) << 8) // Texture index field
            | (@intCast(u32, direction) << 0) // Direction field
            ;

            log.info("Attribute int 0x{X} for dir {}, texture {}", .{ attribute, direction, texture.index });

            genQuad(mesh, attribute, x, y, z);
        }
    };
}

// Basic blocks have no state nor facing direction
pub fn BasicBlock(
    comptime top: anytype,
    comptime bottom: anytype,
    comptime front: anytype,
    comptime back: anytype,
    comptime left: anytype,
    comptime right: anytype,
) type {
    return struct {
        pub fn addToMesh(args: struct {
            mesh: *Mesh,
            x: i32,
            y: i32,
            z: i32,
            draw_top: bool,
            draw_bottom: bool,
            draw_north: bool,
            draw_south: bool,
            draw_west: bool,
            draw_east: bool,
        }) void {
            if (args.draw_top)
                BlockFace(top, 1.0).generate(args.mesh, .top, args.x, args.y, args.z);

            if (args.draw_bottom)
                BlockFace(bottom, 0.6).generate(args.mesh, .bottom, args.x, args.y, args.z);

            if (args.draw_north)
                BlockFace(front, 0.8).generate(args.mesh, .north, args.x, args.y, args.z);

            if (args.draw_south)
                BlockFace(back, 0.8).generate(args.mesh, .south, args.x, args.y, args.z);

            if (args.draw_west)
                BlockFace(left, 0.8).generate(args.mesh, .west, args.x, args.y, args.z);

            if (args.draw_east)
                BlockFace(right, 0.8).generate(args.mesh, .east, args.x, args.y, args.z);
        }

        fn cornerVertex(self: *const @This(), mesh: *Mesh, cond: bool, x: i32, y: i32, z: i32) Mesh.VertexID {
            if (comptime (config.conditional_vertices) or cond) {
                return mesh.addVertex(x, y, z);
            }
            return undefined;
        }
    };
}

fn BasicBlockTopBottomSides(
    comptime top: anytype,
    comptime bottom: anytype,
    comptime sides: anytype,
) type {
    return BasicBlock(top, bottom, sides, sides, sides, sides);
}

fn BasicBlockSingleText(
    comptime all: anytype,
) type {
    return BasicBlock(all, all, all, all, all, all);
}

pub const Block = struct {
    block_id: comptime_int,
    block_type: type,
    name: []const u8,
};

const Transparent = struct {
    pub fn addToMesh(_: anytype) void {}
};

const block_list = .{
    .air = Transparent,
    .stone = BasicBlockSingleText(.stone),
    .dirt = BasicBlockSingleText(.dirt),
    .grass = BasicBlockTopBottomSides(.grass, .dirt, .grass_side),
    .barrier = BasicBlockSingleText(.barrier),
    //.iron_ore = BasicBlockSingleText(.iron_ore),
};

const blocks = {
    comptime var result: []const Block = &[_]Block{};

    inline for (@typeInfo(@TypeOf(block_list)).Struct.fields) |decl, i| {
        result = result ++ [1]Block{.{
            .block_id = i,
            .block_type = @field(block_list, decl.name),
            .name = decl.name,
        }};
    }

    return result;
};

pub fn findBlock(comptime tag: anytype) *const Block {
    inline for (blocks) |*blk| {
        if (comptime std.mem.eql(u8, blk.name, @tagName(tag)))
            return blk;
    }

    @compileError("Cannot find block");
}
