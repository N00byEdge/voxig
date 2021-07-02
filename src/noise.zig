const fnl = @cImport({
    @cDefine("FNL_IMPL", "HI MOM");
    @cInclude("FastNoiseLite.h");
});

const std = @import("std");
const log = std.log.scoped(.noise);

pub fn Noise(comptime dim: comptime_int) type {
    return struct {
        fnl_obj: fnl.fnl_state,

        const NoiseType = @This();

        pub fn init(octaves: usize, seed: u32) @This() {
            var fnl_obj = fnl.fnlCreateState();

            fnl_obj.octaves = @intCast(c_int, octaves);
            fnl_obj.seed = @bitCast(c_int, seed);

            return .{
                .fnl_obj = fnl_obj,
            };
        }

        // Returns [-1,1]
        pub const get = switch (dim) {
            2 => struct {
                pub fn f(self: *NoiseType, x: i32, y: i32) f32 {
                    return fnl.fnlGetNoise2D(&self.fnl_obj, @intToFloat(f32, x), @intToFloat(f32, y));
                }
            }.f,
            3 => struct {
                pub fn f(self: *NoiseType, x: i32, y: i32, z: i32) f32 {
                    return fnl.fnlGetNoise3D(&self.fnl_obj, @intToFloat(f32, x), @intToFloat(f32, y), @intToFloat(f32, z));
                }
            }.f,
            else => @compileError("Unknown dim"),
        };

        fn scaleNoise(f: f32, scale: u32) u32 {
            return @floatToInt(u32, ((f + 1) / 2) * @intToFloat(f32, scale));
        }

        // Returns [0,scale]
        pub const getScaled = switch (dim) {
            2 => struct {
                pub fn f(self: *NoiseType, x: i32, y: i32) f32 {
                    return scaleNoise(self.get(x, y), scale);
                }
            }.f,
            3 => struct {
                pub fn f(self: *NoiseType, x: i32, y: i32, z: i32, scale: u32) u32 {
                    return scaleNoise(self.get(x, y, z), scale);
                }
            }.f,
            else => @compileError("Unknown dim"),
        };
    };
}
