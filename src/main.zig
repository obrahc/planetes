const std = @import("std");
const fmt = std.fmt;
const math = std.math;
const rl = @import("raylib");
const system = @import("system.zig");

const Screen_width = 1920;
const Screen_height = 1080;
pub const Screen_size = [2]f64{ Screen_width, Screen_height };
pub const Zero_vector = [2]f64{ 0, 0 };
pub const Screen_center = [2]i64{ Screen_width / 2, Screen_height / 2 };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);
    var s = system.System.init(allocator);
    defer s.deinit();

    // Add the sun in the middle
    try s.addParticle(Screen_center, [2]f64{ 0, 0 }, [2]f64{ 1.9884E+30, 1.9884E+30 });

    rl.initWindow(Screen_width, Screen_height, "2-Body Simulation");
    defer rl.closeWindow();

    var camera = rl.Camera2D{
        .target = rl.Vector2.init(0, 0),
        .offset = rl.Vector2.init(0, 0),
        .rotation = 0,
        .zoom = 1,
    };

    while (!rl.windowShouldClose()) {
        camera.zoom += rl.getMouseWheelMove() * 0.05;
        camera.zoom = rl.math.clamp(camera.zoom, 0.1, 3.0);

        if (rl.isKeyDown(rl.KeyboardKey.key_right)) {
            camera.target.x += 0.05;
        } else if (rl.isKeyDown(rl.KeyboardKey.key_left)) {
            camera.target.x -= 0.05;
        }

        if (rl.isKeyDown(rl.KeyboardKey.key_up)) {
            camera.target.y -= 0.05;
        } else if (rl.isKeyDown(rl.KeyboardKey.key_down)) {
            camera.target.y += 0.05;
        }

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.white);

        const ballPosition = rl.getMousePosition();

        if (rl.isMouseButtonPressed(rl.MouseButton.mouse_button_left)) {
            // TODO: Fix position of the new particle, it needs to take into account that you can move the camera target
            try s.addParticle([2]f64{ ballPosition.x / camera.zoom, ballPosition.y / camera.zoom }, [2]f64{ 0.01, 0 }, [2]f64{ 1_000_000_000, 1_000_000_000 });
        }
        {
            camera.begin();
            defer camera.end();
            for (s.getParticles()) |particle| {
                rl.drawCircle(@intFromFloat(particle.*.position[0]), @intFromFloat(particle.*.position[1]), 5, rl.Color.dark_gray);
            }
            var buf: [256]u8 = undefined;
            const slice = try fmt.bufPrintZ(&buf, "Mouse Position: {any}\nZoom: {any}", .{ ballPosition, camera.zoom });
            rl.drawText(slice, @intFromFloat(10 / camera.zoom), @intFromFloat(10 / camera.zoom), @intFromFloat(20 / camera.zoom), rl.Color.black);
        }

        s.iterate();
    }
}
