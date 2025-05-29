const std = @import("std");
const rl = @import("raylib");
const TERRAIN_SIZE: i32 = 128;
const CUBE_SIZE: f32 = 2.0;

pub fn drawTerrain(terrain: []const f32) void {
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

            // if (cube_height < INITIAL_WATER_LEVEL * 2) {
            color.r = @intFromFloat(@as(f32, @floatFromInt(color.r)) * 0.7);
            color.g = @intFromFloat(@as(f32, @floatFromInt(color.g)) * 0.7);
            color.b = @intFromFloat(@as(f32, @floatFromInt(color.b)) * 0.7);
            // }
            rl.drawCube(pos, CUBE_SIZE, cube_height, CUBE_SIZE, color);
        }
    }
}

pub fn generatePermutation(allocator: std.mem.Allocator, seed: u64) ![]i32 {
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

pub fn generateTerrain(allocator: std.mem.Allocator, seed: u32) ![]f32 {
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
