pub const textures = .{
    .dim = 16,
};

// If vertex lists should be generated conditionally
// Slows down chunk generation, but generates a smaller chunk mesh
pub const conditional_vertices = true;

pub const fov = 90;
pub const near = 0.01;
pub const far = 10000;

pub const keys = .{
    .quit = .GLFW_KEY_Q,
    .forward = .GLFW_KEY_W,
    .backward = .GLFW_KEY_S,
    .left = .GLFW_KEY_A,
    .right = .GLFW_KEY_D,
    .down = .GLFW_KEY_LEFT_SHIFT,
    .up = .GLFW_KEY_SPACE,
};
