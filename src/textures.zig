const logger = @import("logger");
const std = @import("std");
const zgl = @import("zgl");

const log = std.log.scoped(.textures);

// Public interface

pub fn init() zgl.Texture {
    log.info("Creating texture atlas", .{});
    const atlas = zgl.Texture.create(.@"2d_array");
    atlas.parameter(.wrap_s, .repeat);
    atlas.parameter(.wrap_t, .repeat);
    atlas.parameter(.min_filter, .nearest);
    atlas.parameter(.mag_filter, .nearest);
    log.info("Allocating texture atlas", .{});
    atlas.storage3D(1, .rgba8, texture_dim, texture_dim, textures.len);
    log.info("Loading texture atlas: {any}", .{atlas});
    atlas.subImage3D(0, 0, 0, 0, texture_dim, texture_dim, textures.len, .rgba, .unsigned_int_8_8_8_8_rev, array_texture.ptr);

    return atlas;
}

pub fn findTexture(comptime tag: anytype) *const Texture {
    inline for (textures) |*text| {
        if (comptime std.mem.eql(u8, text.name, @tagName(tag)))
            return text;
    }

    @compileError("Texture not found!");
}

pub const Texture = struct {
    index: comptime_int,
    texture_coord: comptime_float,
    name: comptime []const u8,
};

// Implementation

const texture_dim = @import("config").textures.dim;

const atlas_texture_list = .{
    .stone = .block,
    .barrier = .block,
    .dirt = .block,
    .grass_side = .block,
    .grass = .block,
};

const textures = {
    comptime var result: []const Texture = &[_]Texture{};

    inline for (@typeInfo(@TypeOf(atlas_texture_list)).Struct.fields) |decl, i| {
        result = result ++ [1]Texture{.{
            .index = i,
            .texture_coord = @as(f32, i) + 0.5,
            .name = decl.name,
        }};
    }

    return result;
};

const array_texture = {
    comptime var result: []const u8 = &[_]u8{};

    inline for (@typeInfo(@TypeOf(atlas_texture_list)).Struct.fields) |decl, i| {
        const data = @embedFile("../res/" ++ @tagName(@field(atlas_texture_list, decl.name)) ++ "s/" ++ decl.name ++ ".data");
        result = result ++ @as(*const [texture_dim * texture_dim * 4]u8, data);
    }

    return result;
};
