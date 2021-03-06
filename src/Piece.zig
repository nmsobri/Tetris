const std = @import("std");
const c = @import("sdl.zig");
const t = @import("Tetromino.zig");
const mixin = @import("Mixin.zig");
const constant = @import("constant.zig");
const Board = @import("Board.zig");
const DrawInterface = @import("interface.zig").DrawInterface;

const Vacant = [3]u8{ 255, 255, 255 };
pub var next_piece: ?Self = null;
var frame_count: u8 = 0;
var some_row_full: bool = false;
pub const View = enum { PlayViewport, TetrominoViewport };

const Self = @This();

x: i32 = undefined,
y: i32 = undefined,
renderer: *c.SDL_Renderer = undefined,
tetromino: t.Tetromino = undefined,
tetromino_index: u32 = undefined,
tetromino_layout: t.TetrominoLayout = undefined,
interface: DrawInterface,
score: *u32,
line: *u32,

usingnamespace mixin.DrawMixin(Self);

pub fn init(renderer: *c.SDL_Renderer, x: i8, y: i8, tetromino: t.Tetromino, score: *u32, line: *u32) Self {
    return Self{
        .x = x,
        .y = y,
        .tetromino_index = 0,
        .renderer = renderer,
        .tetromino = tetromino,
        .tetromino_layout = tetromino.layout[0],
        .interface = DrawInterface.init(draw),
        .score = score,
        .line = line,
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

pub fn randomPiece(renderer: *c.SDL_Renderer, score: *u32, line: *u32) !Self {
    Self.next_piece = Self.init(renderer, 0, 0, t.Tetrominoes[try Self.randomNumber()], score, line);
    return Self.init(renderer, 3, -3, t.Tetrominoes[try Self.randomNumber()], score, line);
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
                    var viewport_y_space = @intToFloat(f32, constant.TetrominoViewport.h - self.tetromino.height) / @as(f32, 2);

                    var x = viewport_x_space + @intToFloat(f32, col * constant.BLOCK);
                    var y = viewport_y_space + @intToFloat(f32, (row - self.tetromino.yoffset) * constant.BLOCK);
                    self._draw(@floatToInt(c_int, x), @floatToInt(c_int, y), self.tetromino.color);
                }
            }
        }
    }
}

pub fn drawRandomPiece(renderer: *c.SDL_Renderer, view: Self.View) !void {
    if (Self.next_piece == null) {
        var score: u32 = 0;
        var line: u32 = 0;
        Self.next_piece = Self.init(renderer, 0, 0, t.Tetrominoes[try Self.randomNumber()], &score, &line);
    }

    Self.next_piece.?.interface.draw(view);
}

pub fn hardDrop(self: *Self, board: *Board, drop: *c.Mix_Chunk, clear: *c.Mix_Chunk) !bool {
    while (self.collision(board, 0, 1, self.tetromino_layout) == false) {
        self.y += 1;
    }

    _ = c.Mix_PlayChannel(-1, drop, 0);

    if (self.lock(board, clear) == false) {
        return false;
    }

    // Reset piece position for play viewport
    Self.next_piece.?.x = 3;
    Self.next_piece.?.y = -3;

    self.* = Self.next_piece.?;
    Self.next_piece = Self.init(self.renderer, 0, 0, t.Tetrominoes[try randomNumber()], self.score, self.line);
    return true;
}

pub fn moveDown(self: *Self, board: *Board, drop: *c.Mix_Chunk, clear: *c.Mix_Chunk) !bool {
    var is_next_collide = false;

    if (self.collision(board, 0, 2, self.tetromino_layout)) {
        is_next_collide = true;
    }

    if (!self.collision(board, 0, 1, self.tetromino_layout)) {
        self.y += 1;
        if (is_next_collide) {
            // Play sound effect
            _ = c.Mix_PlayChannel(-1, drop, 0);
            // _ = c.Mix_PlayChannel(-1, clear, 0);
        }
    }

    if (is_next_collide) {

        // We lock the piece and generate a new one
        if (self.lock(board, clear) == false) {
            return false;
        }

        // Reset piece position for play viewport
        Self.next_piece.?.x = 3;
        Self.next_piece.?.y = -3;

        self.* = Self.next_piece.?;
        Self.next_piece = Self.init(self.renderer, 0, 0, t.Tetrominoes[try randomNumber()], self.score, self.line);
    }

    return true;
}

pub fn moveRight(self: *Self, board: *Board) void {
    if (!self.collision(board, 1, 0, self.tetromino_layout)) {
        self.x += 1;
        self.interface.draw(View.PlayViewport);
    }
}

pub fn moveLeft(self: *Self, board: *Board) void {
    if (!self.collision(board, -1, 0, self.tetromino_layout)) {
        self.x -= 1;
        self.interface.draw(View.PlayViewport);
    }
}

pub fn rotate(self: *Self, board: *Board) void {
    const next_layout = self.tetromino.layout[(self.tetromino_index + 1) % self.tetromino.layout.len];
    var kick: i8 = 0;

    // Check if rotation at current position cause blocking, if yes, then kick it one block to left/right based on its x position
    if (self.collision(board, 0, 0, next_layout)) {
        if (self.x > constant.COL / 2) {
            // It's the right wall
            kick = -1; // We need to move the piece to the left
        } else {
            // It's the left wall
            kick = 1; // We need to move the piece to the right
        }
    }

    if (!self.collision(board, kick, 0, next_layout)) {
        self.x += kick;
        self.tetromino_index = @intCast(u32, (self.tetromino_index + 1) % self.tetromino.layout.len); // (0+1)%4 => 1
        self.tetromino_layout = self.tetromino.layout[self.tetromino_index];
        self.interface.draw(View.PlayViewport);
    }
}

pub fn lock(self: *Self, board: *Board, clear: *c.Mix_Chunk) bool {
    var row: u8 = 0;
    var should_return = false;

    outer: while (row < self.tetromino_layout.len) : (row += 1) {
        var col: u8 = 0;
        while (col < self.tetromino_layout[0].len) : (col += 1) {
            // We skip the vacant squares
            if (!self.tetromino_layout[row][col]) {
                continue;
            }

            // Pieces to lock on top = game over
            if (self.y + row < 0) {
                // Game over
                // dont immediately return, it will cause row 0, always vacant,
                // eventhough there is piece lock on that row
                should_return = true;
                continue :outer;
            }

            // We lock the piece
            board.board[@intCast(usize, self.y + row)][@intCast(usize, self.x + col)] = self.tetromino.color;
        }
    }

    if (should_return) return false;

    // Check if there is full row, if its, remove full row
    self.remove(board, clear);
    return true;
}

pub fn remove(self: *Self, board: *Board, clear: *c.Mix_Chunk) void {
    _ = clear;
    // Remove full rows
    var row: u8 = 0;
    while (row < constant.ROW) : (row += 1) {
        var col: u8 = 0;
        var is_row_full = while (col < constant.COL) : (col += 1) {
            if (board.board[row][col] == null) break false;
        } else true;

        if (is_row_full) {
            _ = c.Mix_PlayChannel(-1, clear, 0);
            Self.some_row_full = true;
            // If the row is full, we move down all the rows above it
            self.score.* += 10;
            self.line.* += 1;

            // Change color of rows that need to be remove
            var _col: u8 = 0;
            while (_col < constant.COL) : (_col += 1) {
                board.board[@intCast(usize, row)][@intCast(usize, _col)] = .{ 100, 100, 100 };
            }

            // Mark the rows as full thus for removal
            board.full_rows[row] = true;
        }
    }
}

pub fn collision(self: Self, board: *Board, x: i32, y: i32, tetromino: t.TetrominoLayout) bool {
    var row: u8 = 0;
    while (row < tetromino.len) : (row += 1) {
        var col: u8 = 0;
        while (col < tetromino[0].len) : (col += 1) {

            // If the square is empty, we skip it
            if (!tetromino[row][col]) {
                continue;
            }

            // Coordinates of the tetromino after movement
            const new_x = self.x + col + x;
            const new_y = self.y + row + y;

            // Conditions, collided with the viewport
            if (new_x < 0 or new_x >= constant.COL or new_y >= constant.ROW) {
                return true;
            }

            // Skip newY < 0; board[-1] will crush our game
            if (new_y < 0) {
                continue;
            }

            // check if there is a locked tetromino alrady in place
            if (board.board[@intCast(usize, new_y)][@intCast(usize, new_x)] != null) {
                return true;
            }
        }
    }

    return false;
}

pub fn eraseLine(board: *Board) void {
    if (Self.some_row_full) {
        Self.frame_count += 1;
    }

    if (Self.frame_count >= 10) {
        board.animation_frame += 1;

        if (board.animation_frame <= 4) {
            for (board.full_rows) |row, i| {
                if (row) {
                    // Animate color of rows that need to be remove
                    var col: u8 = 0;
                    while (col < constant.COL) : (col += 1) {
                        if (board.animation_frame % 2 == 0) {
                            board.board[@intCast(usize, i)][@intCast(usize, col)] = .{ 100, 100, 100 };
                        } else {
                            board.board[@intCast(usize, i)][@intCast(usize, col)] = .{ 150, 150, 150 };
                        }
                    }
                }
            }
        } else {
            // Remove row
            for (board.full_rows) |row, i| {
                if (row) {
                    var top_row = i;
                    while (top_row >= 1) : (top_row -= 1) {
                        var col: u8 = 0;
                        while (col < constant.COL) : (col += 1) {
                            board.board[top_row][col] = board.board[top_row - 1][col];
                        }
                    } else {
                        // this is the very first row, so there is no more row above it, so just vacant the entire row
                        var col: u8 = 0;
                        while (col < constant.COL) : (col += 1) {
                            board.board[top_row][col] = null;
                        }
                    }

                    board.full_rows[i] = false; // Mark as not full
                }
            }

            Self.some_row_full = false;
            board.animation_frame = 0;
        }

        Self.frame_count = 0;
    }
}
