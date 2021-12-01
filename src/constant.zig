const c = @import("sdl.zig");

pub const ROW = 20;
pub const COL = 10;
pub const BLOCK = 30;
pub const GAME_NAME = "Tetriz";

pub const SCREEN_WIDTH = BLOCK * 18;
pub const SCREEN_HEIGHT = BLOCK * 22;

pub const VIEWPORT_INFO_WIDTH = BLOCK * 5;
pub const VIEWPORT_INFO_HEIGHT = BLOCK * 6;

pub const FPS = 60;
pub const TICKS_PER_FRAME: f64 = 1000.0 / @intToFloat(f64, FPS);

pub const LeftViewport: c.SDL_Rect = .{
    .x = 0,
    .y = 0,
    .w = BLOCK * 12,
    .h = SCREEN_HEIGHT,
};

pub const PlayViewport: c.SDL_Rect = .{
    .x = BLOCK,
    .y = BLOCK,
    .w = BLOCK * 10,
    .h = BLOCK * ROW,
};

pub const RightViewport: c.SDL_Rect = .{
    .x = BLOCK * 12,
    .y = 0,
    .w = BLOCK * 7,
    .h = SCREEN_HEIGHT,
};

pub const LevelViewport: c.SDL_Rect = .{
    .x = BLOCK * 12,
    .y = BLOCK,
    .w = VIEWPORT_INFO_WIDTH,
    .h = VIEWPORT_INFO_HEIGHT,
};

pub const ScoreViewport: c.SDL_Rect = .{
    .x = BLOCK * 12,
    .y = BLOCK * 8,
    .w = VIEWPORT_INFO_WIDTH,
    .h = VIEWPORT_INFO_HEIGHT,
};

pub const TetrominoViewport: c.SDL_Rect = .{
    .x = BLOCK * 12,
    .y = BLOCK * 15,
    .w = VIEWPORT_INFO_WIDTH,
    .h = VIEWPORT_INFO_HEIGHT,
};
