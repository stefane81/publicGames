const std = @import("std");
const rl = @import("raylib");
const Terrain = @import("terrain.zig");
const Water = @import("water.zig");
const Camera = @import("camera.zig");
const UI = @import("ui.zig");

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

    // Initialize camera
    Camera.initCamera();

    // Generate terrain
    // Use a seed based on the current time for randomness
    var _terrain = try Terrain.generateTerrain(allocator, @intFromFloat(rl.getTime() * 1000000.0));
    defer allocator.free(_terrain);

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        Camera.updateCamera();

        // Regenerate terrain
        if (rl.isKeyPressed(rl.KeyboardKey.r) or rl.isMouseButtonPressed(rl.MouseButton.right)) {
            allocator.free(_terrain);
            _terrain = try Terrain.generateTerrain(allocator, @intFromFloat(rl.getTime() * 1000000.0));
        }

        // Adjust water level
        Water.adjustWaterLevel();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
        rl.beginMode3D(Camera.camera);

        // Draw terrain
        Terrain.drawTerrain(_terrain);
        // Draw
        //----------------------------------------------------------------------------------
        // Draw water
        Water.drawWater();

        rl.endMode3D();

        // Draw UI
        UI.drawUI();
        //----------------------------------------------------------------------------------
    }
}
