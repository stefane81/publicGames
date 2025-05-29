const std = @import("std");
const rl = @import("raylib");

pub var camera_distance: f32 = 200.0;
pub var camera_angle = rl.Vector2{ .x = 0.7, .y = 0.7 };
pub var camera: rl.Camera3D = rl.Camera3D{
    .position = rl.Vector3{ .x = 0, .y = 0, .z = 0 },
    .target = rl.Vector3{ .x = 0, .y = 0, .z = 0 },
    .up = rl.Vector3{ .x = 0, .y = 1, .z = 0 },
    .fovy = 45.0,
    .projection = rl.CameraProjection.perspective,
};

pub fn initCamera() void {
    camera = rl.Camera3D{
        .position = rl.Vector3{ .x = @cos(camera_angle.y) * @cos(camera_angle.x) * camera_distance, .y = @sin(camera_angle.x) * camera_distance, .z = @sin(camera_angle.y) * @cos(camera_angle.x) * camera_distance },
        .target = rl.Vector3{ .x = 0.0, .y = -20.0, .z = 0.0 },
        .up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 },
        .fovy = 45.0,
        .projection = rl.CameraProjection.perspective,
    };
}

pub fn updateCamera() void {
    // Camera rotation
    if (rl.isMouseButtonDown(rl.MouseButton.left)) {
        const delta = rl.getMouseDelta();
        camera_angle.x += delta.y * 0.003;
        camera_angle.y -= delta.x * 0.003;
        camera_angle.x = std.math.clamp(camera_angle.x, -std.math.pi / 3.0, std.math.pi / 3.0);

        // print ("Camera angle: {any}\n", .{camera_angle});
        std.debug.print("Camera angle: {any}\n", .{camera_angle});
    }

    // Camera zoom
    const wheel = rl.getMouseWheelMove();
    if (wheel != 0) {
        camera_distance *= (1.0 - wheel * 0.02);
        camera_distance = std.math.clamp(camera_distance, 10.0, 300.0);
    }
    // Update camera position
    camera.position = .{
        .x = @cos(camera_angle.y) * @cos(camera_angle.x) * camera_distance,
        .y = @sin(camera_angle.x) * camera_distance,
        .z = @sin(camera_angle.y) * @cos(camera_angle.x) * camera_distance,
    };

    // Reset camera
    if (rl.isKeyPressed(rl.KeyboardKey.z)) {
        camera_angle = .{ .x = 0.7, .y = 0.7 };
        camera_distance = 200.0;
    }
}
