const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("tetriz", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.subsystem = .Windows;
    exe.install();

    exe.addIncludeDir("./vendor/SDL2/include");
    exe.addLibPath("./vendor/SDL2/lib/x64");

    // Link system lib
    exe.linkLibC();
    exe.linkSystemLibrary("SDL2");

    // Copy dll to output dir
    b.installBinFile("./vendor/SDL2/lib/x64/SDL2.dll", "SDL2.dll");

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the game");
    run_step.dependOn(&run_cmd.step);
}
