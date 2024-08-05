const std = @import("std");
const fmt = std.fmt;
const math = std.math;
const rl = @import("raylib");

const Screen_width = 1920;
const Screen_height = 1080;
const Screen_size = [2]f64{ Screen_width, Screen_height };
const Zero_vector = [2]f64{ 0, 0 };
const Screen_center = [2]i64{ Screen_width / 2, Screen_height / 2 };
const massFactor = [2]f64{ 1E21, 1E21 };
const G: @Vector(2, f64) = @splat(6.6743 * math.pow(f64, 10, -11));

const Particle = struct {
    id: u8 = 0,
    position: @Vector(2, f64) = @Vector(2, f64){ 0, 0 },
    velocity: @Vector(2, f64) = @Vector(2, f64){ 0, 0 },
    mass: @Vector(2, f64) = @Vector(2, f64){ 0, 0 },
    hidden: bool = false,

    pub fn distanceToParticle(self: *Particle, other: *Particle) @Vector(2, f64) {
        return (other.*.position - self.*.position);
    }

    pub fn scalarDistanceToParticle(self: *Particle, other: *Particle) f64 {
        const distance: @Vector(2, f64) = self.distanceToParticle(other);
        const power = distance * distance;
        return math.sqrt(@abs(power[0] + power[1]));
    }
};

test "test scalar distance" {
    var p1: Particle = Particle{ .position = [2]f64{ 0, 0 } };
    var p2: Particle = Particle{ .position = [2]f64{ 1, 1 } };
    try std.testing.expect(p1.scalarDistanceToParticle(p2) == 1);
    std.log.debug("{any}", .{p1.scalarDistanceToParticle(p2)});
    p1 = Particle{ .position = [2]f64{ 0, 0 } };
    p2 = Particle{ .position = [2]f64{ 2, 2 } };
    try std.testing.expect(p1.scalarDistanceToParticle(p2) == 2);
    std.log.debug("{any}", .{p1.scalarDistanceToParticle(p2)});
    p1 = Particle{ .position = [2]f64{ 1, 1 } };
    p2 = Particle{ .position = [2]f64{ 4, 5 } };
    try std.testing.expect(p1.scalarDistanceToParticle(p2) == 5);
    std.log.debug("{any}", .{p1.scalarDistanceToParticle(p2)});
}

const System = struct {
    elements: std.ArrayList(*Particle),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) System {
        return System{ .elements = std.ArrayList(*Particle).init(allocator), .allocator = allocator };
    }

    pub fn deinit(self: System) void {
        for (self.elements.items) |particle| {
            self.allocator.destroy(particle);
        }
        self.elements.deinit();
    }

    pub fn addParticle(self: *System, position: @Vector(2, f64), velocity: @Vector(2, f64), mass: @Vector(2, f64)) !void {
        const particle = try self.*.allocator.create(Particle);
        particle.* = Particle{ .position = position, .velocity = velocity, .mass = mass };
        try self.*.elements.append(particle);
    }

    fn integrate(_: *System, particle: *Particle, other: *Particle) void {
        // Fix integration when distances are really small
        const distance: @Vector(2, f64) = particle.distanceToParticle(other);
        const scalarDistanceVector: @Vector(2, f64) = @splat(math.pow(f64, particle.scalarDistanceToParticle(other), 3));
        const acc: @Vector(2, f64) = G * (other.mass / massFactor) * distance / scalarDistanceVector;
        //        std.debug.print("{any}, {any}, {any}, {any}\n", .{ acc, particle.mass, distance, scalarDistanceVector });
        particle.*.position += particle.*.velocity;
        if (@reduce(.Or, particle.*.position > Screen_size) or @reduce(.Or, particle.*.position < Zero_vector)) {
            particle.*.hidden = true;
        } else {
            particle.*.hidden = false;
        }
        particle.*.velocity += acc;
    }

    pub fn iterate(self: *System) void {
        for (self.elements.items, 0..) |_, i| {
            for (self.elements.items, 0..) |_, j| {
                if (i == j) {
                    continue;
                }
                const particle: *Particle = self.elements.items[i];
                const other: *Particle = self.elements.items[j];
                self.integrate(particle, other);
            }
        }
    }

    pub fn getParticles(self: System) []*Particle {
        return self.elements.items;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);
    var system = System.init(allocator);
    defer system.deinit();

    // Add the sun in the middle
    try system.addParticle(Screen_center, [2]f64{ 0, 0 }, [2]f64{ 1.9884E+30, 1.9884E+30 });

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
            try system.addParticle([2]f64{ ballPosition.x / camera.zoom, ballPosition.y / camera.zoom }, [2]f64{ 0.01, 0 }, [2]f64{ 1_000_000_000, 1_000_000_000 });
        }
        {
            camera.begin();
            defer camera.end();
            for (system.getParticles()) |particle| {
                rl.drawCircle(@intFromFloat(particle.*.position[0]), @intFromFloat(particle.*.position[1]), 5, rl.Color.dark_gray);
            }
            var buf: [256]u8 = undefined;
            const slice = try fmt.bufPrintZ(&buf, "Mouse Position: {any}\nZoom: {any}", .{ ballPosition, camera.zoom });
            rl.drawText(slice, @intFromFloat(10 * camera.zoom), @intFromFloat(10 * camera.zoom), @intFromFloat(20 / camera.zoom), rl.Color.black);
        }

        system.iterate();
    }
}
