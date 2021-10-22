const c = @import("sdl.zig");
const std = @import("std");
const constant = @import("constant.zig");

pub fn DrawMixin(comptime T: type) type {
    return struct {
        pub fn _draw(self: T, x: c_int, y: c_int, color: [3]u8) void {
            _ = c.SDL_SetRenderDrawColor(
                self.renderer,
                color[0],
                color[1],
                color[2],
                255,
            );

            _ = c.SDL_RenderFillRect(self.renderer, &.{
                .x = x,
                .y = y,
                .w = constant.BLOCK,
                .h = constant.BLOCK,
            });

            _ = c.SDL_SetRenderDrawColor(
                self.renderer,
                0,
                0,
                0,
                255,
            );

            _ = c.SDL_RenderDrawRect(self.renderer, &.{
                .x = x,
                .y = y,
                .w = constant.BLOCK,
                .h = constant.BLOCK,
            });
        }
    };
}
