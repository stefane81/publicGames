package main

import rl "vendor:raylib"
import "core:math"
import "core:fmt"

WINDOW_WIDTH      :: 1200
WINDOW_HEIGHT     :: 800
TERRAIN_SIZE      :: 128
CUBE_SIZE         :: 2.0
INITIAL_WATER_LEVEL :: 0.1

generate_permutation :: proc(allocator: ^allocator_type, seed: u64) -> []i32 {
    math.random_seed(seed)
    perm   := allocator.alloc(i32, 512)
    source := allocator.alloc(i32, 256)
    defer allocator.free(source)

    for i in 0..<256 {
        source[i] = i32(i)
    }

    for i := 255; i > 0; i -= 1 {
        j := math.random_int_between(0, i)
        temp := source[i]
        source[i] = source[j]
        source[j] = temp
    }

    for i in 0..<512 {
        perm[i] = source[i % 256]
    }
    return perm
}

fade :: proc(t: f32) -> f32 {
    return t * t * t * (t * (t * 6 - 15) + 10)
}

lerp :: proc(t, a, b: f32) -> f32 {
    return a + t * (b - a)
}

grad :: proc(hash: i32, x, y, z: f32) -> f32 {
    h := hash & 15
    u: f32
    if h < 8 {
        u = x
    } else {
        u = y
    }
    v: f32
    if h < 4 {
        v = y
    } else if h == 12 || h == 14 {
        v = x
    } else {
        v = z
    }
    result: f32
    if (h & 1) == 0 {
        result = u
    } else {
        result = -u
    }
    if (h & 2) == 0 {
        result += v
    } else {
        result += -v
    }
    return result
}

noise :: proc(x, y, z: f32, p: []i32) -> f32 {
    X := int(x) & 255
    Y := int(y) & 255
    Z := int(z) & 255
    x_floor := x - math.floor(x)
    y_floor := y - math.floor(y)
    z_floor := z - math.floor(z)
    u := fade(x_floor)
    v := fade(y_floor)
    w := fade(z_floor)

    A  := p[X] + i32(Y)
    AA := p[A] + i32(Z)
    AB := p[A+1] + i32(Z)
    B  := p[X+1] + i32(Y)
    BA := p[B] + i32(Z)
    BB := p[B+1] + i32(Z)

    return lerp(w,
        lerp(v,
            lerp(u, grad(p[AA], x_floor, y_floor, z_floor), grad(p[BA], x_floor-1, y_floor, z_floor)),
            lerp(u, grad(p[AB], x_floor, y_floor-1, z_floor), grad(p[BB], x_floor-1, y_floor-1, z_floor))
        ),
        lerp(v,
            lerp(u, grad(p[AA+1], x_floor, y_floor, z_floor-1), grad(p[BA+1], x_floor-1, y_floor, z_floor-1)),
            lerp(u, grad(p[AB+1], x_floor, y_floor-1, z_floor-1), grad(p[BB+1], x_floor-1, y_floor-1, z_floor-1))
        )
    )
}

fbm :: proc(x, y: f32, octaves: int, persistence, lacunarity, scale: f32, p: []i32) -> f32 {
    value: f32 = 0
    amplitude: f32 = 1
    frequency: f32 = 1
    for i in 0..<octaves {
        value += amplitude * noise(x * frequency / scale, y * frequency / scale, 0, p)
        amplitude *= persistence
        frequency *= lacunarity
    }
    return value
}

generate_terrain :: proc(allocator: ^allocator_type, seed: u32) -> []f32 {
    terrain := allocator.alloc(f32, TERRAIN_SIZE * TERRAIN_SIZE)
    perm := generate_permutation(allocator, u64(seed))
    defer allocator.free(perm)
    for y in 0..<TERRAIN_SIZE {
        for x in 0..<TERRAIN_SIZE {
            terrain[y * TERRAIN_SIZE + x] = fbm(f32(x), f32(y), 6, 0.5, 2.0, 50.0, perm)
        }
    }
    return terrain
}

main :: proc() {
    allocator := context.allocator
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "raylib-odin [core] example - basic window")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)

    camera_distance: f32 = 200.0
    camera_angle := rl.Vector2{0.7, 0.7}
    camera := rl.Camera3D{
        position = rl.Vector3{math.cos(camera_angle.y) * math.cos(camera_angle.x) * camera_distance,
                              math.sin(camera_angle.x) * camera_distance,
                              math.sin(camera_angle.y) * math.cos(camera_angle.x) * camera_distance},
        target = rl.Vector3{0.0, -20.0, 0.0},
        up = rl.Vector3{0.0, 1.0, 0.0},
        fovy = 45.0,
        projection = rl.CameraProjection_Perspective,
    }

    terrain := generate_terrain(allocator, u32(rl.GetTime() * 1000000.0))
    defer allocator.free(terrain)
    water_level: f32 = INITIAL_WATER_LEVEL

    for !rl.WindowShouldClose() {
        // Camera rotation
        if rl.IsMouseButtonDown(rl.MouseButton_Left) {
            delta := rl.GetMouseDelta()
            camera_angle.x += delta.y * 0.003
            camera_angle.y -= delta.x * 0.003
            camera_angle.x = math.clamp(camera_angle.x, -math.PI/3.0, math.PI/3.0)
        }

        // Camera zoom
        wheel := rl.GetMouseWheelMove()
        if wheel != 0 {
            camera_distance *= (1.0 - wheel * 0.02)
            camera_distance = math.clamp(camera_distance, 10.0, 300.0)
        }
        camera.position = rl.Vector3{
            math.cos(camera_angle.y) * math.cos(camera_angle.x) * camera_distance,
            math.sin(camera_angle.x) * camera_distance,
            math.sin(camera_angle.y) * math.cos(camera_angle.x) * camera_distance,
        }

        // Reset camera
        if rl.IsKeyPressed(rl.KeyboardKey_Z) {
            camera_angle = rl.Vector2{0.7, 0.7}
            camera_distance = 200.0
        }

        // Regenerate terrain
        if rl.IsKeyPressed(rl.KeyboardKey_R) || rl.IsMouseButtonPressed(rl.MouseButton_Right) {
            allocator.free(terrain)
            terrain = generate_terrain(allocator, u32(rl.GetTime() * 1000000.0))
        }

        // Adjust water level
        if rl.IsKeyDown(rl.KeyboardKey_Comma)    { water_level = math.max(0.0, water_level - 0.1) }
        if rl.IsKeyDown(rl.KeyboardKey_Period)   { water_level += 0.1 }

        rl.BeginDrawing()
        rl.ClearBackground(rl.RAYWHITE)
        rl.BeginMode3D(camera)

        // Draw terrain
        for z in 0..<TERRAIN_SIZE {
            for x in 0..<TERRAIN_SIZE {
                height := terrain[z * TERRAIN_SIZE + x]
                cube_height := height * 20.0
                pos := rl.Vector3{
                    f32(x) * CUBE_SIZE - f32(TERRAIN_SIZE) * CUBE_SIZE / 2,
                    cube_height / 2,
                    f32(z) * CUBE_SIZE - f32(TERRAIN_SIZE) * CUBE_SIZE / 2,
                }
                color := rl.ColorFromHSV(120 * height, 0.8, 0.8)
                if cube_height < INITIAL_WATER_LEVEL * 2 {
                    color.r = u8(f32(color.r) * 0.7)
                    color.g = u8(f32(color.g) * 0.7)
                    color.b = u8(f32(color.b) * 0.7)
                }
                rl.DrawCube(pos, CUBE_SIZE, cube_height, CUBE_SIZE, color)
            }
        }

        // Draw water
        water_size := f32(TERRAIN_SIZE) * CUBE_SIZE
        water_pos := rl.Vector3{0, water_level, 0}
        rl.DrawCube(water_pos, water_size, 0.1, water_size, rl.ColorAlpha(rl., 0.5))

        rl.DrawGrid(10, 10.0)
        rl.EndMode3D()

        // Draw UI
        rl.DrawRectangle(10, 10, 245, 162, rl.Fade(rl.color.SKYBLUE, 0.5))
        rl.DrawRectangleLines(10, 10, 245, 162, rl.color.BLUE)
        rl.DrawText("Controls:", 20, 20, 10, rl.color.BLACK)
        rl.DrawText("- R or Right Mouse: Regenerate terrain", 40, 40, 10, rl.color.DARKGRAY)
        rl.DrawText("- , or .: Decrease/Increase water level", 40, 55, 10, rl.color.DARKGRAY)
        rl.DrawText("- Left Mouse: Rotate camera", 40, 70, 10, rl.DARKGRAY)
        rl.DrawText("- Mouse Wheel: Zoom in/out", 40, 85, 10, rl.DARKGRAY)
        rl.DrawText("- Z: Reset camera", 40, 100, 10, rl.DARKGRAY)
        rl.DrawText(fmt.sbprintf("", "Camera Angle X: %.2f", camera_angle.x), 20, 120, 10, rl.DARKGRAY)
        rl.DrawText(fmt.sbprintf("", "Camera Angle Y: %.2f", camera_angle.y), 20, 135, 10, rl.DARKGRAY)
        rl.DrawText(fmt.sbprintf("", "Camera Distance: %.2f", camera_distance), 20, 150, 10, rl.DARKGRAY)
        rl.DrawFPS(10, 180)
        rl.EndDrawing()
    }
}