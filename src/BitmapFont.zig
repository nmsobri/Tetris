const Font = @import("Font.zig");
const c = @import("sdl.zig");
const std = @import("std");

const Self = @This();
const NUM_GLYPHS = 127;
const FONT_TEXTURE_SIZE = 1000;

font: *c.TTF_Font = undefined,
texture: ?*c.SDL_Texture = null,
renderer: *c.SDL_Renderer = undefined,
glyphs: [NUM_GLYPHS]c.SDL_Rect = undefined,

pub fn init(renderer: *c.SDL_Renderer, path: []const u8, size: u8) !Self {
    if (c.TTF_Init() == -1) {
        std.log.err("SDL_ttf could not initialize! SDL_ttf Error: {s}\n", .{c.TTF_GetError()});
        return error.ERROR_TTF_INIT;
    }

    var s = Self{ .renderer = renderer };
    try s.initFont(path, size);
    return s;
}

pub fn initFont(self: *Self, path: []const u8, size: u8) !void {
    // Zeroes the glyphys
    @memset(@ptrCast([*]align(4) u8, &self.glyphs), 0, (@sizeOf(c.SDL_Rect) * NUM_GLYPHS));

    self.font = c.TTF_OpenFont(path.ptr, size) orelse {
        std.log.err("Failed to load font! SDL_ttf Error: {s}\n", .{c.TTF_GetError()});
        return error.ERROR_OPEN_FONT;
    };

    var surface: *c.SDL_Surface = undefined;

    if (c.SDL_BYTEORDER == c.SDL_BIG_ENDIAN) {
        surface = c.SDL_CreateRGBSurface(0, FONT_TEXTURE_SIZE, FONT_TEXTURE_SIZE, 32, 0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF);
    } else {
        surface = c.SDL_CreateRGBSurface(0, FONT_TEXTURE_SIZE, FONT_TEXTURE_SIZE, 32, 0x000000FF, 0x0000FF00, 0x00FF0000, 0xFF000000);
    }

    defer c.SDL_FreeSurface(surface);

    if (c.SDL_SetColorKey(surface, c.SDL_TRUE, c.SDL_MapRGBA(surface.*.format, 0, 0, 0, 0)) != 0) {
        std.log.err("Failed to set color key for font! SDL Error: {s}\n", .{c.SDL_GetError()});
        return error.ERROR_SET_COLOR_KEY;
    }

    var dest: c.SDL_Rect = .{ .x = 0, .y = 0, .w = 0, .h = 0 };

    var i: u8 = ' ';
    while (i <= '~') : (i += 1) {
        var ch = [_]u8{ i, 0 };
        const text = c.TTF_RenderUTF8_Blended(self.font, &ch, .{ .r = 255, .g = 255, .b = 255, .a = 255 });
        defer c.SDL_FreeSurface(text);

        if (c.TTF_SizeText(self.font, &ch, &dest.w, &dest.h) != 0) {
            std.log.err("Failed to get font text size! SDL_ttf Error: {s}\n", .{c.TTF_GetError()});
            return error.ERROR_SET_COLOR_KEY;
        }

        if (dest.x + dest.w >= FONT_TEXTURE_SIZE) {
            dest.x = 0;
            dest.y += dest.h + 1;

            if (dest.y + dest.h >= FONT_TEXTURE_SIZE) {
                std.log.err("Out of glyph space in {d}x{d} font atlas texture map.\n", .{ FONT_TEXTURE_SIZE, FONT_TEXTURE_SIZE });
                std.os.exit(1);
            }
        }

        if (c.SDL_BlitSurface(text, null, surface, &dest) != 0) {
            std.log.err("Failed to blit font to the surface! SDL Error: {s}\n", .{c.SDL_GetError()});
            return error.ERROR_BLIT_ERROR;
        }

        self.glyphs[i] = .{ .x = dest.x, .y = dest.y, .w = dest.w, .h = dest.h };
        dest.x += dest.w; // Advance the glyph position
    }

    self.texture = c.SDL_CreateTextureFromSurface(self.renderer, surface);
}

pub fn renderText(self: *Self, _x: c_int, _y: c_int, text: []const u8, r: u8, g: u8, b: u8) !void {
    // If the font has not been built
    if (self.texture == null) return;

    var x = _x;
    var y = _y;

    if (c.SDL_SetTextureColorMod(self.texture.?, r, g, b) != 0) {
        std.log.err("Failed to set texture font color! SDL Error: {s}\n", .{c.SDL_GetError()});
        return error.ERROR_COLOR_MOD;
    }

    var i: u8 = 0;
    while (i < text.len) : (i += 1) {
        const ascii = text[i];
        const glyph = &self.glyphs[ascii];

        const dest: c.SDL_Rect = .{ .x = x, .y = y, .w = glyph.w, .h = glyph.h };

        if (c.SDL_RenderCopy(self.renderer, self.texture, glyph, &dest) != 0) {
            std.log.err("Failed to render texture! SDL Error: {s}\n", .{c.SDL_GetError()});
            return error.ERROR_RENDER_TEXTURE;
        }

        x += glyph.w;
    }
}

pub fn calculateTextWidth(self: Self, text: []const u8) u32 {
    var width: u32 = 0;

    var i: usize = 0;
    while (i < text.len) : (i += 1) {
        if (text[i] != '\n') {
            const ascii = text[i];
            width += @intCast(u32, self.glyphs[ascii].w);
        }
    }

    return width;
}
