const std = @import("std");
const err = std.log.err;
const c = @import("../sdl.zig");

const Self = @This();
width: u32 = undefined,
height: u32 = undefined,
texture: ?*c.SDL_Texture = undefined,
pixels: ?*anyopaque,
pitch: c_int,
window: *c.SDL_Window = undefined,
renderer: *c.SDL_Renderer = undefined,

pub fn init(window: *c.SDL_Window, renderer: *c.SDL_Renderer) Self {
    return Self{
        .width = 0,
        .height = 0,
        .texture = null,
        .pixels = null,
        .pitch = undefined,
        .window = window,
        .renderer = renderer,
    };
}

pub fn loadFromFile(self: *Self, path: []const u8) !void {
    const surface: *c.SDL_Surface = c.IMG_Load(path.ptr) orelse {
        err("Error loading: {s}, SDL_ERROR: {s}\n", .{ path, c.SDL_GetError() });
        return error.ERROR_LOADING_RESOURCE;
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

    // Remove cyan background
    // Get image dimensions
    const height = formatted_surface.h;

    // Get pixel data in editable format
    const pixels: [*]u32 = @ptrCast([*]u32, @alignCast(@alignOf(u32), self.pixels));
    const pixel_count: u32 = (self.getPitch() / 4) * @intCast(u32, height);

    // Map colors
    const search_color: u32 = c.SDL_MapRGB(formatted_surface.format, 0, 0xFF, 0xFF);
    const transparent_color: u32 = c.SDL_MapRGBA(formatted_surface.format, 0x00, 0xFF, 0xFF, 0x00);

    //Color key pixels
    var i: usize = 0;
    while (i < pixel_count) : (i += 1) {
        if (pixels[i] == search_color) {
            pixels[i] = transparent_color;
        }
    }

    // Unlock texture and update it
    c.SDL_UnlockTexture(blank_texture);
    self.pixels = null;

    self.width = @intCast(u32, formatted_surface.w);
    self.height = @intCast(u32, formatted_surface.h);
    self.texture = blank_texture;
}

pub fn getTexture(self: Self) *c.SDL_Texture {
    return self.texture;
}

pub fn cleanup(self: *Self) void {
    if (self.texture != null) {
        _ = c.SDL_DestroyTexture(self.texture.?);
        self.pixels = null;
        self.pitch = 0;
        self.width = 0;
        self.height = 0;
        self.texture = null;
    }
}

pub fn render(
    self: Self,
    x: c_int,
    y: c_int,
    clip: ?*c.SDL_Rect,
    angle: ?f64,
    center: ?*c.SDL_Point,
    flip: ?c.SDL_RendererFlip,
    defaults: struct {
        flip: c.SDL_RendererFlip = c.SDL_FLIP_NONE,
        angle: f64 = 0,
    },
) void {
    var render_square: c.SDL_Rect = .{
        .x = x,
        .y = y,
        .w = @intCast(c_int, self.getWidth()),
        .h = @intCast(c_int, self.getHeight()),
    };

    if (clip != null) {
        render_square.w = clip.?.w;
        render_square.h = clip.?.h;
    }

    // Render to screen
    _ = c.SDL_RenderCopyEx(
        self.renderer,
        self.texture,
        clip orelse null,
        &render_square,
        angle orelse defaults.angle,
        center orelse null,
        flip orelse defaults.flip,
    );
}

pub fn setColor(self: Self, red: u8, green: u8, blue: u8) void {
    _ = c.SDL_SetTextureColorMod(self.texture, red, green, blue);
}

pub fn setAlpha(self: Self, alpha: u16) void {
    _ = c.SDL_SetTextureAlphaMod(self.texture, @intCast(u8, alpha));
}

pub fn setBlendMode(self: Self, blend_mode: c.SDL_BlendMode) void {
    _ = c.SDL_SetTextureBlendMode(self.texture, blend_mode);
}

pub fn getWidth(self: Self) u32 {
    return self.width;
}

pub fn getHeight(self: Self) u32 {
    return self.height;
}

pub fn getPixels(self: Self) *anyopaque {
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

    if (c.SDL_LockTexture(self.texture, null, &self.pixels, &self.pitch) != 0) {
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
    c.SDL_UnlockTexture(self.texture);
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

pub fn setAsRenderTarget(self: Self) !void {
    if (c.SDL_SetRenderTarget(self.renderer, self.texture) != 0) {
        err("Unable to set texture as a render target! SDL Error: {s}\n", .{c.SDL_GetError()});
        return error.ERROR_CANT_SET_RENDER_TARGET;
    }
}

pub fn copyPixels(self: Self, pixels: *anyopaque) !void {
    if (self.pixels != null) {
        @memcpy(
            @ptrCast([*]u8, @alignCast(@alignOf(u8), self.pixels)),
            @ptrCast([*]u8, @alignCast(@alignOf(u8), pixels)),
            self.getPitch() * self.height,
        );
    }
}
