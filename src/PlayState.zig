const std = @import("std");
const err = std.log.err;
const c = @import("sdl.zig");

const Timer = @import("Timer.zig");
const Board = @import("Board.zig");
const Piece = @import("Piece.zig");
const BitmapFont = @import("BitmapFont.zig");
const Font = @import("Font.zig");
const constant = @import("constant.zig");
const StateInterfce = @import("interface.zig").StateInterface;
const Statemachine = @import("StateMachine.zig");
const PauseState = @import("PauseState.zig");
const GameOverState = @import("GameOverState.zig");

const Entity = enum { Board, Piece };
const Element = struct { typ: Entity, obj: *const c_void };
const Self = @This();

level: u8 = 1,
score: u32 = 0,
cap_timer: Timer = undefined,
window: *c.SDL_Window = null,
elements: [2]Element = undefined,
renderer: *c.SDL_Renderer = null,
allocator: *std.mem.Allocator = undefined,
info_font: BitmapFont = undefined,
interface: StateInterfce = undefined,
state_machine: *Statemachine = undefined,
drop_sound: *c.Mix_Chunk = undefined,
clear_sound: *c.Mix_Chunk = undefined,
bg_music: *c.Mix_Music = undefined,

pub fn init(allocator: *std.mem.Allocator, window: *c.SDL_Window, renderer: *c.SDL_Renderer, state_machine: *Statemachine) !*Self {
    var self = try allocator.create(Self);

    self.* = Self{
        .allocator = allocator,
        .window = window,
        .renderer = renderer,
        .info_font = try BitmapFont.init(renderer, "res/Futura.ttf", 25),
        .cap_timer = Timer.init(),
        .interface = StateInterfce.init(updateFn, renderFn, onEnterFn, onExitFn, inputFn, stateIDFn),
        .state_machine = state_machine,
    };

    var ptr_board = try allocator.create(Board);
    ptr_board.* = Board.init(self.renderer); // Need to do this, so Board is allocated on the Heap

    var ptr_piece = try allocator.create(Piece);
    ptr_piece.* = try Piece.randomPiece(self.renderer, &self.score); // Need to do this, so Board is allocated on the Heap

    self.drop_sound = c.Mix_LoadWAV("res/drop.wav") orelse {
        std.log.err("Failed to load drop sound effect! SDL_mixer Error: {s}\n", .{c.Mix_GetError()});
        return error.ERROR_LOAD_WAV;
    };

    self.clear_sound = c.Mix_LoadWAV("res/clear.wav") orelse {
        std.log.err("Failed to load clear sound effect! SDL_mixer Error: {s}\n", .{c.Mix_GetError()});
        return error.ERROR_LOAD_WAV;
    };

    self.bg_music = c.Mix_LoadMUS("res/play.mp3") orelse {
        std.log.err("Failed to load background music! SDL_mixer Error: {s}\n", .{c.Mix_GetError()});
        return error.ERROR_LOAD_WAV;
    };

    self.elements = .{
        // .{ .typ = .Board, .obj = &Board.init(self.renderer.?) }, // Not working, cause this allocated Board on the Stack
        // .{ .typ = .Piece, .obj = &try Piece.randomPiece(self.renderer.?, aBoard) }, // Not working, cause this allocated Piece on the Stack
        .{ .typ = .Board, .obj = ptr_board },
        .{ .typ = .Piece, .obj = ptr_piece },
    };

    return self;
}

fn inputFn(child: *StateInterfce) !void {
    var self = @fieldParentPtr(Self, "interface", child);
    var evt: c.SDL_Event = undefined;

    var piece = for (self.elements) |elem| {
        if (elem.typ == .Piece) {
            break @intToPtr(*Piece, @ptrToInt(elem.obj));
        }
    } else unreachable;

    var board = for (self.elements) |elem| {
        if (elem.typ == .Board) {
            break @intToPtr(*Board, @ptrToInt(elem.obj));
        }
    } else unreachable;

    while (c.SDL_PollEvent(&evt) > 0) {
        switch (evt.type) {
            c.SDL_QUIT => {
                std.os.exit(0);
            },

            c.SDL_KEYDOWN => switch (evt.key.keysym.sym) {
                c.SDLK_ESCAPE => {
                    var pause_state = try self.allocator.create(*PauseState);
                    pause_state.* = try PauseState.init(self.allocator, self.window, self.renderer, self.state_machine);
                    try self.state_machine.pushState(&pause_state.*.*.interface);
                },
                c.SDLK_SPACE => {
                    _ = try piece.hardDrop(board, self.drop_sound, self.clear_sound);
                },
                c.SDLK_UP => {
                    if (evt.key.repeat == 0) {
                        piece.rotate(board);
                    }
                },
                c.SDLK_DOWN => {
                    if ((try piece.moveDown(board, self.drop_sound, self.clear_sound)) == false) {
                        var game_over_state = try self.allocator.create(*GameOverState);
                        game_over_state.* = try GameOverState.init(self.allocator, self.window, self.renderer, self.state_machine);
                        try self.state_machine.pushState(&game_over_state.*.*.interface);
                    }
                },
                c.SDLK_LEFT => piece.moveLeft(board),
                c.SDLK_RIGHT => piece.moveRight(board),
                else => {},
            },
            else => {},
        }
    }
}

fn updateFn(child: *StateInterfce) !void {
    var self = @fieldParentPtr(Self, "interface", child);

    var p = for (self.elements) |elem| {
        if (elem.typ == .Piece) {
            break @intToPtr(*Piece, @ptrToInt(elem.obj));
        }
    } else unreachable;

    var b = for (self.elements) |elem| {
        if (elem.typ == .Board) {
            break @intToPtr(*Board, @ptrToInt(elem.obj));
        }
    } else unreachable;

    const elapsed_time = self.cap_timer.getTicks();
    if (elapsed_time >= 1000) {
        if ((try p.moveDown(b, self.drop_sound, self.clear_sound)) == false) {
            var game_over_state = try self.allocator.create(*GameOverState);
            game_over_state.* = try GameOverState.init(self.allocator, self.window, self.renderer, self.state_machine);
            try self.state_machine.pushState(&game_over_state.*.*.interface);
        }

        self.cap_timer.startTimer();
    }

    Piece.eraseLine(b);
}

fn renderFn(child: *StateInterfce) !void {
    var self = @fieldParentPtr(Self, "interface", child);
    _ = c.SDL_SetRenderDrawColor(self.renderer, 0x00, 0x00, 0x00, 0x00);
    _ = c.SDL_RenderClear(self.renderer);

    // Left viewport
    _ = c.SDL_RenderSetViewport(self.renderer, &constant.LeftViewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer, 0x00, 0x00, 0x00, 0x00);
    _ = c.SDL_RenderFillRect(self.renderer, &.{ .x = 0, .y = 0, .w = 360, .h = constant.SCREEN_HEIGHT });

    // Play viewport
    _ = c.SDL_RenderSetViewport(self.renderer, &constant.PlayViewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer, 0x00, 0xFF, 0x00, 0xFF);
    _ = c.SDL_RenderDrawRect(self.renderer, &.{
        .x = 0,
        .y = 0,
        .w = 300,
        .h = constant.SCREEN_HEIGHT - constant.BLOCK * 2,
    });

    for (self.elements) |e| {
        var object = switch (e.typ) {
            .Board => &(@intToPtr(*Board, @ptrToInt(e.obj))).interface,
            .Piece => &(@intToPtr(*Piece, @ptrToInt(e.obj))).interface,
        };

        object.draw(Piece.View.PlayViewport);
    }

    // Right viewport
    _ = c.SDL_RenderSetViewport(self.renderer, &constant.RightViewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer, 0x00, 0x00, 0x00, 0xFF);
    _ = c.SDL_RenderFillRect(self.renderer, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    // Level viewport
    _ = c.SDL_RenderSetViewport(self.renderer, &constant.LevelViewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer, 0xFF, 0xFF, 0xFF, 0xFF);
    _ = c.SDL_RenderFillRect(self.renderer, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    var txt_width = self.info_font.calculateTextWidth("Level");
    try self.info_font.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 55, "Level", 255, 0, 0);

    var level_txt = try std.fmt.allocPrintZ(self.allocator, "{d}", .{self.level});
    txt_width = self.info_font.calculateTextWidth(level_txt);
    try self.info_font.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 95, level_txt, 255, 0, 0);

    // Score viewport
    _ = c.SDL_RenderSetViewport(self.renderer, &constant.ScoreViewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer, 0xFF, 0xFF, 0xFF, 0xFF);
    _ = c.SDL_RenderFillRect(self.renderer, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    txt_width = self.info_font.calculateTextWidth("Score");
    try self.info_font.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 55, "Score", 255, 0, 0);

    var score_txt = try std.fmt.allocPrintZ(self.allocator, "{d}", .{self.score});
    txt_width = self.info_font.calculateTextWidth(score_txt);
    try self.info_font.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 95, score_txt, 255, 0, 0);

    // Tetromino viewport
    _ = c.SDL_RenderSetViewport(self.renderer, &constant.TetrominoViewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer, 0xFF, 0xFF, 0xFF, 0xFF);
    _ = c.SDL_RenderFillRect(self.renderer, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    // Draw next incoming piece
    Piece.next_piece.?.interface.draw(Piece.View.TetrominoViewport);

    _ = c.SDL_RenderPresent(self.renderer);
}

fn onEnterFn(child: *StateInterfce) !bool {
    var self = @fieldParentPtr(Self, "interface", child);
    self.cap_timer.startTimer();

    if (c.Mix_PlayingMusic() == 0) {
        // Play the music
        _ = c.Mix_PlayMusic(self.bg_music, -1);
    }
    // If music is being played
    else {
        // If the music is paused
        if (c.Mix_PausedMusic() == 1) {
            // Resume the music
            c.Mix_ResumeMusic();
        }
    }

    return true;
}

fn onExitFn(child: *StateInterfce) !bool {
    var self = @fieldParentPtr(Self, "interface", child);
    _ = self;

    if (c.Mix_PlayingMusic() != 0) {
        c.Mix_PauseMusic();
    }

    return true;
}

fn stateIDFn(child: *StateInterfce) []const u8 {
    var self = @fieldParentPtr(Self, "interface", child);
    _ = self;
    return "Play";
}

pub fn close(self: Self) void {
    c.SDL_DestroyWindow(self.window);
    c.SDL_DestroyRenderer(self.renderer);

    c.Mix_FreeChunk(self.drop_sound);
    c.Mix_FreeChunk(self.clear_sound);
}
