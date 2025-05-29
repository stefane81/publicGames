const std = @import("std");
const rl = @import("raylib");
const terrain = @import("terrain.zig");
const water = @import("water.zig");

const WINDOW_WIDTH: i32 = 1200;
const WINDOW_HEIGHT: i32 = 800;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Initialization
    //--------------------------------------------------------------------------------------
    rl.initWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var camera_distance: f32 = 200.0;
    var camera_angle = rl.Vector2{ .x = 0.7, .y = 0.7 };
    var camera = rl.Camera3D{
        .position = rl.Vector3{ .x = @cos(camera_angle.y) * @cos(camera_angle.x) * camera_distance, .y = @sin(camera_angle.x) * camera_distance, .z = @sin(camera_angle.y) * @cos(camera_angle.x) * camera_distance },
        .target = rl.Vector3{ .x = 0.0, .y = -20.0, .z = 0.0 },
        .up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 },
        .fovy = 45.0,
        .projection = rl.CameraProjection.perspective,
    };

    // Generate terrain
    // Use a seed based on the current time for randomness
    var _terrain = try terrain.generateTerrain(allocator, @intFromFloat(rl.getTime() * 1000000.0));
    defer allocator.free(_terrain);
    // var water_level: f32 = INITIAL_WATER_LEVEL;
    // var water_level: f32 = water.water_level;

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
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

        // Regenerate terrain
        if (rl.isKeyPressed(rl.KeyboardKey.r) or rl.isMouseButtonPressed(rl.MouseButton.right)) {
            allocator.free(_terrain);
            _terrain = try terrain.generateTerrain(allocator, @intFromFloat(rl.getTime() * 1000000.0));
        }

        // Adjust water level
        water.adjustWaterLevel();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
        rl.beginMode3D(camera);
        // Update

        // Draw terrain
        terrain.drawTerrain(_terrain);
        // Draw
        //----------------------------------------------------------------------------------
        // Draw water
        water.drawWater();

        rl.drawGrid(10, 10.0);
        rl.endMode3D();

        // Draw UI
        rl.drawRectangle(10, 10, 245, 162, rl.fade(rl.Color.sky_blue, 0.5));
        rl.drawRectangleLines(10, 10, 245, 162, rl.Color.blue);
        rl.drawText("Controls:", 20, 20, 10, rl.Color.black);
        rl.drawText("- R or Right Mouse: Regenerate terrain", 40, 40, 10, rl.Color.dark_gray);
        rl.drawText("- , or .: Decrease/Increase water level", 40, 55, 10, rl.Color.dark_gray);
        rl.drawText("- Left Mouse: Rotate camera", 40, 70, 10, rl.Color.dark_gray);
        rl.drawText("- Mouse Wheel: Zoom in/out", 40, 85, 10, rl.Color.dark_gray);
        rl.drawText("- Z: Reset camera", 40, 100, 10, rl.Color.dark_gray);
        rl.drawText(rl.textFormat("Camera Angle X: %.2f", .{camera_angle.x}), 20, 120, 10, rl.Color.dark_gray);
        rl.drawText(rl.textFormat("Camera Angle Y: %.2f", .{camera_angle.y}), 20, 135, 10, rl.Color.dark_gray);
        rl.drawText(rl.textFormat("Camera Distance: %.2f", .{camera_distance}), 20, 150, 10, rl.Color.dark_gray);
        rl.drawFPS(10, 180);
        // rl.drawText("Congrats! You created your first window!", 190, 200, 20, .light_gray);
        //----------------------------------------------------------------------------------
    }
}
