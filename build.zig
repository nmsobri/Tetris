const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("tetriz", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.subsystem = .Windows;
    exe.install();

    // Link system lib
    exe.linkLibC();
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2_image");

    // Cross compile, only add header file dir and lib dir on windows
    // cause on linux we use pkg-config
    if (builtin.os.tag == .windows) {
        // SDL2
        exe.addIncludeDir("./vendor/SDL2/include");
        exe.addLibPath("./vendor/SDL2/lib/x64");

        // SDL2_Iamge
        exe.addIncludeDir("./vendor/SDL2_Image/include");
        exe.addLibPath("./vendor/SDL2_Image/lib/x64");

        // Copy dll to output dir
        b.installBinFile("./vendor/SDL2/lib/x64/SDL2.dll", "SDL2.dll");
        b.installBinFile("./vendor/SDL2_Image/lib/x64/SDL2_image.dll", "SDL2_image.dll");
    }

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the game");
    run_step.dependOn(&run_cmd.step);
}
