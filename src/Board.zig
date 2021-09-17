const std = @import("std");
const mixin = @import("Mixin.zig");
const c = @import("sdl.zig");
const constant = @import("constant.zig");

const Self = @This();
board: [constant.ROW][constant.COL]?[3]u8 = undefined,
renderer: *c.SDL_Renderer = undefined,

usingnamespace mixin.DrawMixin(Self);

pub fn init(renderer: *c.SDL_Renderer) Self {
    return Self{
        .board = [_][constant.COL]?[3]u8{[1]?[3]u8{null} ** constant.COL} ** constant.ROW,
        .renderer = renderer,
    };
}

pub fn draw(self: Self) void {
    var row: u8 = 0;
    while (row < constant.ROW) : (row += 1) {
        var col: u8 = 0;
        while (col < constant.COL) : (col += 1) {
            if (self.board[row][col] != null) {
                self._draw(col, row, self.board[row][col].?);
            } else {
                self._draw(col, row, .{ 255, 255, 255 });
            }
        }
    }
}
