const std = @import("std");
const err = std.log.err;
const c = @import("sdl.zig");

const Timer = @import("Timer.zig");
const Board = @import("Board.zig");
const Piece = @import("Piece.zig");
const BitmapFont = @import("BitmapFont.zig");
const Font = @import("Font.zig");
const constant = @import("constant.zig");
const StateInterface = @import("interface.zig").StateInterface;
const StateMachine = @import("StateMachine.zig");
const PlayState = @import("PlayState.zig");

const Entity = enum { Board, Piece };
const Element = struct { typ: Entity, obj: *const c_void };
const Self = @This();

window: *c.SDL_Window = null,
renderer: *c.SDL_Renderer = null,
font_info: BitmapFont = undefined,
font_logo: BitmapFont = undefined,
font_credit: BitmapFont = undefined,
allocator: *std.mem.Allocator = undefined,
interface: StateInterface = undefined,
state_machine: *StateMachine = undefined,
board: Board = undefined,

pub fn init(allocator: *std.mem.Allocator, window: *c.SDL_Window, renderer: *c.SDL_Renderer, state_machine: *StateMachine) !*Self {
    var self = try allocator.create(Self);

    self.* = Self{
        .window = window,
        .renderer = renderer,
        .font_info = try BitmapFont.init(renderer, "res/Futura.ttf", 25),
        .font_logo = try BitmapFont.init(renderer, "res/Futura.ttf", 90),
        .font_credit = try BitmapFont.init(renderer, "res/Futura.ttf", 15),
        .allocator = allocator,
        .interface = StateInterface.init(updateFn, renderFn, onEnterFn, onExitFn, inputFn, stateIDFn),
        .state_machine = state_machine,
        .board = Board.init(renderer),
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

    self.board.interface.draw(Piece.View.PlayViewport);
    var txt_width = self.font_logo.calculateTextWidth("Tetriz");
    try self.font_logo.renderText(@intCast(c_int, ((constant.BLOCK * 10) - txt_width) / 2), 75, "Tetriz", 0, 255, 0);

    txt_width = self.font_info.calculateTextWidth("Press Enter To Play");
    try self.font_info.renderText(@intCast(c_int, ((constant.BLOCK * 10) - txt_width) / 2), 185, "Press Enter To Play", 0, 0, 255);

    txt_width = self.font_credit.calculateTextWidth("(C) Sobri 2021");
    try self.font_credit.renderText(@intCast(c_int, ((constant.BLOCK * 10) - txt_width) / 2), constant.SCREEN_HEIGHT - 110, "(C) Sobri 2021", 0, 0, 0);

    // // Right viewport
    _ = c.SDL_RenderSetViewport(self.renderer, &constant.RightViewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer, 0x00, 0x00, 0x00, 0xFF);
    _ = c.SDL_RenderFillRect(self.renderer, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    // Level viewport
    _ = c.SDL_RenderSetViewport(self.renderer, &constant.LevelViewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer, 0xFF, 0xFF, 0xFF, 0xFF);
    _ = c.SDL_RenderFillRect(self.renderer, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    txt_width = self.font_info.calculateTextWidth("Level");
    try self.font_info.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 55, "Level", 255, 0, 0);

    var level_txt = try std.fmt.allocPrintZ(self.allocator, "{d}", .{1});
    txt_width = self.font_info.calculateTextWidth(level_txt);
    try self.font_info.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 95, level_txt, 255, 0, 0);

    // Score viewport
    _ = c.SDL_RenderSetViewport(self.renderer, &constant.ScoreViewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer, 0xFF, 0xFF, 0xFF, 0xFF);
    _ = c.SDL_RenderFillRect(self.renderer, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    txt_width = self.font_info.calculateTextWidth("Score");
    try self.font_info.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 55, "Score", 255, 0, 0);

    var score_txt = try std.fmt.allocPrintZ(self.allocator, "{d}", .{0});
    txt_width = self.font_info.calculateTextWidth(score_txt);
    try self.font_info.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 95, score_txt, 255, 0, 0);

    // Tetromino viewport
    _ = c.SDL_RenderSetViewport(self.renderer, &constant.TetrominoViewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer, 0xFF, 0xFF, 0xFF, 0xFF);
    _ = c.SDL_RenderFillRect(self.renderer, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    // Draw incoming piece
    try Piece.drawRandomPiece(self.renderer, Piece.View.TetrominoViewport);

    _ = c.SDL_RenderPresent(self.renderer);
}

fn onEnterFn(child: *StateInterface) !bool {
    var self = @fieldParentPtr(Self, "interface", child);
    _ = self;
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
