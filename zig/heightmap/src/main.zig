const std = @import("std");
const rl = @import("raylib");

const WINDOW_WIDTH: i32 = 1200;
const WINDOW_HEIGHT: i32 = 800;
const TERRAIN_SIZE: i32 = 128;
const CUBE_SIZE: f32 = 2.0;
const INITIAL_WATER_LEVEL: f32 = 1.0;

fn generatePermutation(allocator: std.mem.Allocator, seed: u64) ![]i32 {
    var prng = std.Random.DefaultPrng.init(seed);
    var random = prng.random();

    const perm = try allocator.alloc(i32, 512);
    var source = try allocator.alloc(i32, 256);
    defer allocator.free(source);

    for (source, 0..) |*value, index| {
        value.* = @intCast(index);
    }

    var i: usize = 255;
    while (i > 0) : (i -= 1) {
        const j = random.intRangeAtMost(usize, 0, i);
        const temp = source[i];
        source[i] = source[j];
        source[j] = temp;
    }

    for (perm, 0..) |*value, index| {
        value.* = source[index % 256];
    }

    return perm;
}

fn fade(t: f32) f32 {
    return t * t * t * (t * (t * 6 - 15) + 10);
}

fn lerp(t: f32, a: f32, b: f32) f32 {
    return a + t * (b - a);
}

fn grad(hash: i32, x: f32, y: f32, z: f32) f32 {
    const h = hash & 15;
    const u = if (h < 8) x else y;
    const v = if (h < 4) y else if (h == 12 or h == 14) x else z;
    return (if ((h & 1) == 0) u else -u) + (if ((h & 2) == 0) v else -v);
}

fn noise(x: f32, y: f32, z: f32, p: []const i32) f32 {
    const X = @as(u8, @intFromFloat(x)) & 255;
    const Y = @as(u8, @intFromFloat(y)) & 255;
    const Z = @as(u8, @intFromFloat(z)) & 255;
    const x_floor = x - @floor(x);
    const y_floor = y - @floor(y);
    const z_floor = z - @floor(z);
    const u = fade(x_floor);
    const v = fade(y_floor);
    const w = fade(z_floor);

    const A = @as(u8, @intCast(p[X])) +% Y;
    const AA = @as(u8, @intCast(p[A])) +% Z;
    const AB = @as(u8, @intCast(p[A +% 1])) +% Z;
    const B = @as(u8, @intCast(p[X +% 1])) +% Y;
    const BA = @as(u8, @intCast(p[B])) +% Z;
    const BB = @as(u8, @intCast(p[B +% 1])) +% Z;

    return lerp(w, lerp(v, lerp(u, grad(p[@intCast(AA)], x_floor, y_floor, z_floor), grad(p[@intCast(BA)], x_floor - 1, y_floor, z_floor)), lerp(u, grad(p[@intCast(AB)], x_floor, y_floor - 1, z_floor), grad(p[@intCast(BB)], x_floor - 1, y_floor - 1, z_floor))), lerp(v, lerp(u, grad(p[@intCast(AA +% 1)], x_floor, y_floor, z_floor - 1), grad(p[@intCast(BA +% 1)], x_floor - 1, y_floor, z_floor - 1)), lerp(u, grad(p[@intCast(AB +% 1)], x_floor, y_floor - 1, z_floor - 1), grad(p[@intCast(BB +% 1)], x_floor - 1, y_floor - 1, z_floor - 1))));
}

fn fbm(x: f32, y: f32, octaves: u32, persistence: f32, lacunarity: f32, scale: f32, p: []const i32) f32 {
    var value: f32 = 0;
    var amplitude: f32 = 1;
    var frequency: f32 = 1;

    var i: u32 = 0;
    while (i < octaves) : (i += 1) {
        value += amplitude * noise(x * frequency / scale, y * frequency / scale, 0, p);
        amplitude *= persistence;
        frequency *= lacunarity;
    }

    return value;
}

fn generateTerrain(allocator: std.mem.Allocator, seed: u32) ![]f32 {
    var terrain = try allocator.alloc(f32, @as(usize, TERRAIN_SIZE * TERRAIN_SIZE));
    const perm = try generatePermutation(allocator, @as(u64, @as(u32, seed)));
    defer allocator.free(perm);

    for (0..TERRAIN_SIZE) |y| {
        for (0..TERRAIN_SIZE) |x| {
            terrain[y * TERRAIN_SIZE + x] = fbm(@floatFromInt(x), @floatFromInt(y), 6, 0.5, 2.0, 50.0, perm);
        }
    }

    return terrain;
}

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
    var terrain = try generateTerrain(allocator, @intFromFloat(rl.getTime() * 1000000.0));
    defer allocator.free(terrain);
    var water_level: f32 = INITIAL_WATER_LEVEL;

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
            allocator.free(terrain);
            terrain = try generateTerrain(allocator, @intFromFloat(rl.getTime() * 1000000.0));
        }

        // Adjust water level
        if (rl.isKeyDown(rl.KeyboardKey.comma)) water_level = @max(0.0, water_level - 0.1);
        if (rl.isKeyDown(rl.KeyboardKey.period)) water_level += 0.1;

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
        rl.beginMode3D(camera);
        // Update

        // allocator.free(terrain);
        // terrain = try generateTerrain(allocator, @intFromFloat(rl.getTime() * 1000000.0));
        // Draw terrain
        for (0..TERRAIN_SIZE) |z| {
            for (0..TERRAIN_SIZE) |x| {
                const height = terrain[z * TERRAIN_SIZE + x];
                const cube_height = height * 20.0;
                const pos = rl.Vector3{
                    .x = @as(f32, @floatFromInt(x)) * CUBE_SIZE - @as(f32, @floatFromInt(TERRAIN_SIZE)) * CUBE_SIZE / 2,
                    .y = cube_height / 2,
                    .z = @as(f32, @floatFromInt(z)) * CUBE_SIZE - @as(f32, @floatFromInt(TERRAIN_SIZE)) * CUBE_SIZE / 2,
                };
                var color = rl.colorFromHSV(120 * height, 0.8, 0.8);

                if (cube_height < INITIAL_WATER_LEVEL * 2) {
                    color.r = @intFromFloat(@as(f32, @floatFromInt(color.r)) * 0.7);
                    color.g = @intFromFloat(@as(f32, @floatFromInt(color.g)) * 0.7);
                    color.b = @intFromFloat(@as(f32, @floatFromInt(color.b)) * 0.7);
                }
                rl.drawCube(pos, CUBE_SIZE, cube_height, CUBE_SIZE, color);
            }
        }
        // Draw
        //----------------------------------------------------------------------------------
        // Draw water
        const water_size = @as(f32, @floatFromInt(TERRAIN_SIZE)) * CUBE_SIZE;
        const water_pos = rl.Vector3{ .x = 0, .y = water_level, .z = 0 };
        rl.drawCube(water_pos, water_size, 0.1, water_size, rl.colorAlpha(rl.Color.sky_blue, 0.5));

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
