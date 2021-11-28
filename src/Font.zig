const std = @import("std");
const err = std.log.err;
const c = @import("sdl.zig");

const Self = @This();

pitch: c_int = undefined,
pixels: ?*c_void = undefined,
width: u32 = undefined,
height: u32 = undefined,
texture: ?*c.SDL_Texture = undefined,
renderer: *c.SDL_Renderer = undefined,

pub fn init(renderer: *c.SDL_Renderer, path: []const u8, size: u8, color: c.SDL_Color) !Self {
    if (c.TTF_Init() == -1) {
        err("SDL_ttf could not initialize! SDL_ttf Error: {s}\n", .{c.TTF_GetError()});
        return error.ERROR_TTF_INIT;
    }

    var s = Self{
        .pitch = 0,
        .pixels = null,
        .width = 0,
        .height = 0,
        .texture = null,
        .renderer = renderer,
    };

    try s.createFont(path, size, color);
    return s;
}

fn createFont(self: *Self, path: []const u8, size: u8, color: c.SDL_Color) !void {
    var font = c.TTF_OpenFont(path.ptr, size) orelse {
        err("Failed to load font! SDL_ttf Error: {s}\n", .{c.TTF_GetError()});
        return error.ERROR_OPEN_FONT;
    };

    c.TTF_SetFontKerning(font, 0); // Disable font kerning

    var text: []const u8 = "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";

    // Create font surface
    const surface: *c.SDL_Surface = c.TTF_RenderText_Blended(font, text.ptr, color) orelse {
        err("Unable to render text surface! SDL_ttf Error: {s}\n", .{c.TTF_GetError()});
        return error.ERROR_RENDER_TEXT;
    };

    defer c.SDL_FreeSurface(surface);

    // Reformat this image surface to be the same as window surface
    const formatted_surface: *c.SDL_Surface = c.SDL_ConvertSurfaceFormat(surface, c.SDL_PIXELFORMAT_RGBA8888, 0) orelse {
        err("Error: unable to convert loaded surface to display format! SDL Error: {s}\n", .{c.SDL_GetError()});
        return error.ERROR_REFORMAT_SURFACE;
    };

    defer c.SDL_FreeSurface(formatted_surface);

    const blank_texture = c.SDL_CreateTexture(self.renderer, c.SDL_PIXELFORMAT_RGBA8888, c.SDL_TEXTUREACCESS_STREAMING, formatted_surface.*.w, formatted_surface.*.h) orelse {
        err("Error: unable to create blank texture! SDL Error: {s}\n", .{c.SDL_GetError()});
        return error.ERROR_CREATE_TEXTURE;
    };

    // Need this, or else we couldnt modify the pixels, i dont know why, it work
    // if we do it externally
    _ = c.SDL_SetTextureBlendMode(blank_texture, c.SDL_BLENDMODE_BLEND);

    // Lock texture for modification
    if (c.SDL_LockTexture(blank_texture, null, &self.pixels, &self.pitch) != 0) {
        err("Error: unable to lock texture for modification! SDL Error: {s}\n", .{c.SDL_GetError()});
        return error.ERROR_LOCK_TEXTURE;
    }

    // Do something with the pixels
    // Copy pixels from loaded surface image to the blank texture
    @memcpy(
        @ptrCast([*]u8, @alignCast(@alignOf(u8), self.pixels.?)),
        @ptrCast([*]u8, @alignCast(@alignOf(u8), formatted_surface.*.pixels.?)),
        @intCast(usize, formatted_surface.*.pitch * formatted_surface.*.h),
    );

    // Unlock texture and update it
    c.SDL_UnlockTexture(blank_texture);
    self.pixels = null;

    self.width = @intCast(u32, formatted_surface.w);
    self.height = @intCast(u32, formatted_surface.h);
    self.texture = blank_texture;
}

pub fn render(
    self: Self,
    x: c_int,
    y: c_int,
    clip: ?*c.SDL_Rect,
    angle: f64,
    center: ?*c.SDL_Point,
    flip: ?c.SDL_RendererFlip,
    defaults: struct {
        flip: c.SDL_RendererFlip = c.SDL_FLIP_NONE,
    },
) void {
    var render_square: c.SDL_Rect = .{
        .x = x,
        .y = y,
        .w = @intCast(c_int, self.getWidth()), // assume full width of the texture
        .h = @intCast(c_int, self.getHeight()), // assume full height of the texture
    };

    if (clip != null) {
        render_square.w = clip.?.w; // since we are clipping the texture, change rendering width
        render_square.h = clip.?.h; // since we are clipping the texture, change rendering height
    }

    // Render to screen
    _ = c.SDL_RenderCopyEx(
        self.renderer,
        self.texture.?,
        clip orelse null,
        &render_square,
        angle,
        center orelse null,
        flip orelse defaults.flip,
    );
}

pub fn setColor(self: Self, red: u8, green: u8, blue: u8) void {
    _ = c.SDL_SetTextureColorMod(self.texture.?, red, green, blue);
}

pub fn setAlpha(self: Self, alpha: u16) void {
    _ = c.SDL_SetTextureAlphaMod(self.texture.?, @intCast(u8, alpha));
}

pub fn setBlendMode(self: Self, blend_mode: c.SDL_BlendMode) void {
    _ = c.SDL_SetTextureBlendMode(self.texture.?, blend_mode);
}

pub fn getWidth(self: Self) u32 {
    return self.width;
}

pub fn getHeight(self: Self) u32 {
    return self.height;
}

pub fn getTexture(self: Self) *c.SDL_Texture {
    return self.texture.?;
}

pub fn getPixels(self: Self) *c_void {
    return self.pixels.?;
}

pub fn getPixels32(self: Self, x: u32, y: u32) u32 {
    // Convert the pixels to 32 bit
    var pixels: [*]u32 = @ptrCast([*]u32, @alignCast(@alignOf(u32), self.pixels.?));
    const pixels_per_row = self.getPitch() / 4; // 1 pixels have 4 bytes

    // Get the pixel requested
    return pixels[y * pixels_per_row + x];
}

pub fn getPitch(self: Self) u32 {
    return @intCast(u32, self.pitch);
}

pub fn lockTexture(self: *Self) !void {
    if (self.pixels != null) {
        err("Texture already locked: SDL_ERROR:{s}\n", .{c.SDL_GetError()});
        return error.ERROR_TEXTURE_ALREADY_LOCKED;
    }

    if (c.SDL_LockTexture(self.texture.?, null, &self.pixels, &self.pitch) != 0) {
        err("Error: unable to lock texture for modification! SDL Error: {s}\n", .{c.SDL_GetError()});
        return error.ERROR_LOCK_TEXTURE;
    }
}

pub fn unlockTexture(self: *Self) !void {
    if (self.pixels == null) {
        err("Texture is not locked: SDL_ERROR:{s}\n", .{c.SDL_GetError()});
        return error.ERROR_TEXTURE_NOT_LOCKED;
    }

    // Unlock texture and update texture
    c.SDL_UnlockTexture(self.texture.?);
    self.pixels = null;
}

pub fn createBlankTexture(
    self: *Self,
    width: c_int,
    height: c_int,
    defaults: struct {
        access: c.SDL_TextureAccess = c.SDL_TEXTUREACCESS_STREAMING,
    },
) !void {
    self.texture = c.SDL_CreateTexture(self.renderer, c.SDL_PIXELFORMAT_RGBA8888, @intCast(c_int, defaults.access), width, height) orelse {
        err("Unable to create blank texture! SDL Error: {s}\n", .{c.SDL_GetError()});
        return error.ERROR_CANT_CREATE_TEXTURE;
    };

    self.width = @intCast(u32, width);
    self.height = @intCast(u32, height);
}

pub fn copyPixels(self: Self, pixels: *c_void) !void {
    if (self.pixels.? != null) {
        @memcpy(
            @ptrCast([*]u8, @alignCast(@alignOf(u8), self.pixels.?)),
            @ptrCast([*]u8, @alignCast(@alignOf(u8), pixels)),
            self.getPitch() * self.height,
        );
    }
}

pub fn cleanup(self: *Self) void {
    if (self.texture.? != null) {
        _ = c.SDL_DestroyTexture(self.texture.?);
        self.pixels = null;
        self.pitch = 0;
        self.width = 0;
        self.height = 0;
        self.texture = null;
    }
}
