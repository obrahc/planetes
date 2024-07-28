const std = @import("std");
const raylib = @import("raylib");

pub fn main() !void {
    raylib.initWindow(800, 450, "raylib [core] example - basic window");
    defer raylib.closeWindow();

    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();
        defer raylib.endDrawing();
        raylib.clearBackground(raylib.Color.white);
        raylib.drawText("Congrats! You created your first window!", 190, 200, 20, raylib.Color.light_gray);
    }
}
