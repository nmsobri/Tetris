const std = @import("std");
const c = @import("sdl.zig");
const t = @import("Tetromino.zig");
const mixin = @import("Mixin.zig");
const constant = @import("constant.zig");
const Board = @import("Board.zig");
const DrawInterface = @import("interface.zig").DrawInterface;

const Vacant = [3]u8{ 255, 255, 255 };
pub var next_piece: Self = undefined;
pub const View = enum { PlayViewport, TetrominoViewport };

const Self = @This();

x: i32 = undefined,
y: i32 = undefined,
board: *Board = undefined,
renderer: *c.SDL_Renderer = undefined,
tetromino: t.Tetromino = undefined,
tetromino_index: u32 = undefined,
tetromino_layout: t.TetrominoLayout = undefined,
interface: DrawInterface,
score: *u32,

usingnamespace mixin.DrawMixin(Self);

pub fn init(renderer: *c.SDL_Renderer, x: i8, y: i8, board: *Board, tetromino: t.Tetromino, score: *u32) Self {
    return Self{
        .x = x,
        .y = y,
        .board = board,
        .tetromino_index = 0,
        .renderer = renderer,
        .tetromino = tetromino,
        .tetromino_layout = tetromino.layout[0],
        .interface = DrawInterface.init(draw),
        .score = score,
    };
}

fn randomNumber() !u32 {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    const rand = prng.random();
    return rand.uintLessThan(u32, t.Tetrominoes.len);
}

pub fn randomPiece(renderer: *c.SDL_Renderer, board: *Board, score: *u32) !Self {
    Self.next_piece = Self.init(renderer, 0, 0, board, t.Tetrominoes[try Self.randomNumber()], score);
    return Self.init(renderer, 3, -3, board, t.Tetrominoes[try randomNumber()], score);
}

pub fn draw(inner: *DrawInterface, v: View) void {
    const self = @fieldParentPtr(Self, "interface", inner);

    var row: u8 = 0;
    while (row < self.tetromino_layout.len) : (row += 1) {
        var col: u8 = 0;
        while (col < self.tetromino_layout[0].len) : (col += 1) {
            if (self.tetromino_layout[row][col]) {
                if (v == .PlayViewport) {
                    self._draw((self.x + col) * constant.BLOCK, (self.y + row) * constant.BLOCK, self.tetromino.color);
                } else {
                    var viewport_x_space = @intToFloat(f32, constant.VIEWPORT_INFO_WIDTH - self.tetromino.width) / @as(f32, 2);
                    var viewport_y_space = @intToFloat(f32, constant.VIEWPORT_INFO_HEIGHT - self.tetromino.height) / @as(f32, 2);

                    var x = viewport_x_space + @intToFloat(f32, col * constant.BLOCK);
                    var y = viewport_y_space + @intToFloat(f32, (row - self.tetromino.yoffset) * constant.BLOCK);
                    self._draw(@floatToInt(c_int, x), @floatToInt(c_int, y), self.tetromino.color);
                }
            }
        }
    }
}

pub fn moveDown(self: *Self) !bool {
    if (!self.collision(0, 1, self.tetromino_layout)) {
        self.y += 1;
    } else {
        // we lock the piece and generate a new one
        if (self.lock() == false) {
            return false;
        }

        // Reset piece position for play viewport
        Self.next_piece.x = 3;
        Self.next_piece.y = -3;

        self.* = Self.next_piece;
        Self.next_piece = Self.init(self.renderer, 0, 0, self.board, t.Tetrominoes[try randomNumber()], self.score);
    }

    return true;
}

pub fn moveRight(self: *Self) void {
    if (!self.collision(1, 0, self.tetromino_layout)) {
        self.x += 1;
        self.interface.draw(View.PlayViewport);
    }
}

pub fn moveLeft(self: *Self) void {
    if (!self.collision(-1, 0, self.tetromino_layout)) {
        self.x -= 1;
        self.interface.draw(View.PlayViewport);
    }
}

pub fn rotate(self: *Self) void {
    const next_layout = self.tetromino.layout[(self.tetromino_index + 1) % self.tetromino.layout.len];
    var kick: i8 = 0;

    // Check if rotation at current position cause blocking, if yes, then kick it one block to left/right based on its x position
    if (self.collision(0, 0, next_layout)) {
        if (self.x > constant.COL / 2) {
            // it's the right wallgg
            kick = -1; // we need to move the piece to the left
        } else {
            // it's the left wall
            kick = 1; // we need to move the piece to the right
        }
    }

    if (!self.collision(kick, 0, next_layout)) {
        self.x += kick;
        self.tetromino_index = @intCast(u32, (self.tetromino_index + 1) % self.tetromino.layout.len); // (0+1)%4 => 1
        self.tetromino_layout = self.tetromino.layout[self.tetromino_index];
        self.interface.draw(View.PlayViewport);
    }
}

pub fn lock(self: *Self) bool {
    var row: u8 = 0;
    while (row < self.tetromino_layout.len) : (row += 1) {
        var col: u8 = 0;
        while (col < self.tetromino_layout[0].len) : (col += 1) {
            // we skip the vacant squares
            if (!self.tetromino_layout[row][col]) {
                continue;
            }

            // pieces to lock on top = game over
            if (self.y + row < 0) {
                // stop request animation frame
                // game over
                return false;
            }
            // we lock the piece
            self.board.board[@intCast(usize, self.y + row)][@intCast(usize, self.x + col)] = self.tetromino.color;
        }
    }

    // check if there is full row, if its, remove full row
    self.remove();
    return true;
}

pub fn remove(self: Self) void {
    // remove full rows
    var row: u8 = 0;
    while (row < constant.ROW) : (row += 1) {
        var col: u8 = 0;

        var is_row_full = while (col < constant.COL) : (col += 1) {
            if (self.board.board[row][col] == null) break false;
        } else true;

        if (is_row_full) {
            // if the row is full, we move down all the rows above it
            var top_row = row;
            self.score.* += 10;

            while (top_row >= 1) : (top_row -= 1) {
                var top_col: u8 = 0;
                while (top_col < constant.COL) : (top_col += 1) {
                    self.board.board[top_row][top_col] = self.board.board[top_row - 1][top_col];
                }
            } else {
                // this is the very first row, so there is no more row above it, so just vacant the entire row
                var top_col: u8 = 0;
                while (top_col < constant.COL) : (top_col += 1) {
                    self.board.board[top_row][top_col] = null;
                }
            }
        }
    }
}

pub fn collision(self: Self, x: i32, y: i32, tetromino: t.TetrominoLayout) bool {
    var row: u8 = 0;
    while (row < tetromino.len) : (row += 1) {
        var col: u8 = 0;
        while (col < tetromino[0].len) : (col += 1) {

            // if the square is empty, we skip it
            if (!tetromino[row][col]) {
                continue;
            }

            // coordinates of the tetromino after movement
            const new_x = self.x + col + x;
            const new_y = self.y + row + y;

            // conditions, collided with the viewport
            if (new_x < 0 or new_x >= constant.COL or new_y >= constant.ROW) {
                return true;
            }

            // skip newY < 0; board[-1] will crush our game
            if (new_y < 0) {
                continue;
            }

            // check if there is a locked tetromino alrady in place
            if (self.board.board[@intCast(usize, new_y)][@intCast(usize, new_x)] != null) {
                return true;
            }
        }
    }

    return false;
}
