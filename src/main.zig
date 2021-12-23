const std = @import("std");
const Game = @import("lib/Game.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var game = try Game.init(allocator);
    defer game.close();
    try game.loop();
}
