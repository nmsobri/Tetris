const Font = @import("Font.zig");
const c = @import("sdl.zig");

const Self = @This();
const TotalCharColumn = 127; // actually it just 94 but since printed ascii code start at 33, so 94 + 33
const AsciiStart = 33;

bitmap: ?*Font,
chars: [256]c.SDL_Rect,
new_line: u32,
space: u32,
cell_width: u32,
cell_height: u32,
char_left_side: u64,
char_right_side: u64,

pub fn init() Self {
    return Self{
        .bitmap = null,
        .chars = undefined,
        .new_line = 0,
        .space = 0,
        .cell_width = 0,
        .cell_height = 0,
        .char_left_side = 0,
        .char_right_side = 0,
    };
}

pub fn buildFont(self: *Self, bitmap: *Font) !void {
    // Lock pixels for access
    try bitmap.lockTexture();

    // Set the background color by getting pixel color at left top
    var bg_color: u32 = bitmap.getPixels32(0, 0);

    // Set the cell dimensions
    self.cell_width = bitmap.getWidth() / (TotalCharColumn - AsciiStart);
    // self.cell_width = 12;
    self.cell_height = bitmap.getHeight();

    // Vars for Calculation of new line variables
    var top: u32 = self.cell_height; // set to the bottom of the cell, so later we can iterate and find the highest point
    var bottom: u32 = self.cell_height;

    const rows: u32 = 0; // No need to go each rows since we only have one row
    var cols: u32 = AsciiStart; // start at 33 since printed ascii code start at 33
    var start_pixel: u64 = self.char_left_side;

    // Go through the cell columns
    while (start_pixel <= bitmap.getWidth()) {
        // Set current character ( based on ascii code ) initial offset
        self.chars[cols].x = @intCast(c_int, (cols - AsciiStart) * self.cell_width);
        self.chars[cols].y = @intCast(c_int, rows * self.cell_height);

        // Set the initial dimensions of the character
        self.chars[cols].w = @intCast(c_int, self.cell_width);
        self.chars[cols].h = @intCast(c_int, self.cell_height);

        self.setLeftOffset(bitmap, bg_color, cols, self.cell_width, self.cell_height, start_pixel, rows);
        self.setRightOffset(bitmap, bg_color, cols, self.cell_width, self.cell_height, start_pixel, rows);
        self.setTopOffset(bitmap, bg_color, self.cell_width, self.cell_height, start_pixel, rows, &top);
        self.setBottomOffset(bitmap, bg_color, cols, self.cell_width, self.cell_height, start_pixel, rows, &bottom);

        // advance to next glyph
        start_pixel += self.char_right_side + 1;

        // Next character
        cols += 1;
    }

    // Calculate space
    self.space = self.cell_width / 2;

    // Calculate new line
    self.new_line = bottom - top;

    // Lop off excess top pixels
    var i: usize = 0;
    while (i < 256) : (i += 1) {
        self.chars[i].y += @intCast(c_int, top);
        self.chars[i].h -= @intCast(c_int, top);
    }

    try bitmap.unlockTexture();
    self.bitmap = bitmap;
}

pub fn buildMonoSpacedFont(self: *Self, bitmap: *Font) !void {
    // Lock pixels for access
    try bitmap.lockTexture();

    // Set the background color by getting pixel color at left top
    var bg_color: u32 = bitmap.getPixels32(0, 0);

    // Set the cell dimensions
    self.cell_width = bitmap.getWidth() / (TotalCharColumn - AsciiStart);
    // self.cell_width = 12;
    self.cell_height = bitmap.getHeight();

    // Vars for Calculation of new line variables
    var top: u32 = self.cell_height; // set to the bottom of the cell, so later we can iterate and find the highest point
    var bottom: u32 = self.cell_height;

    const rows: u32 = 0; // No need to go each rows since we only have one row
    var cols: u32 = AsciiStart; // start at 33 since printed ascii code start at 33

    // Go through the cell columns
    while (cols <= TotalCharColumn) : (cols += 1) {
        // Set current character ( based on ascii code ) initial offset
        self.chars[cols].x = @intCast(c_int, (cols - AsciiStart) * self.cell_width);
        self.chars[cols].y = @intCast(c_int, rows * self.cell_height);

        // Set the initial dimensions of the character
        self.chars[cols].w = @intCast(c_int, self.cell_width);
        self.chars[cols].h = @intCast(c_int, self.cell_height);

        self.setMonospacedLeftOffset(bitmap, bg_color, cols, self.cell_width, self.cell_height, cols - AsciiStart, rows);
        self.setMonospacedRightOffset(bitmap, bg_color, cols, self.cell_width, self.cell_height, cols - AsciiStart, rows);
        self.setMonospacedTopOffset(bitmap, bg_color, self.cell_width, self.cell_height, cols - AsciiStart, rows, &top);
        self.setMonospacedBottomOffset(bitmap, bg_color, cols, self.cell_width, self.cell_height, cols - AsciiStart, rows, &bottom);
    }

    // Calculate space
    self.space = self.cell_width / 2;

    // Calculate new line
    self.new_line = bottom - top;

    // Lop off excess top pixels
    var i: usize = 0;
    while (i < 256) : (i += 1) {
        self.chars[i].y += @intCast(c_int, top);
        self.chars[i].h -= @intCast(c_int, top);
    }

    try bitmap.unlockTexture();
    self.bitmap = bitmap;
}

pub fn renderText(self: *Self, x: c_int, y: c_int, text: []const u8) void {
    // If the font has not been built
    if (self.bitmap == null) return;

    // Temp offsets
    var cur_x: c_int = x;
    var cur_y: c_int = y;

    // Go through the text
    var i: usize = 0;
    while (i < text.len) : (i += 1) {
        if (text[i] == ' ') { // If the current character is a space
            // Move over
            cur_x += @intCast(c_int, self.space);
        } else if (text[i] == '\n') { // If the current character is a newline
            // Move down
            cur_y += @intCast(c_int, self.new_line);

            // Move back
            cur_x = x;
        } else {
            // Get the ASCII value of the character
            const ascii = text[i];

            // Show the character
            self.bitmap.?.render(cur_x, cur_y, &self.chars[ascii], 0, null, null, .{});

            // Move over the width of the character with one pixel of padding
            cur_x += self.chars[ascii].w + 1;
        }
    }
}

pub fn getCellW(self: Self) u32 {
    return self.cell_width;
}

pub fn getCellH(self: Self) u32 {
    return self.cell_height;
}

pub fn calculateTextWidth(self: Self, text: []const u8) u32 {
    var width: u32 = 0;

    var i: usize = 0;
    while (i < text.len) : (i += 1) {
        if (text[i] != '\n') {
            if (text[i] == ' ') {
                width += self.space;
            } else {
                const ascii = text[i];
                width += @intCast(u32, self.chars[ascii].w);
            }
        }
    }

    return width;
}

fn setMonospacedLeftOffset(
    self: *Self,
    bitmap: *Font,
    bg_color: u32,
    current_char: u32,
    cell_w: u32,
    cell_h: u32,
    current_col: u32,
    current_row: u32,
) void {
    // Find Left Side edges
    // Go through every pixel of every row for each column ( start from left to the right side )
    var cell_col: u32 = 0;
    main: while (cell_col < cell_w) : (cell_col += 1) {

        // Go through pixel rows
        var cell_row: u32 = 0;
        while (cell_row < cell_h) : (cell_row += 1) {

            // Get the pixel offsets
            // col_num * cell_width + current_col
            // eg: col_num : 1, cell_width: 32, current_col: 2
            // so we will iterate from column 32 to column 63 (and currently at column: 34)
            // since col_num: 0, cell_width: 32, current_col: 0 is:
            // iterating from column 0 to column 31 ( and currently at column 0)
            var px: u32 = (current_col * cell_w) + cell_col;
            var py: u32 = (current_row * cell_h) + cell_row;

            // If a current pixel color != bg_color ( then it is font color )
            if (bitmap.getPixels32(px, py) != bg_color) {
                // Set the x offset
                self.chars[current_char].x = @intCast(c_int, px);
                break :main;
            }
        }
    }
}

fn setMonospacedRightOffset(
    self: *Self,
    bitmap: *Font,
    bg_color: u32,
    current_char: u32,
    cell_w: u32,
    cell_h: u32,
    current_col: u32,
    current_row: u32,
) void {
    // Find Right Side
    // Go through pixel columns ( start from the right side to the left )
    var cell_col: i32 = @intCast(i32, cell_w - 1); // -1 cause column started with 0
    main: while (cell_col >= 0) : (cell_col -= 1) {

        // Go through pixel current_row
        var cell_row: u32 = 0;
        while (cell_row < cell_h) : (cell_row += 1) {

            // Get the pixel offsets
            var px: u32 = (current_col * cell_w) + @intCast(u32, cell_col);
            var py: u32 = (current_row * cell_h) + cell_row;

            // If a current pixel color != bg_color ( then it is font color )
            if (bitmap.getPixels32(px, py) != bg_color) {
                // Set the width
                // Need to  - self.chars[current_char].x cause we want width and not position
                // +1 cause column start at 0
                self.chars[current_char].w = (@intCast(c_int, px) - self.chars[current_char].x) + 1;
                break :main;
            }
        }
    }
}

fn setMonospacedTopOffset(
    self: Self,
    bitmap: *Font,
    bg_color: u32,
    cell_w: u32,
    cell_h: u32,
    current_col: u32,
    current_row: u32,
    top: *u32,
) void {
    _ = self;

    // Find Top
    // Go through pixel of current row ( go by each cols of current row )
    var cell_row: u32 = 0;
    main: while (cell_row < cell_h) : (cell_row += 1) {

        // Go through pixel columns
        var cell_col: u32 = 0;
        while (cell_col < cell_w) : (cell_col += 1) {

            // Get the pixel offsets
            var px: u32 = (current_col * cell_w) + cell_col;
            var py: u32 = (current_row * cell_h) + cell_row;

            // If a current pixel color != bg_color ( then it is font color )
            if (bitmap.getPixels32(px, py) != bg_color) {
                // If new top is found
                if (cell_row < top.*) {
                    top.* = cell_row;
                }

                break :main;
            }
        }
    }
}

fn setMonospacedBottomOffset(
    self: *Self,
    bitmap: *Font,
    bg_color: u32,
    current_char: u32,
    cell_w: u32,
    cell_h: u32,
    current_col: u32,
    current_row: u32,
    bottom: *u32,
) void {
    _ = self;

    // Find Bottom of A
    // Since each character might have different bottom such as 'g','j', 'y', we only about character 'A'
    // and use it as default bottom for all chars
    if (current_char != 'A') return;

    // Go through pixel current_row
    var cell_row: i32 = @intCast(i32, cell_h);
    main: while (cell_row >= 0) : (cell_row -= 1) {

        // Go through pixel columns
        var cell_col: u32 = 0;
        while (cell_col < cell_w) : (cell_col += 1) {

            // Get the pixel offsets
            var px: u32 = (current_col * cell_w) + @intCast(u32, cell_col);
            var py: u32 = (current_row * cell_h) + @intCast(u32, cell_row);

            // If a non colorkey pixel is found
            if (bitmap.getPixels32(px, py) != bg_color) {
                // Bottom of A is found
                bottom.* = @intCast(u32, cell_row);
                break :main;
            }
        }
    }
}

fn setLeftOffset(
    self: *Self,
    bitmap: *Font,
    bg_color: u32,
    current_char: u32,
    cell_w: u32,
    cell_h: u32,
    current_col: u32,
    current_row: u32,
) void {
    // Find Left Side edges
    // Go through every pixel of every row for each column ( start from left to the right side )
    var cell_col: u32 = current_col;
    main: while (cell_col < bitmap.getWidth()) : (cell_col += 1) {

        // Go through pixel rows
        var cell_row: u32 = 0;
        while (cell_row < cell_h) : (cell_row += 1) {
            var px: u32 = cell_col;
            var py: u32 = cell_row;

            // If a current pixel color != bg_color ( then it is font color )
            if (bitmap.getPixels32(px, py) != bg_color) {
                // Set the x offset
                self.chars[current_char].x = @intCast(c_int, px);
                self.char_left_side = px;
                break :main;
            }
        }
    }
}

fn setRightOffset(
    self: *Self,
    bitmap: *Font,
    bg_color: u32,
    current_char: u32,
    cell_w: u32,
    cell_h: u32,
    current_col: u32,
    current_row: u32,
) void {
    // Find Right Side
    var cell_col: i32 = self.char_left_side + 1;

    main: while (cell_col <= bitmap.getWidth()) : (cell_col += 1) {
        // Go through pixel row by row
        var cell_row: u32 = 0;

        var found_font = while (cell_row < cell_h) : (cell_row += 1) {
            // Get the pixel offsets
            var px: u32 = cell_col;
            var py: u32 = cell_row;

            // If a current pixel color != bg_color ( then it is font color )
            if (bitmap.getPixels32(px, py) != bg_color) {
                break true;
            }
        } else false;

        if (found_font) {
            continue :main;
        } else {
            // Set the width
            // Need to  - self.chars[current_char].x cause we want width and not position
            // +1 cause column start at 0
            self.chars[current_char].w = px - 1;
            self.char_right_side = px - 1;
            break :main;
        }
    }
}

fn setTopOffset(
    self: Self,
    bitmap: *Font,
    bg_color: u32,
    cell_w: u32,
    cell_h: u32,
    current_col: u32,
    current_row: u32,
    top: *u32,
) void {}

fn setBottomOffset(
    self: *Self,
    bitmap: *Font,
    bg_color: u32,
    current_char: u32,
    cell_w: u32,
    cell_h: u32,
    current_col: u32,
    current_row: u32,
    bottom: *u32,
) void {}
