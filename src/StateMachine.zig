const std = @import("std");
const StateInterfce = @import("interface.zig").StateInterface;

const Self = @This();

states: std.ArrayList(*StateInterfce),

pub fn init(allocator: *std.mem.Allocator) Self {
    return Self{
        .states = std.ArrayList(*StateInterfce).init(allocator),
    };
}

pub fn pushState(self: *Self, state: *StateInterfce) !void {
    if (self.states.items.len != 0) {
        if (std.mem.eql(u8, self.states.items[self.states.items.len - 1].stateID(), state.stateID())) {
            return;
        }

        _ = try self.states.items[self.states.items.len - 1].onExit();
    }

    try self.states.append(state);
    _ = try self.states.items[self.states.items.len - 1].onEnter();
}

pub fn changeState(self: *Self, state: *StateInterfce) !void {
    if (self.states.items.len != 0) {
        if (std.mem.eql(u8, self.states.items[self.states.items.len - 1].stateID(), state.stateID())) {
            return;
        }

        if (try self.states.items[self.states.items.len - 1].onExit()) {
            _ = self.states.pop();
        }
    }

    try self.states.append(state);
    _ = try self.states.items[self.states.items.len - 1].onEnter();
}

pub fn popState(self: *Self) !void {
    if (self.states.items.len != 0) {
        if (try self.states.items[self.states.items.len - 1].onExit()) {
            _ = self.states.pop();
        }
    }

    if (self.states.items.len != 0) {
        _ = try self.states.items[self.states.items.len - 1].onEnter();
    }
}

pub fn input(self: Self) !void {
    if (self.states.items.len != 0) {
        try self.states.items[self.states.items.len - 1].input();
    }
}

pub fn update(self: Self) !void {
    if (self.states.items.len != 0) {
        try self.states.items[self.states.items.len - 1].update();
    }
}

pub fn render(self: Self) !void {
    if (self.states.items.len != 0) {
        try self.states.items[self.states.items.len - 1].render();
    }
}
