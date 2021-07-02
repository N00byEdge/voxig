const glm = @import("glm");
const std = @import("std");
const config = @import("config");

const World = @import("world/world.zig").World;
const VoxelShader = @import("shaders/voxel.zig").VoxelShader;

const log = std.log.scoped(.player);

const ivec3 = struct {
    x: i32,
    y: i32,
    z: i32,
};

// A player keeps track of the chunks it references
pub const Player = struct {
    // We keep track of the fractional positions separately so that we can
    // translate all blocks with integer positions for everything except the
    // fractional position (which is done with floats)

    x: i32 = 1,
    x_frac: f32 = 0.5,
    y: i32 = -1,
    y_frac: f32 = -0.5,
    z: i32 = 2,
    z_frac: f32 = 0,

    velocity: glm.Vector(3) = glm.Vector(3).init([_]f32{ 0, 0, 0 }),

    look_x: f32 = @as(f32, std.math.pi) / 2,
    look_z: f32 = -0.4,

    world: *World,

    forward: glm.Vector(3) = undefined,
    right: glm.Vector(3) = undefined,

    camera: glm.Matrix(4) = undefined,

    pub fn init(world: *World) @This() {
        return .{
            .world = world,
        };
    }

    pub fn deinit(self: *@This()) void {}

    fn directionVector(x_dir: f32, z_dir: f32) glm.Vector(3) {
        return glm.Vector(3).init([_]f32{
            std.math.cos(x_dir) * std.math.cos(z_dir),
            std.math.sin(x_dir) * std.math.cos(z_dir),
            std.math.sin(z_dir),
        });
    }

    fn updateMouseInput(self: *@This(), window: anytype) void {
        const delta = window.getMouseDelta();

        // Update look directions
        self.look_x += @floatCast(f32, -delta.dx * config.mouse_sensitivity);
        self.look_z += @floatCast(f32, -delta.dy * config.mouse_sensitivity);

        // Keep the updated values valid
        self.look_x = @mod(self.look_x, 2 * @as(f32, std.math.pi));
        self.look_z = std.math.clamp(self.look_z, -@as(f32, std.math.pi) / 2, @as(f32, std.math.pi) / 2);

        // Update vectors
        self.forward = directionVector(self.look_x, 0);
        self.right = directionVector(self.look_x - @as(f32, std.math.pi) / 2, 0);
    }

    fn updateAcceleration(self: *@This(), window: anytype) glm.Vector(3) {
        var acc = glm.Vector(3).init([_]f32{ 0, 0, 0 });

        if (window.configKeyPressed(.forward)) acc.addAssign(self.forward);
        if (window.configKeyPressed(.backward)) acc.subAssign(self.forward);
        if (window.configKeyPressed(.left)) acc.subAssign(self.right);
        if (window.configKeyPressed(.right)) acc.addAssign(self.right);

        if (acc.values[0] != 0 or acc.values[1] != 0) acc.normalizeAssign();

        if (window.configKeyPressed(.down)) acc.values[2] -= 1;
        if (window.configKeyPressed(.up)) acc.values[2] += 1;

        return acc;
    }

    pub fn updateVelocity(self: *@This(), acceleration: glm.Vector(3), dt: f32) void {
        // Lmao just be lazy, throw away dt too
        self.velocity = acceleration;
    }

    // Fixes precision problems with player coordinates by keeping an integer and a float part
    fn fixupCoord(int: *i32, flt: *f32) i32 {
        const adjust = @floatToInt(i32, flt.*);
        flt.* -= @intToFloat(f32, adjust);
        int.* += adjust;
        return int.* - adjust;
    }

    fn fixupIntCoords(self: *@This()) ivec3 {
        return .{
            .x = fixupCoord(&self.x, &self.x_frac),
            .y = fixupCoord(&self.y, &self.y_frac),
            .z = fixupCoord(&self.z, &self.z_frac),
        };
    }

    pub fn updatePosition(self: *@This(), dt: f32) ivec3 {
        const vel = self.velocity.mulScalar(config.movement_speed * dt);
        self.x_frac += vel.values[0];
        self.y_frac += vel.values[1];
        self.z_frac += vel.values[2];

        return self.fixupIntCoords();
    }

    fn updateWorldPosition(self: *@This(), old_x: i32, old_y: i32, old_z: i32) void {}

    pub fn updateWithInput(self: *@This(), window: anytype, dt: f32) void {
        self.updateMouseInput(window);

        const acceleration = self.updateAcceleration(window);

        self.updateVelocity(acceleration, dt);

        const old_position = self.updatePosition(dt);

        // Calculate the new view
        const position = glm.Vector(3).init([_]f32{ self.x_frac, self.y_frac, self.z_frac });
        const look_direction = directionVector(self.look_x, self.look_z);
        const up = directionVector(self.look_x, self.look_z + @as(f32, std.math.pi) / 2);

        // Update camera matrix
        const perspective = glm.perspective(
            config.fov,
            window.aspect_ratio,
            config.near,
            config.far,
        );

        const look = glm.lookAt(
            position,
            position.add(look_direction),
            up,
        );

        self.camera = perspective.mul(look);

        self.updateWorldPosition(old_position.x, old_position.y, old_position.z);
    }

    pub fn drawPlayerView(self: *@This(), shader: *VoxelShader) void {
        shader.camera(self.camera);
        shader.intTranslation(-self.x, -self.y, -self.z);
        self.world.drawWorld(shader);
    }
};
