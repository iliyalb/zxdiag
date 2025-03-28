const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zxdiag",
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Add raylib dependencies
    const raylib = b.addStaticLibrary(.{
        .name = "raylib",
        .target = target,
        .optimize = optimize,
    });
    raylib.addIncludePath(.{ .cwd_relative = "vendor/raylib/src" });
    raylib.addIncludePath(.{ .cwd_relative = "vendor/raylib/src/external/glfw/include" });

    const raylib_flags = &[_][]const u8{
        "-DPLATFORM_DESKTOP",
        "-D_GNU_SOURCE",
        "-DGLFW_BUILD_X11",
    };

    raylib.addCSourceFile(.{
        .file = .{ .cwd_relative = "vendor/raylib/src/rcore.c" },
        .flags = raylib_flags,
    });
    raylib.addCSourceFile(.{
        .file = .{ .cwd_relative = "vendor/raylib/src/rtextures.c" },
        .flags = raylib_flags,
    });
    raylib.addCSourceFile(.{
        .file = .{ .cwd_relative = "vendor/raylib/src/rshapes.c" },
        .flags = raylib_flags,
    });
    raylib.addCSourceFile(.{
        .file = .{ .cwd_relative = "vendor/raylib/src/rtext.c" },
        .flags = raylib_flags,
    });
    raylib.addCSourceFile(.{
        .file = .{ .cwd_relative = "vendor/raylib/src/utils.c" },
        .flags = raylib_flags,
    });
    raylib.addCSourceFile(.{
        .file = .{ .cwd_relative = "vendor/raylib/src/raudio.c" },
        .flags = raylib_flags,
    });
    raylib.addCSourceFile(.{
        .file = .{ .cwd_relative = "vendor/raylib/src/rglfw.c" },
        .flags = raylib_flags,
    });

    raylib.linkSystemLibrary("GL");
    raylib.linkSystemLibrary("m");
    raylib.linkSystemLibrary("dl");
    raylib.linkSystemLibrary("pthread");
    raylib.linkSystemLibrary("rt");
    raylib.linkSystemLibrary("X11");

    // Add raygui implementation
    exe.addCSourceFile(.{
        .file = .{ .cwd_relative = "src/raygui_impl.c" },
        .flags = &.{},
    });

    exe.linkLibrary(raylib);
    exe.addIncludePath(.{ .cwd_relative = "vendor/raylib/src" });
    exe.addIncludePath(.{ .cwd_relative = "vendor/raygui/src" });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_cmd.step);
} 