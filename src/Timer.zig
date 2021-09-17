const std = @import("std");
const err = std.log.err;
const c = @import("sdl.zig");

const Self = @This();

is_started: bool,
is_paused: bool,
start_timer: u32,
pause_timer: u32,

pub fn init() Self {
    return Self{
        .is_started = false,
        .is_paused = false,
        .start_timer = 0,
        .pause_timer = 0,
    };
}

pub fn startTimer(self: *Self) void {
    self.start_timer = c.SDL_GetTicks();
    self.pause_timer = 0;
    self.is_started = true;
    self.is_paused = false;
}

pub fn stopTimer(self: *Self) void {
    self.is_started = false;
    self.is_paused = false;
    self.start_timer = 0;
    self.pause_timer = 0;
}

pub fn pauseTimer(self: *Self) void {
    if (self.is_started and !self.is_paused) {
        self.is_paused = true;
        self.start_timer = 0;
        // Since time is static here ( due to pause ), we need to calculate
        // how much time has passed before time become static ( paused )
        self.pause_timer = c.SDL_GetTicks() - self.start_timer;
    }
}

pub fn resumeTimer(self: *Self) void {
    if (self.is_started and self.is_paused) {
        self.is_paused = false;
        self.start_timer = c.SDL_GetTicks() - self.pause_timer;
        self.pause_timer = 0;
    }
}

pub fn getTicks(self: Self) u32 {
    if (!self.is_started) return 0;

    if (self.is_paused) {
        return self.pause_timer;
    } else {
        return c.SDL_GetTicks() - self.start_timer;
    }
}

pub fn isStarted(self: Self) bool {
    return self.is_started;
}

pub fn isPaused(self: Self) bool {
    return self.is_paused;
}
