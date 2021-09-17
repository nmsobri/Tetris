const T = true;
const F = false;

pub const TetrominoLayout = [4][4]bool;

pub const Tetromino = struct {
    name: u8,
    color: [3]u8,
    layout: [4]TetrominoLayout,
};

pub const Tetrominoes = [_]Tetromino{
    Tetromino{
        .name = 'I',
        .color = .{ 49, 199, 239 },
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
        .layout = [4]TetrominoLayout{
            TetrominoLayout{
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, T, F },
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
