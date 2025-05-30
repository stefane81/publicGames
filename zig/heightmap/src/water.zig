const std = @import("std");
const rl = @import("raylib");
const TERRAIN = @import("terrain.zig");

pub const Water = struct {
    water_level: f32 = 0.1,
    INITIAL_WATER_LEVEL: f32 = 0.5,

    pub fn init() @This() {
        // Initialize water with a default level
        return @This(){
            .water_level = 0.1,
            .INITIAL_WATER_LEVEL = 0.5,
        };
    }

    pub fn drawWater(self: *@This()) void {
        // Draw water
        const water_size = @as(f32, @floatFromInt(TERRAIN.TERRAIN_SIZE)) * TERRAIN.CUBE_SIZE;
        const water_pos = rl.Vector3{ .x = 0, .y = self.water_level, .z = 0 };
        rl.drawCube(water_pos, water_size, 0.1, water_size, rl.colorAlpha(rl.Color.sky_blue, 0.5));
    }

    pub fn adjustWaterLevel(self: *@This()) void {
        if (rl.isKeyDown(rl.KeyboardKey.comma)) self.water_level = @max(0.0, self.water_level - 0.1);
        if (rl.isKeyDown(rl.KeyboardKey.period)) self.water_level += 0.1;
    }
};
