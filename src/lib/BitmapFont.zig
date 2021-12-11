const Font = @import("Font.zig");
const c = @import("../sdl.zig");
const std = @import("std");

const Self = @This();
const NUM_GLYPHS = 127;

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
        std.log.err("Failed to load font! Sdl_ttf Error: {s}\n", .{c.TTF_GetError()});
        return error.error_open_font;
    };

    var width: c_int = 0;
    var height: c_int = 0;

    if (c.TTF_SizeText(
        self.font,
        "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~",
        &width,
        &height,
    ) != 0) {
        std.log.err("Failed to calculate font surface area! Sdl_ttf Error: {s}\n", .{c.TTF_GetError()});
        return error.error_open_font;
    }

    var surface: *c.SDL_Surface = undefined;

    if (c.SDL_BYTEORDER == c.SDL_BIG_ENDIAN) {
        surface = c.SDL_CreateRGBSurface(
            0,
            width,
            height,
            32,
            0xFF000000,
            0x00FF0000,
            0x0000FF00,
            0x000000FF,
        );
    } else {
        surface = c.SDL_CreateRGBSurface(
            0,
            width,
            height,
            32,
            0x000000FF,
            0x0000FF00,
            0x00FF0000,
            0xFF000000,
        );
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
            return error.ERROR_GET_FONT_SIZE;
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

    var x: u32 = @intCast(u32, _x);
    var y: u32 = @intCast(u32, _y);

    if (c.SDL_SetTextureColorMod(self.texture.?, r, g, b) != 0) {
        std.log.err("Failed to set texture font color! SDL Error: {s}\n", .{c.SDL_GetError()});
        return error.ERROR_COLOR_MOD;
    }

    var i: u8 = 0;
    while (i < text.len) : (i += 1) {
        if (text[i] == '\n') {
            x = @intCast(u32, _x);
            y += self.getGlyphHeight();
            continue;
        }

        const ascii = text[i];
        const glyph = &self.glyphs[ascii];
        const dest: c.SDL_Rect = .{ .x = @intCast(c_int, x), .y = @intCast(c_int, y), .w = glyph.w, .h = glyph.h };

        if (c.SDL_RenderCopy(self.renderer, self.texture, glyph, &dest) != 0) {
            std.log.err("Failed to render texture! SDL Error: {s}\n", .{c.SDL_GetError()});
            return error.ERROR_RENDER_TEXTURE;
        }

        x += @intCast(u32, glyph.w);
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

pub fn getGlyphs(self: Self) [NUM_GLYPHS]c.SDL_Rect {
    return self.glyphs;
}

pub fn getGlyphHeight(self: Self) u32 {
    // Use `A` glyph height as out baseline for all of the glyph
    return @intCast(u32, self.glyphs[65].h);
}
