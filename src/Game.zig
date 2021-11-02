const std = @import("std");
const err = std.log.err;
const c = @import("sdl.zig");

const Timer = @import("Timer.zig");
const Board = @import("Board.zig");
const Piece = @import("Piece.zig");
const BitmapFont = @import("BitmapFont.zig");
const Texture = @import("Texture.zig");
const constant = @import("constant.zig");
const DrawInterface = @import("interface.zig").DrawInterface;

const Entity = enum { Board, Piece };
const Element = struct { typ: Entity, obj: *const c_void };
const Self = @This();

const left_viewport: c.SDL_Rect = .{
    .x = 0,
    .y = 0,
    .w = constant.BLOCK * 12,
    .h = constant.SCREEN_HEIGHT,
};

const play_viewport: c.SDL_Rect = .{
    .x = constant.BLOCK,
    .y = constant.BLOCK,
    .w = constant.BLOCK * 10,
    .h = constant.BLOCK * constant.ROW,
};

const right_viewport: c.SDL_Rect = .{
    .x = constant.BLOCK * 12,
    .y = 0,
    .w = constant.BLOCK * 7,
    .h = constant.SCREEN_HEIGHT,
};

const level_viewport: c.SDL_Rect = .{
    .x = constant.BLOCK * 12,
    .y = constant.BLOCK,
    .w = constant.VIEWPORT_INFO_WIDTH,
    .h = constant.VIEWPORT_INFO_HEIGHT,
};

const score_viewport: c.SDL_Rect = .{
    .x = constant.BLOCK * 12,
    .y = constant.BLOCK * 8,
    .w = constant.VIEWPORT_INFO_WIDTH,
    .h = constant.VIEWPORT_INFO_HEIGHT,
};

const tetromino_viewport: c.SDL_Rect = .{
    .x = constant.BLOCK * 12,
    .y = constant.BLOCK * 15,
    .w = constant.VIEWPORT_INFO_WIDTH,
    .h = constant.VIEWPORT_INFO_HEIGHT,
};

pub var Score: u32 = 0;
pub var Level: u8 = 1;

fps_timer: Timer = undefined,
cap_timer: Timer = undefined,
window: ?*c.SDL_Window = null,
elements: [2]Element = undefined,
renderer: ?*c.SDL_Renderer = null,
allocator: *std.mem.Allocator = undefined,
bitmap_font: BitmapFont = undefined,

pub fn init(allocator: *std.mem.Allocator) !Self {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) < 0) {
        err("Couldn't initialize SDL: {s}", .{c.SDL_GetError()});
        return error.ERROR_INIT_SDL;
    }

    var self = Self{
        .allocator = allocator,
        .bitmap_font = BitmapFont.init(),
        .fps_timer = Timer.init(),
        .cap_timer = Timer.init(),
    };

    self.window = c.SDL_CreateWindow(
        constant.GAME_NAME,
        c.SDL_WINDOWPOS_CENTERED,
        c.SDL_WINDOWPOS_CENTERED,
        constant.SCREEN_WIDTH,
        constant.SCREEN_HEIGHT,
        0,
    ) orelse {
        err("Error creating window. SDL Error: {s}", .{c.SDL_GetError()});
        return error.ERROR_CREATE_WINDOW;
    };

    self.renderer = c.SDL_CreateRenderer(self.window.?, -1, c.SDL_RENDERER_ACCELERATED) orelse {
        err("Error creating renderer. SDL Error: {s}", .{c.SDL_GetError()});
        return error.ERROR_CREATE_RENDERER;
    };

    var font_texture = try allocator.create(Texture);
    font_texture.* = Texture.init(self.window.?, self.renderer.?);

    try font_texture.loadFromFile("res/font.bmp");
    try self.bitmap_font.buildFont(font_texture);

    var aBoard = try allocator.create(Board);
    aBoard.* = Board.init(self.renderer.?); // need to do this, so Board is allocated on the Heap

    var aPiece = try allocator.create(Piece);
    aPiece.* = try Piece.randomPiece(self.renderer.?, aBoard); // need to do this, so Board is allocated on the Heap

    self.elements = .{
        // .{ .typ = .Board, .obj = &Board.init(self.renderer.?) }, // not working, cause this allocated Board on the Stack
        // .{ .typ = .Piece, .obj = &try Piece.randomPiece(self.renderer.?, aBoard) }, // not working, cause this allocated Piece on the Stack
        .{ .typ = .Board, .obj = aBoard },
        .{ .typ = .Piece, .obj = aPiece },
    };

    return self;
}

pub fn loop(self: *Self) !void {
    self.cap_timer.startTimer();

    var p = for (self.elements) |e| {
        if (e.typ == .Piece) {
            break @intToPtr(*Piece, @ptrToInt(e.obj));
        }
    } else unreachable;

    mainloop: while (true) {
        self.fps_timer.startTimer();

        if (try self.handleInput(p)) {
            break :mainloop;
        }

        const elapsed_time = self.cap_timer.getTicks();
        if (elapsed_time >= 1000) {
            try p.moveDown();
            self.cap_timer.startTimer();
        }

        self.updateGame();
        try self.renderGame();

        const time_taken = @intToFloat(f64, self.fps_timer.getTicks());
        if (time_taken < constant.TICKS_PER_FRAME) {
            c.SDL_Delay(@floatToInt(u32, constant.TICKS_PER_FRAME - time_taken));
        }
    }
}

fn handleInput(self: Self, _piece: *Piece) !bool {
    _ = self;
    var e: c.SDL_Event = undefined;

    return while (c.SDL_PollEvent(&e) > 0) {
        switch (e.type) {
            c.SDL_QUIT => break true,

            c.SDL_KEYDOWN => switch (e.key.keysym.sym) {
                c.SDLK_ESCAPE => break true,
                c.SDLK_UP => {
                    if (e.key.repeat == 0) {
                        _piece.rotate();
                    }
                },
                c.SDLK_DOWN => try _piece.moveDown(),
                c.SDLK_LEFT => _piece.moveLeft(),
                c.SDLK_RIGHT => _piece.moveRight(),
                else => {},
            },
            else => {},
        }
    } else false;
}

fn updateGame(self: Self) void {
    _ = self;
}

fn renderGame(self: *Self) !void {
    _ = c.SDL_SetRenderDrawColor(self.renderer.?, 0x00, 0x00, 0x00, 0x00);
    _ = c.SDL_RenderClear(self.renderer.?);

    // Left viewport
    _ = c.SDL_RenderSetViewport(self.renderer.?, &Self.left_viewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer.?, 0x00, 0x00, 0x00, 0x00);
    _ = c.SDL_RenderFillRect(self.renderer.?, &.{ .x = 0, .y = 0, .w = 360, .h = constant.SCREEN_HEIGHT });

    // Play viewport
    _ = c.SDL_RenderSetViewport(self.renderer.?, &Self.play_viewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer.?, 0x00, 0xFF, 0x00, 0xFF);
    _ = c.SDL_RenderDrawRect(self.renderer.?, &.{
        .x = 0,
        .y = 0,
        .w = 300,
        .h = constant.SCREEN_HEIGHT - constant.BLOCK * 2,
    });

    for (self.elements) |e| {
        var obj_interface = switch (e.typ) {
            .Board => &(@intToPtr(*Board, @ptrToInt(e.obj))).interface,
            .Piece => &(@intToPtr(*Piece, @ptrToInt(e.obj))).interface,
        };

        obj_interface.draw(Piece.View.PlayViewport);
    }

    // Right viewport
    _ = c.SDL_RenderSetViewport(self.renderer.?, &Self.right_viewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer.?, 0x00, 0x00, 0x00, 0xFF);
    _ = c.SDL_RenderFillRect(self.renderer.?, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    // Level viewport
    _ = c.SDL_RenderSetViewport(self.renderer.?, &Self.level_viewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer.?, 0xFF, 0xFF, 0xFF, 0xFF);
    _ = c.SDL_RenderFillRect(self.renderer.?, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    var txt_width = self.bitmap_font.calculateTextWidth("Level");
    self.bitmap_font.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 45, "Level");

    var level_txt = try std.fmt.allocPrintZ(self.allocator, "{d}", .{Self.Level});
    txt_width = self.bitmap_font.calculateTextWidth(level_txt);
    self.bitmap_font.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 80, level_txt);

    // Score viewport
    _ = c.SDL_RenderSetViewport(self.renderer.?, &Self.score_viewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer.?, 0xFF, 0xFF, 0xFF, 0xFF);
    _ = c.SDL_RenderFillRect(self.renderer.?, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    txt_width = self.bitmap_font.calculateTextWidth("Score");
    self.bitmap_font.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 45, "Score");

    var score_txt = try std.fmt.allocPrintZ(self.allocator, "{d}", .{Self.Score});
    txt_width = self.bitmap_font.calculateTextWidth(score_txt);
    self.bitmap_font.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 80, score_txt);

    // Tetromino viewport
    _ = c.SDL_RenderSetViewport(self.renderer.?, &Self.tetromino_viewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer.?, 0xFF, 0xFF, 0xFF, 0xFF);
    _ = c.SDL_RenderFillRect(self.renderer.?, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    // Draw next incoming piece
    Piece.next_piece.interface.draw(Piece.View.TetrominoViewport);

    _ = c.SDL_RenderPresent(self.renderer.?);
}

pub fn close(self: Self) void {
    c.SDL_DestroyWindow(self.window.?);
    c.SDL_DestroyRenderer(self.renderer.?);
}
