const std = @import("std");
const mixin = @import("Mixin.zig");
const c = @import("sdl.zig");
const constant = @import("constant.zig");
const Piece = @import("Piece.zig");
const DrawInterface = @import("interface.zig").DrawInterface;

const Self = @This();
board: [constant.ROW][constant.COL]?[3]u8 = undefined,
full_rows: [constant.ROW]bool = undefined,
animation_frame: u8 = undefined,
renderer: *c.SDL_Renderer = undefined,
interface: DrawInterface,

usingnamespace mixin.DrawMixin(Self);

pub fn init(renderer: *c.SDL_Renderer) Self {
    return Self{
        .board = [_][constant.COL]?[3]u8{[1]?[3]u8{null} ** constant.COL} ** constant.ROW,
        .full_rows = [_]bool{false} ** constant.ROW,
        .animation_frame = 0,
        .renderer = renderer,
        .interface = DrawInterface.init(draw),
    };
}

pub fn draw(inner: *DrawInterface, view: Piece.View) void {
    const self = @fieldParentPtr(Self, "interface", inner);
    _ = view;

    var row: usize = 0;
    while (row < constant.ROW) : (row += 1) {
        var col: usize = 0;
        while (col < constant.COL) : (col += 1) {
            if (self.board[row][col] != null) {
                self._draw(@intCast(c_int, col * constant.BLOCK), @intCast(c_int, row * constant.BLOCK), self.board[row][col].?);
            } else {
                self._draw(@intCast(c_int, col * constant.BLOCK), @intCast(c_int, row * constant.BLOCK), .{ 255, 255, 255 });
            }
        }
    }
}
