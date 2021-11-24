pub const ROW = 20;
pub const COL = 10;
pub const BLOCK = 30;
pub const GAME_NAME = "Tetriz";

pub const SCREEN_WIDTH = BLOCK * 39;
pub const SCREEN_HEIGHT = BLOCK * 22;

pub const VIEWPORT_INFO_WIDTH = BLOCK * 6;
pub const VIEWPORT_INFO_HEIGHT = BLOCK * 6;

pub const FPS = 60;
pub const TICKS_PER_FRAME: f64 = 1000.0 / @intToFloat(f64, FPS);
