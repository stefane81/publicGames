const std = @import("std");
const rl = @import("raylib");

pub const Camera = struct {
    camera_distance: f32,
    camera_angle: rl.Vector2,
    camera: rl.Camera3D,

    pub fn init() @This() {
        var cam = @This(){
            .camera_distance = 200.0,
            .camera_angle = rl.Vector2{ .x = 0.7, .y = 0.7 },
            .camera = rl.Camera3D{
                .position = rl.Vector3{ .x = 0, .y = 0, .z = 0 },
                .target = rl.Vector3{ .x = 0.0, .y = -20.0, .z = 0.0 },
                .up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 },
                .fovy = 45.0,
                .projection = rl.CameraProjection.perspective,
            },
        };
        cam.camera.position = rl.Vector3{
            .x = @cos(cam.camera_angle.y) * @cos(cam.camera_angle.x) * cam.camera_distance,
            .y = @sin(cam.camera_angle.x) * cam.camera_distance,
            .z = @sin(cam.camera_angle.y) * @cos(cam.camera_angle.x) * cam.camera_distance,
        };
        return cam;
    }

    pub fn updateCamera(self: *@This()) void {
        // Camera rotation
        if (rl.isMouseButtonDown(rl.MouseButton.left)) {
            const delta = rl.getMouseDelta();
            self.camera_angle.x += delta.y * 0.003;
            self.camera_angle.y -= delta.x * 0.003;
            self.camera_angle.x = std.math.clamp(self.camera_angle.x, -std.math.pi / 3.0, std.math.pi / 3.0);

            // print ("Camera angle: {any}\n", .{camera_angle});
            std.debug.print("Camera angle: {any}\n", .{self.camera_angle});
        }

        // Camera zoom
        const wheel = rl.getMouseWheelMove();
        if (wheel != 0) {
            self.camera_distance *= (1.0 - wheel * 0.02);
            self.camera_distance = std.math.clamp(self.camera_distance, 10.0, 300.0);
        }
        // Update camera position
        self.camera.position = .{
            .x = @cos(self.camera_angle.y) * @cos(self.camera_angle.x) * self.camera_distance,
            .y = @sin(self.camera_angle.x) * self.camera_distance,
            .z = @sin(self.camera_angle.y) * @cos(self.camera_angle.x) * self.camera_distance,
        };

        // Reset camera
        if (rl.isKeyPressed(rl.KeyboardKey.z)) {
            self.camera_angle = .{ .x = 0.7, .y = 0.7 };
            self.camera_distance = 200.0;
        }
    }
};
