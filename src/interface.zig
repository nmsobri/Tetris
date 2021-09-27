pub const DrawInterface = struct {
    const Self = @This();

    drawFn: fn (*Self) void,

    pub fn init(drawFn: fn (*Self) void) Self {
        return Self{
            .drawFn = drawFn,
        };
    }

    pub fn draw(self: *Self) void {
        self.drawFn(self);
    }
};
