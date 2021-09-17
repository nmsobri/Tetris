const std = @import("std");
const c = @import("sdl.zig");
const t = @import("Tetromino.zig");
const mixin = @import("Mixin.zig");
const constant = @import("constant.zig");
const Board = @import("Board.zig");
const Vacant = [3]u8{ 255, 255, 255 };

const Self = @This();

board: *Board,
renderer: *c.SDL_Renderer,

x: i32 = undefined,
y: i32 = undefined,
tetromino: t.Tetromino = undefined,
tetromino_index: u32 = undefined,
tetromino_layout: t.TetrominoLayout = undefined,

usingnamespace mixin.DrawMixin(Self);

pub fn init(renderer: *c.SDL_Renderer, board: *Board, tetromino: t.Tetromino) Self {
    return Self{
        .x = 3,
        .y = -3,
        .board = board,
        .tetromino_index = 0,
        .tetromino = tetromino,
        .renderer = renderer,
        .tetromino_layout = tetromino.layout[0],
    };
}

pub fn randomPiece(renderer: *c.SDL_Renderer, board: *Board) !Self {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    const rand = &prng.random;
    const num = rand.uintLessThan(u32, t.Tetrominoes.len);
    return Self.init(renderer, board, t.Tetrominoes[num]);
}

pub fn draw(self: Self) void {
    var row: u8 = 0;
    while (row < self.tetromino_layout.len) : (row += 1) {
        var col: u8 = 0;
        while (col < self.tetromino_layout[0].len) : (col += 1) {
            if (self.tetromino_layout[row][col]) {
                self._draw(self.x + col, self.y + row, self.tetromino.color);
            }
        }
    }
}

pub fn moveDown(self: *Self) !void {
    if (!self.collision(0, 1, self.tetromino_layout)) {
        self.y += 1;
    } else {
        // we lock the piece and generate a new one
        self.lock();
        self.* = try Self.randomPiece(self.renderer, self.board);
    }
}

pub fn moveRight(self: *Self) void {
    if (!self.collision(1, 0, self.tetromino_layout)) {
        self.x += 1;
        self.draw();
    }
}

pub fn moveLeft(self: *Self) void {
    if (!self.collision(-1, 0, self.tetromino_layout)) {
        self.x -= 1;
        self.draw();
    }
}

pub fn rotate(self: *Self) void {
    const next_layout = self.tetromino.layout[(self.tetromino_index + 1) % self.tetromino.layout.len];
    var kick: i8 = 0;

    if (self.collision(0, 0, next_layout)) {
        if (self.x > constant.COL / 2) {
            // it's the right wall
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
        self.draw();
    }
}

pub fn lock(self: *Self) void {
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
                // gameOver = true;
                break;
            }
            // we lock the piece
            self.board.board[@intCast(usize, self.y + row)][@intCast(usize, self.x + col)] = self.tetromino.color;
        }
    }

    // remove full row
    self.remove();
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
            while (top_row > 1) : (top_row -= 1) {
                var top_col: u8 = 0;
                while (top_col < constant.COL) : (top_col += 1) {
                    self.board.board[top_row][top_col] = self.board.board[top_row - 1][top_col];
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

            // conditions
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
