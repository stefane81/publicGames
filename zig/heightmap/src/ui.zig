const rl = @import("raylib");
const camera = @import("camera.zig");

pub fn drawUI() void {
    // Draw UI
    rl.drawRectangle(10, 10, 245, 162, rl.fade(rl.Color.sky_blue, 0.5));
    rl.drawRectangleLines(10, 10, 245, 162, rl.Color.blue);
    rl.drawText("Controls:", 20, 20, 10, rl.Color.black);
    rl.drawText("- R or Right Mouse: Regenerate terrain", 40, 40, 10, rl.Color.dark_gray);
    rl.drawText("- , or .: Decrease/Increase water level", 40, 55, 10, rl.Color.dark_gray);
    rl.drawText("- Left Mouse: Rotate camera", 40, 70, 10, rl.Color.dark_gray);
    rl.drawText("- Mouse Wheel: Zoom in/out", 40, 85, 10, rl.Color.dark_gray);
    rl.drawText("- Z: Reset camera", 40, 100, 10, rl.Color.dark_gray);
    rl.drawText(rl.textFormat("Camera Angle X: %.2f", .{camera.camera_angle.x}), 20, 120, 10, rl.Color.dark_gray);
    rl.drawText(rl.textFormat("Camera Angle Y: %.2f", .{camera.camera_angle.y}), 20, 135, 10, rl.Color.dark_gray);
    rl.drawText(rl.textFormat("Camera Distance: %.2f", .{camera.camera_distance}), 20, 150, 10, rl.Color.dark_gray);
    rl.drawFPS(10, 180);
    // rl.drawText("Congrats! You created your first window!", 190, 200, 20, .light_gray);
    //----------------------------------------------------------------------------------
}
