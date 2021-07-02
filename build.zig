const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const exe = b.addExecutable("voxig", "src/main.zig");

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    exe.setTarget(b.standardTargetOptions(.{}));

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    exe.setBuildMode(b.standardReleaseOptions());

    exe.install();

    exe.addPackage(.{
        .name = "zgl",
        .path = .{
            .path = "external/zgl/zgl.zig",
        },
    });

    exe.addPackage(.{
        .name = "glm",
        .path = .{
            .path = "external/glm/glm.zig",
        },
    });

    exe.addPackage(.{
        .name = "config",
        .path = .{
            .path = "config.zig",
        },
    });

    exe.addIncludeDir("/usr/include");
    exe.addIncludeDir("./external/FastNoiseLite/C/");

    exe.linkLibC();
    exe.linkSystemLibrary("gl");
    exe.linkSystemLibrary("glfw");
    exe.linkSystemLibrary("epoxy");

    exe.setMainPkgPath("./");

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
