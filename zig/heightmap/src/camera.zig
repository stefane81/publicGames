const std = @import("std");
const rl = @import("raylib");

pub const Camera = struct {
    distance: f32,
    angle: rl.Vector2,
    camera: rl.Camera3D,

    pub fn init() @This() {
        var cam = @This(){
            .distance = 200.0,
            .angle = rl.Vector2{ .x = 0.7, .y = 0.7 },
            .camera = rl.Camera3D{
                .position = rl.Vector3{ .x = 0, .y = 0, .z = 0 },
                .target = rl.Vector3{ .x = 0.0, .y = -20.0, .z = 0.0 },
                .up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 },
                .fovy = 45.0,
                .projection = rl.CameraProjection.perspective,
            },
        };
        cam.camera.position = rl.Vector3{
            .x = @cos(cam.angle.y) * @cos(cam.angle.x) * cam.distance,
            .y = @sin(cam.angle.x) * cam.distance,
            .z = @sin(cam.angle.y) * @cos(cam.angle.x) * cam.distance,
        };
        return cam;
    }

    pub fn updateCamera(self: *@This()) void {
        // Camera rotation
        if (rl.isMouseButtonDown(rl.MouseButton.left)) {
            const delta = rl.getMouseDelta();
            self.angle.x += delta.y * 0.003;
            self.angle.y -= delta.x * 0.003;
            self.angle.x = std.math.clamp(self.angle.x, -std.math.pi / 3.0, std.math.pi / 3.0);

            // print ("Camera angle: {any}\n", .{angle});
            std.debug.print("Camera angle: {any}\n", .{self.angle});
        }

        // Camera zoom
        const wheel = rl.getMouseWheelMove();
        if (wheel != 0) {
            self.distance *= (1.0 - wheel * 0.02);
            self.distance = std.math.clamp(self.distance, 10.0, 300.0);
        }
        // Update camera position
        self.camera.position = .{
            .x = @cos(self.angle.y) * @cos(self.angle.x) * self.distance,
            .y = @sin(self.angle.x) * self.distance,
            .z = @sin(self.angle.y) * @cos(self.angle.x) * self.distance,
        };

        // Reset camera
        if (rl.isKeyPressed(rl.KeyboardKey.z)) {
            self.angle = .{ .x = 0.7, .y = 0.7 };
            self.distance = 200.0;
        }
    }
};
