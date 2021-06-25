// Size of all textures
pub const textures = .{
    .dim = 16,
};

// Render settings
pub const fov = 90;
pub const near = 0.01;
pub const far = 10000;

pub const default_resolution = .{
    .width = 1920,
    .height = 1080,
};

pub const mouse_sensitivity = 0.004;

// Keybinds
pub const keys = .{
    .quit = .GLFW_KEY_Q,

    .forward = .GLFW_KEY_W,
    .backward = .GLFW_KEY_S,
    .left = .GLFW_KEY_A,
    .right = .GLFW_KEY_D,
    .down = .GLFW_KEY_LEFT_SHIFT,
    .up = .GLFW_KEY_SPACE,
};
