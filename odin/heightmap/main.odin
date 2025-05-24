package main

import "core:fmt"
import "vendor:raylib"

main :: proc() {
    raylib.InitWindow(800, 600, "Odin Terrain")
    raylib.SetTargetFPS(60)

    heightmap := raylib.LoadImage("assets/terrain.png")
    texture := raylib.LoadTextureFromImage(heightmap)

    mesh := raylib.GenMeshHeightmap(heightmap, raylib.Vector3{100, 20, 100})
    model := raylib.LoadModelFromMesh(mesh)
    model.materials[0].maps[raylib.MATERIAL_MAP_DIFFUSE].texture = texture

    camera := raylib.Camera{
        position = raylib.Vector3{50, 25, 50},
        target   = raylib.Vector3{0, 0, 0},
        up       = raylib.Vector3{0, 1, 0},
        fovy     = 45,
        projection = raylib.CAMERA_PERSPECTIVE,
    }

    raylib.SetCameraMode(camera, raylib.CAMERA_ORBITAL)

    for !raylib.WindowShouldClose() {
        raylib.UpdateCamera(&camera)

        raylib.BeginDrawing()
        raylib.ClearBackground(raylib.RAYWHITE)
        raylib.BeginMode3D(camera)

        raylib.DrawModel(model, raylib.Vector3{0, 0, 0}, 1.0, raylib.GREEN)
        raylib.DrawGrid(10, 10)

        raylib.EndMode3D()
        raylib.DrawText("Use mouse to orbit", 10, 10, 20, raylib.DARKGRAY)
        raylib.EndDrawing()
    }

    raylib.UnloadModel(model)
    raylib.UnloadTexture(texture)
    raylib.UnloadImage(heightmap)
    raylib.CloseWindow()
}
