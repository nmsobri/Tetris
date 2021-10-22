const T = true;
const F = false;
const constant = @import("constant.zig");

pub const TetrominoLayout = [4][4]bool;

pub const Tetromino = struct {
    name: u8,
    color: [3]u8,
    width: u8,
    height: u8,
    yoffset: u8,
    layout: [4]TetrominoLayout,
};

pub const Tetrominoes = [_]Tetromino{
    Tetromino{
        .name = 'I',
        .color = .{ 49, 199, 239 },
        .width = constant.BLOCK * 4,
        .height = constant.BLOCK * 1,
        .yoffset = 2,
        .layout = [4]TetrominoLayout{
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, T, T },
                [_]bool{ F, F, F, F },
            },
            TetrominoLayout{
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
            },
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, T, T },
                [_]bool{ F, F, F, F },
            },
            TetrominoLayout{
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
            },
        },
    },

    Tetromino{
        .name = 'O',
        .color = .{ 247, 211, 8 },
        .width = constant.BLOCK * 2,
        .height = constant.BLOCK * 2,
        .yoffset = 2,
        .layout = [4]TetrominoLayout{
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ T, T, F, F },
            },
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ T, T, F, F },
            },
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ T, T, F, F },
            },
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ T, T, F, F },
            },
        },
    },

    Tetromino{
        .name = 'T',
        .color = .{ 173, 77, 156 },
        .width = constant.BLOCK * 3,
        .height = constant.BLOCK * 2,
        .yoffset = 2,
        .layout = [4]TetrominoLayout{
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, T, F },
                [_]bool{ F, T, F, F },
            },
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ F, T, F, F },
            },
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ T, T, T, F },
                [_]bool{ F, F, F, F },
            },
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, T, F },
                [_]bool{ F, T, F, F },
            },
        },
    },

    Tetromino{
        .name = 'J',
        .color = .{ 90, 101, 173 },
        .width = constant.BLOCK * 2,
        .height = constant.BLOCK * 3,
        .yoffset = 1,
        .layout = [4]TetrominoLayout{
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ T, T, F, F },
            },
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ T, F, F, F },
                [_]bool{ T, T, T, F },
                [_]bool{ F, F, F, F },
            },
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, T, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
            },
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, T, F },
                [_]bool{ F, F, T, F },
            },
        },
    },

    Tetromino{
        .name = 'L',
        .color = .{ 239, 121, 33 },
        .width = constant.BLOCK * 2,
        .height = constant.BLOCK * 3,
        .yoffset = 1,
        .layout = [4]TetrominoLayout{
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ T, F, F, F },
                [_]bool{ T, F, F, F },
                [_]bool{ T, T, F, F },
            },
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, T, F },
                [_]bool{ T, F, F, F },
            },
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
            },
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, T, F },
                [_]bool{ T, T, T, F },
                [_]bool{ F, F, F, F },
            },
        },
    },

    Tetromino{
        .name = 'S',
        .color = .{ 66, 182, 66 },
        .width = constant.BLOCK * 3,
        .height = constant.BLOCK * 2,
        .yoffset = 2,
        .layout = [4]TetrominoLayout{
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, T, F },
                [_]bool{ T, T, F, F },
            },
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ T, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ F, T, F, F },
            },
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, T, F },
                [_]bool{ T, T, F, F },
            },
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ T, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ F, T, F, F },
            },
        },
    },

    Tetromino{
        .name = 'Z',
        .color = .{ 239, 32, 41 },
        .width = constant.BLOCK * 3,
        .height = constant.BLOCK * 2,
        .yoffset = 2,
        .layout = [4]TetrominoLayout{
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ F, T, T, F },
            },
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, T, F },
                [_]bool{ F, T, T, F },
                [_]bool{ F, T, F, F },
            },
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ F, T, T, F },
            },
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, T, F },
                [_]bool{ F, T, T, F },
                [_]bool{ F, T, F, F },
            },
        },
    },
};
