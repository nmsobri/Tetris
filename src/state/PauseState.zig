const std = @import("std");
const err = std.log.err;
const c = @import("../sdl.zig");

const Font = @import("../lib/Font.zig");
const Timer = @import("../lib/Timer.zig");
const Board = @import("../Board.zig");
const Piece = @import("../Piece.zig");
const BitmapFont = @import("../lib/BitmapFont.zig");
const Texture = @import("../lib/Texture.zig");
const constant = @import("../constant.zig");
const StateInterfce = @import("../interface.zig").StateInterface;
const StateMachine = @import("../lib/StateMachine.zig");
const PlayState = @import("PlayState.zig");

const Entity = enum { Board, Piece };
const Element = struct { typ: Entity, obj: *const c_void };
const Self = @This();

frame_count: u8 = 0,
window: *c.SDL_Window = null,
renderer: *c.SDL_Renderer = null,
allocator: *std.mem.Allocator = undefined,
interface: StateInterfce = undefined,
state_machine: *StateMachine = undefined,
play_state: *PlayState = undefined,

pub fn init(allocator: *std.mem.Allocator, window: *c.SDL_Window, renderer: *c.SDL_Renderer, state_machine: *StateMachine) !*Self {
    var self = try allocator.create(Self);

    self.* = Self{
        .window = window,
        .renderer = renderer,
        .allocator = allocator,
        .interface = StateInterfce.init(updateFn, renderFn, onEnterFn, onExitFn, inputFn, stateIDFn),
        .state_machine = state_machine,
    };

    return self;
}

fn inputFn(child: *StateInterfce) !void {
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
                    try self.state_machine.popState();
                },
                else => {},
            },
            else => {},
        }
    }
}

fn updateFn(child: *StateInterfce) !void {
    var self = @fieldParentPtr(Self, "interface", child);
    _ = self;
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

    for (self.play_state.elements) |e| {
        var object = switch (e.typ) {
            .Board => &(@intToPtr(*Board, @ptrToInt(e.obj))).interface,
            .Piece => &(@intToPtr(*Piece, @ptrToInt(e.obj))).interface,
        };

        object.draw(Piece.View.PlayViewport);
    }

    self.frame_count += 1;
    if (self.frame_count <= 25) {
        const txt_width = self.play_state.font_info.calculateTextWidth("Pause!");
        const xpos = @intCast(c_int, ((constant.BLOCK * 10) - txt_width) / 2);
        const ypos = (constant.BLOCK * 20 / 2) - @intCast(c_int, self.play_state.font_info.getGlyphHeight());
        try self.play_state.font_info.renderText(xpos, ypos, "Pause!", 0, 0, 255);
    } else if (self.frame_count >= 50) {
        self.frame_count = 0;
    }

    // Right viewport
    _ = c.SDL_RenderSetViewport(self.renderer, &constant.RightViewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer, 0x00, 0x00, 0x00, 0xFF);
    _ = c.SDL_RenderFillRect(self.renderer, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    // Level viewport
    _ = c.SDL_RenderSetViewport(self.renderer, &constant.LevelViewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer, 0xFF, 0xFF, 0xFF, 0xFF);
    _ = c.SDL_RenderFillRect(self.renderer, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    var txt_width = self.play_state.font_info.calculateTextWidth("Level");
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

fn onEnterFn(child: *StateInterfce) !bool {
    var self = @fieldParentPtr(Self, "interface", child);
    self.frame_count = 0;

    var play_state_interface = self.state_machine.states.items[self.state_machine.states.items.len - 2];
    var play_state = @fieldParentPtr(PlayState, "interface", play_state_interface);
    self.play_state = play_state;

    return true;
}

fn onExitFn(child: *StateInterfce) !bool {
    var self = @fieldParentPtr(Self, "interface", child);
    _ = self;
    return true;
}

fn stateIDFn(child: *StateInterfce) []const u8 {
    var self = @fieldParentPtr(Self, "interface", child);
    _ = self;
    return "Pause";
}

pub fn close(self: Self) void {
    c.SDL_DestroyWindow(self.window);
    c.SDL_DestroyRenderer(self.renderer);
}
