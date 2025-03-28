const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zxdiag",
        .root_source_file = b.addPath("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add raylib and raygui dependencies
    const raylib = b.addStaticLibrary(.{
        .name = "raylib",
        .target = target,
        .optimize = optimize,
    });
    raylib.addIncludePath(.{ .path = "vendor/raylib/src" });
    raylib.addCSourceFiles(&.{
        "vendor/raylib/src/core.c",
        "vendor/raylib/src/shapes.c",
        "vendor/raylib/src/text.c",
        "vendor/raylib/src/utils.c",
        "vendor/raylib/src/raudio.c",
        "vendor/raylib/src/rglfw.c",
    }, &.{"-DPLATFORM_DESKTOP"});
    raylib.linkSystemLibrary("GL");
    raylib.linkSystemLibrary("m");
    raylib.linkSystemLibrary("dl");
    raylib.linkSystemLibrary("pthread");

    const raygui = b.addStaticLibrary(.{
        .name = "raygui",
        .target = target,
        .optimize = optimize,
    });
    raygui.addIncludePath(.{ .path = "vendor/raygui/src" });
    raygui.addCSourceFiles(&.{
        "vendor/raygui/src/raygui.c",
    }, &.{});

    exe.linkLibrary(raylib);
    exe.linkLibrary(raygui);
    exe.addIncludePath(.{ .path = "vendor/raylib/src" });
    exe.addIncludePath(.{ .path = "vendor/raygui/src" });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_cmd.step);
} 