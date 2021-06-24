pub const textures = .{
    .dim = 16,
};

// If vertex lists should be generated conditionally
// Slows down chunk generation, but generates a smaller chunk mesh
pub const conditional_vertices = true;

pub const fov = 90;
pub const near = 0.01;
pub const far = 10000;
