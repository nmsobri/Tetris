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

pub const StateInterface = struct {
    const Self = @This();

    updateFn: fn (*Self) anyerror!void,
    renderFn: fn (*Self) anyerror!void,
    onEnterFn: fn (*Self) anyerror!bool,
    onExitFn: fn (*Self) anyerror!bool,
    inputFn: fn (*Self) anyerror!void,
    stateIDFn: fn (*Self) []const u8,

    pub fn init(
        updateFn: fn (*Self) anyerror!void,
        renderFn: fn (*Self) anyerror!void,
        onEnterFn: fn (*Self) anyerror!bool,
        onExitFn: fn (*Self) anyerror!bool,
        inputFn: fn (*Self) anyerror!void,
        stateIDFn: fn (*Self) []const u8,
    ) Self {
        return Self{
            .updateFn = updateFn,
            .renderFn = renderFn,
            .onEnterFn = onEnterFn,
            .onExitFn = onExitFn,
            .inputFn = inputFn,
            .stateIDFn = stateIDFn,
        };
    }

    pub fn update(self: *Self) !void {
        try self.updateFn(self);
    }

    pub fn render(self: *Self) !void {
        try self.renderFn(self);
    }

    pub fn onEnter(self: *Self) !bool {
        try return self.onEnterFn(self);
    }

    pub fn onExit(self: *Self) !bool {
        try return self.onExitFn(self);
    }

    pub fn input(self: *Self) !void {
        try return self.inputFn(self);
    }

    pub fn stateID(self: *Self) []const u8 {
        return self.stateIDFn(self);
    }
};
