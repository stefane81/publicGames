const std = @import("std");
const rl = @import("raylib");
const terrain = @import("terrain.zig");
const water = @import("water.zig");
const camera = @import("camera.zig");
const ui = @import("ui.zig");

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
    camera.initCamera();

    // Generate terrain
    // Use a seed based on the current time for randomness
    var _terrain = try terrain.generateTerrain(allocator, @intFromFloat(rl.getTime() * 1000000.0));
    defer allocator.free(_terrain);
    // var water_level: f32 = INITIAL_WATER_LEVEL;
    // var water_level: f32 = water.water_level;

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        camera.updateCamera();

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
        rl.beginMode3D(camera.camera);
        // Update

        // Draw terrain
        terrain.drawTerrain(_terrain);
        // Draw
        //----------------------------------------------------------------------------------
        // Draw water
        water.drawWater();

        // rl.drawGrid(10, 10.0);
        rl.endMode3D();

        // Draw UI
        ui.drawUI();
        //----------------------------------------------------------------------------------
    }
}
