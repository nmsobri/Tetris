const std = @import("std");
const err = std.log.err;
const c = @import("sdl.zig");

const Font = @import("Font.zig");
const Timer = @import("Timer.zig");
const Board = @import("Board.zig");
const Piece = @import("Piece.zig");
const BitmapFont = @import("BitmapFont.zig");
const Texture = @import("Texture.zig");
const constant = @import("constant.zig");
const StateInterfce = @import("interface.zig").StateInterface;
const StateMachine = @import("StateMachine.zig");
const PlayState = @import("PlayState.zig");

const Entity = enum { Board, Piece };
const Element = struct { typ: Entity, obj: *const c_void };
const Self = @This();

const left_viewport: c.SDL_Rect = .{
    .x = 0,
    .y = 0,
    .w = constant.SCREEN_WIDTH,
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

window: *c.SDL_Window = null,
renderer: *c.SDL_Renderer = null,
allocator: *std.mem.Allocator = undefined,
interface: StateInterfce = undefined,
state_machine: *StateMachine = undefined,
play_state: *PlayState = undefined,
frame_count: u8 = 0,
font: Font = undefined,

pub fn init(allocator: *std.mem.Allocator, window: *c.SDL_Window, renderer: *c.SDL_Renderer, state_machine: *StateMachine) !*Self {
    var self = try allocator.create(Self);

    self.* = Self{
        .window = window,
        .renderer = renderer,
        .allocator = allocator,
        .interface = StateInterfce.init(updateFn, renderFn, onEnterFn, onExitFn, inputFn, stateIDFn),
        .state_machine = state_machine,
        .font = try Font.init(renderer, "res/Zector.ttf", 20, .{ .r = 255, .g = 255, .b = 255, .a = 255 }),
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
    _ = c.SDL_RenderSetViewport(self.renderer, &Self.left_viewport);
    _ = c.SDL_SetRenderDrawColor(self.renderer, 0x00, 0x00, 0x00, 0x00);
    _ = c.SDL_RenderFillRect(self.renderer, &.{ .x = 0, .y = 0, .w = 360, .h = constant.SCREEN_HEIGHT });

    // Play viewport
    // _ = c.SDL_RenderSetViewport(self.renderer, &Self.play_viewport);
    // _ = c.SDL_SetRenderDrawColor(self.renderer, 0x00, 0xFF, 0x00, 0xFF);
    // _ = c.SDL_RenderDrawRect(self.renderer, &.{
    //     .x = 0,
    //     .y = 0,
    //     .w = 300,
    //     .h = constant.SCREEN_HEIGHT - constant.BLOCK * 2,
    // });

    // for (self.play_state.elements) |e| {
    //     var object = switch (e.typ) {
    //         .Board => &(@intToPtr(*Board, @ptrToInt(e.obj))).interface,
    //         .Piece => &(@intToPtr(*Piece, @ptrToInt(e.obj))).interface,
    //     };

    //     object.draw(Piece.View.PlayViewport);
    // }

    self.frame_count += 1;
    if (self.frame_count <= 25) {
        self.play_state.bitmap_font.renderText(45, 45, "Pause!");
    } else if (self.frame_count >= 50) {
        self.frame_count = 0;
    }

    self.play_state.bitmap_font.renderText(45, 105, "Pause!");
    self.font.render(0, 200, null, 0, null, null, .{});

    // Right viewport
    // _ = c.SDL_RenderSetViewport(self.renderer, &Self.right_viewport);
    // _ = c.SDL_SetRenderDrawColor(self.renderer, 0x00, 0x00, 0x00, 0xFF);
    // _ = c.SDL_RenderFillRect(self.renderer, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    // // Level viewport
    // _ = c.SDL_RenderSetViewport(self.renderer, &Self.level_viewport);
    // _ = c.SDL_SetRenderDrawColor(self.renderer, 0xFF, 0xFF, 0xFF, 0xFF);
    // _ = c.SDL_RenderFillRect(self.renderer, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    // var txt_width = self.play_state.bitmap_font.calculateTextWidth("Level");
    // self.play_state.bitmap_font.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 45, "Level");

    // var level_txt = try std.fmt.allocPrintZ(self.allocator, "{d}", .{self.play_state.level});
    // txt_width = self.play_state.bitmap_font.calculateTextWidth(level_txt);
    // self.play_state.bitmap_font.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 80, level_txt);

    // // Score viewport
    // _ = c.SDL_RenderSetViewport(self.renderer, &Self.score_viewport);
    // _ = c.SDL_SetRenderDrawColor(self.renderer, 0xFF, 0xFF, 0xFF, 0xFF);
    // _ = c.SDL_RenderFillRect(self.renderer, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    // txt_width = self.play_state.bitmap_font.calculateTextWidth("Score");
    // self.play_state.bitmap_font.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 45, "Score");

    // var score_txt = try std.fmt.allocPrintZ(self.allocator, "{d}", .{self.play_state.score});
    // txt_width = self.play_state.bitmap_font.calculateTextWidth(score_txt);
    // self.play_state.bitmap_font.renderText(@intCast(c_int, (constant.VIEWPORT_INFO_WIDTH - txt_width) / 2), 80, score_txt);

    // // Tetromino viewport
    // _ = c.SDL_RenderSetViewport(self.renderer, &Self.tetromino_viewport);
    // _ = c.SDL_SetRenderDrawColor(self.renderer, 0xFF, 0xFF, 0xFF, 0xFF);
    // _ = c.SDL_RenderFillRect(self.renderer, &.{ .x = 0, .y = 0, .w = constant.BLOCK * 6, .h = constant.SCREEN_HEIGHT });

    // // Draw next incoming piece
    // Piece.next_piece.?.interface.draw(Piece.View.TetrominoViewport);

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
