const std = @import("std");
const rl = @import("raylib");
const Terrain = @import("terrain.zig");

const INITIAL_WATER_LEVEL: f32 = 0.1;
var water_level: f32 = INITIAL_WATER_LEVEL;

pub fn drawWater() void {

    // Draw water
    const water_size = @as(f32, @floatFromInt(Terrain.TERRAIN_SIZE)) * Terrain.CUBE_SIZE;
    const water_pos = rl.Vector3{ .x = 0, .y = water_level, .z = 0 };
    rl.drawCube(water_pos, water_size, 0.1, water_size, rl.colorAlpha(rl.Color.sky_blue, 0.5));
}

pub fn adjustWaterLevel() void {
    if (rl.isKeyDown(rl.KeyboardKey.comma)) water_level = @max(0.0, water_level - 0.1);
    if (rl.isKeyDown(rl.KeyboardKey.period)) water_level += 0.1;
}
