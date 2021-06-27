const std = @import("std");
const config = @import("config");
const textures = @import("../textures.zig");

const Mesh = @import("../chunk_mesh.zig").ChunkMeshBuilder;

const log = std.log.scoped(.blocks);

fn genFace(
    mesh: *Mesh,
    direction: u8,
    texture: u8,
    x: u5,
    y: u5,
    z: u5,
) void {
    const attribute: i32 = 0 //
    | (@intCast(i32, direction) << 0) // Direction field
    | (@intCast(i32, @intCast(u8, texture)) << 8) // Texture index field
    | (@intCast(i32, x) << 16) // x
    | (@intCast(i32, y) << 21) // y
    | (@intCast(i32, z) << 26) // z
    ;

    mesh.add(&[_]i32{attribute});
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
            x: u5,
            y: u5,
            z: u5,
            draw_top: bool,
            draw_bottom: bool,
            draw_north: bool,
            draw_south: bool,
            draw_west: bool,
            draw_east: bool,
        }) void {
            if (args.draw_top)
                genFace(args.mesh, 0, textures.find(top).index, args.x, args.y, args.z);

            if (args.draw_bottom)
                genFace(args.mesh, 1, textures.find(bottom).index, args.x, args.y, args.z);

            if (args.draw_west)
                genFace(args.mesh, 2, textures.find(left).index, args.x, args.y, args.z);

            if (args.draw_east)
                genFace(args.mesh, 3, textures.find(right).index, args.x, args.y, args.z);

            if (args.draw_north)
                genFace(args.mesh, 4, textures.find(back).index, args.x, args.y, args.z);

            if (args.draw_south)
                genFace(args.mesh, 5, textures.find(front).index, args.x, args.y, args.z);
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
