const std = @import("std");
const Game = @import("Game.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var game = try Game.init(&gpa.allocator);
    defer game.close();
    try game.loop();
}
