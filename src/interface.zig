const Piece = @import("Piece.zig");

pub const DrawInterface = struct {
    const Self = @This();

    drawFn: fn (*Self, Piece.View) void,

    pub fn init(drawFn: fn (*Self, Piece.View) void) Self {
        return Self{
            .drawFn = drawFn,
        };
    }

    pub fn draw(self: *Self, view: Piece.View) void {
        self.drawFn(self, view);
    }
};
