const std = @import("std");
const gl = @cImport({
    @cInclude("GL/gl.h");
    @cInclude("stb_image.h");
});

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    // GLFW context creation skipped for brevity

    var width: c_int = 0;
    var height: c_int = 0;
    var channels: c_int = 0;

    const heightmapData = gl.stbi_load("assets/heightmap.png", &width, &height, &channels, 1);
    if (heightmapData == null) return error.FailedToLoadImage;

    var vertices = try allocator.alloc(f32, @intCast(usize, width * height * 3));
    var i: usize = 0;
    while (i < @intCast(usize, width * height)) : (i += 1) {
        const x = i % width;
        const z = i / width;
        const y = @floatFromInt(f32, heightmapData[i]) / 255.0 * 10.0;

        vertices[i * 3 + 0] = @floatFromInt(f32, x);
        vertices[i * 3 + 1] = y;
        vertices[i * 3 + 2] = @floatFromInt(f32, z);
    }

    // Setup VBO/VAO
    var vao: u32 = 0;
    gl.glGenVertexArrays(1, &vao);
    gl.glBindVertexArray(vao);

    var vbo: u32 = 0;
    gl.glGenBuffers(1, &vbo);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, vbo);
    gl.glBufferData(gl.GL_ARRAY_BUFFER, vertices.len * @sizeOf(f32), vertices.ptr, gl.GL_STATIC_DRAW);

    // enable attribs, shaders, draw loop omitted for brevity

    gl.stbi_image_free(heightmapData);
}
