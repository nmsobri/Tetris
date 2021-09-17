const std = @import("std");
const Game = @import("Game.zig");

pub fn main() anyerror!void {
    var game = try Game.init();
    defer game.close();
    try game.loop();
}
