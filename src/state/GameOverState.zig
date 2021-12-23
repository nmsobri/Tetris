const std = @import("std");
const err = std.log.err;
const c = @import("../sdl.zig");

const Timer = @import("../lib/Timer.zig");
const Board = @import("../Board.zig");
const Piece = @import("../Piece.zig");
const BitmapFont = @import("../lib/BitmapFont.zig");
const Texture = @import("../lib/Texture.zig");
const constant = @import("../constant.zig");
const StateInterface = @import("../interface.zig").StateInterface;
const StateMachine = @import("../lib/StateMachine.zig");
const PlayState = @import("PlayState.zig");

const Entity = enum { Board, Piece };
const Element = struct { typ: Entity, obj: *const anyopaque };
const Self = @This();

window: *c.SDL_Window = null,
renderer: *c.SDL_Renderer = null,
allocator: std.mem.Allocator = undefined,
interface: StateInterface = undefined,
state_machine: *StateMachine = undefined,
play_state: *PlayState = undefined,
font_info: BitmapFont = undefined,
extra_info_font: BitmapFont = undefined,

pub fn init(allocator: std.mem.Allocator, window: *c.SDL_Window, renderer: *c.SDL_Renderer, state_machine: *StateMachine) !*Self {
    var self = try allocator.create(Self);

    self.* = Self{
        .window = window,
        .renderer = renderer,
        .allocator = allocator,
        .interface = StateInterface.init(updateFn, renderFn, onEnterFn, onExitFn, inputFn, stateIDFn),
        .state_machine = state_machine,
        .font_info = try BitmapFont.init(renderer, "res/Futura.ttf", 50),
        .extra_info_font = try BitmapFont.init(renderer, "res/Futura.ttf", 20),
    };

    return self;
}

fn inputFn(child: *StateInterface) !void {
    var self = @fieldParentPtr(Self, "interface", child);
    _ = self;
    var evt: c.SDL_Event = undefined;

    while (c.SDL_PollEvent(&evt) > 0) {
        switch (evt.type) {
            c.SDL_QUIT => {
                std.os.exit(0);
            },

            c.SDL_KEYDOWN => switch (evt.key.keysym.sym) {
                c.SDLK_ESCAPE => std.os.exit(0),
                c.SDLK_RETURN, c.SDLK_KP_ENTER => {
                    var play_state = try self.allocator.create(*PlayState);
                    play_state.* = try PlayState.init(self.allocator, self.window, self.renderer, self.state_machine);
                    try self.state_machine.popState(); // pop game over state
                    try self.state_machine.popState(); // pop play state
                    try self.state_machine.changeState(&play_state.*.*.interface);
                },
                else => {},
            },
            else => {},
        }
    }
}

fn updateFn(child: *StateInterface) !void {
    var self = @fieldParentPtr(Self, "interface", child);
    _ = self;
}

fn renderFn(child: *StateInterface) !void {
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

    var board = for (self.play_state.elements) |elem| {
        if (elem.typ == .Board) {
            break @intToPtr(*Board, @ptrToInt(elem.obj));
        }
    } else unreachable;

    board.interface.draw(Piece.View.PlayViewport);

    var txt_width = self.font_info.calculateTextWidth("Game Over!");
    try self.font_info.renderText(@intCast(c_int, ((constant.BLOCK * 10) - txt_width) / 2), @intCast(c_int, (constant.BLOCK * constant.ROW / 2) - self.font_info.getGlyphHeight() * 2), "Game Over!", 255, 0, 0);

    txt_width = self.extra_info_font.calculateTextWidth("Press Enter To Restart");
    try self.extra_info_font.renderText(@intCast(c_int, ((constant.BLOCK * 10) - txt_width) / 2), @intCast(c_int, (constant.BLOCK * constant.ROW / 2) - self.font_info.getGlyphHeight()), "Press Enter To Restart", 255, 0, 0);

    // Right viewport
    _ = c.SDL_RenderSetViewport(self.renderer, &constant.RightViewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer, 0x00, 0x00, 0x00, 0xFF);
    _ = c.SDL_RenderFillRect(self.renderer, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    // Level viewport
    _ = c.SDL_RenderSetViewport(self.renderer, &constant.LevelViewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer, 0xFF, 0xFF, 0xFF, 0xFF);
    _ = c.SDL_RenderFillRect(self.renderer, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    txt_width = self.play_state.font_info.calculateTextWidth("Level");
    try self.play_state.font_info.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 35, "Level", 255, 0, 0);

    var level_txt = try std.fmt.allocPrintZ(self.allocator, "{d}", .{self.play_state.level});
    txt_width = self.play_state.font_info.calculateTextWidth(level_txt);
    try self.play_state.font_info.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 75, level_txt, 255, 0, 0);

    // Score viewport
    _ = c.SDL_RenderSetViewport(self.renderer, &constant.ScoreViewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer, 0xFF, 0xFF, 0xFF, 0xFF);
    _ = c.SDL_RenderFillRect(self.renderer, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    txt_width = self.play_state.font_info.calculateTextWidth("Score");
    try self.play_state.font_info.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 35, "Score", 255, 0, 0);

    var score_txt = try std.fmt.allocPrintZ(self.allocator, "{d}", .{self.play_state.score});
    txt_width = self.play_state.font_info.calculateTextWidth(score_txt);
    try self.play_state.font_info.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 75, score_txt, 255, 0, 0);

    // Line viewport
    _ = c.SDL_RenderSetViewport(self.renderer, &constant.LineViewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer, 0xFF, 0xFF, 0xFF, 0xFF);
    _ = c.SDL_RenderFillRect(self.renderer, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    txt_width = self.play_state.font_info.calculateTextWidth("Line");
    try self.play_state.font_info.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 35, "Line", 255, 0, 0);

    var line_txt = try std.fmt.allocPrintZ(self.allocator, "{d}", .{self.play_state.line});
    txt_width = self.play_state.font_info.calculateTextWidth(line_txt);
    try self.play_state.font_info.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 75, line_txt, 255, 0, 0);

    // Tetromino viewport
    _ = c.SDL_RenderSetViewport(self.renderer, &constant.TetrominoViewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer, 0xFF, 0xFF, 0xFF, 0xFF);
    _ = c.SDL_RenderFillRect(self.renderer, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    // Draw next incoming piece
    Piece.next_piece.?.interface.draw(Piece.View.TetrominoViewport);

    _ = c.SDL_RenderPresent(self.renderer);
}

fn onEnterFn(child: *StateInterface) !bool {
    var self = @fieldParentPtr(Self, "interface", child);

    var play_state_interface = self.state_machine.states.items[self.state_machine.states.items.len - 2];
    var play_state = @fieldParentPtr(PlayState, "interface", play_state_interface);

    var board = for (play_state.elements) |elem| {
        if (elem.typ == .Board) {
            break @intToPtr(*Board, @ptrToInt(elem.obj));
        }
    } else unreachable;

    // Change the color of every tetrominoes to show obvious game over state
    var row: usize = 0;
    while (row < constant.ROW) : (row += 1) {
        var col: usize = 0;

        while (col < constant.COL) : (col += 1) {
            if (board.board[row][col] != null) {
                board.board[row][col] = .{ 150, 150, 150 };
            }
        }
    }

    self.play_state = play_state;
    return true;
}

fn onExitFn(child: *StateInterface) !bool {
    var self = @fieldParentPtr(Self, "interface", child);
    _ = self;
    return true;
}

fn stateIDFn(child: *StateInterface) []const u8 {
    var self = @fieldParentPtr(Self, "interface", child);
    _ = self;
    return "Pause";
}

pub fn close(self: Self) void {
    c.SDL_DestroyWindow(self.window);
    c.SDL_DestroyRenderer(self.renderer);
}
