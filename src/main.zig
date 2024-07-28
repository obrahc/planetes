const std = @import("std");
const math = std.math;
const rl = @import("raylib");

const Screen_width = 1920;
const Screen_height = 1080;
const Screen_center = [2]i32{ Screen_width / 2, Screen_height / 2 };
const G: @Vector(2, f32) = @splat(6.6743 * math.pow(f32, 10, -11));

const Particle = struct {
    position: @Vector(2, f32) = @Vector(2, f32){ 0, 0 },
    velocity: @Vector(2, f32) = @Vector(2, f32){ 0, 0 },
    mass: @Vector(2, f32) = @Vector(2, f32){ 0, 0 },

    pub fn distanceToParticle(self: *Particle, other: *Particle) @Vector(2, f32) {
        return other.*.position - self.*.position;
    }

    pub fn scalarDistanceToParticle(self: *Particle, other: *Particle) f32 {
        const distance: @Vector(2, f32) = self.distanceToParticle(other);
        const power = distance * distance;
        return math.sqrt(@abs(power[0] + power[1]));
    }
};

test "test scalar distance" {
    var p1: Particle = Particle{ .position = [2]f32{ 0, 0 } };
    var p2: Particle = Particle{ .position = [2]f32{ 1, 1 } };
    try std.testing.expect(p1.scalarDistanceToParticle(p2) == 1);
    std.log.debug("{any}", .{p1.scalarDistanceToParticle(p2)});
    p1 = Particle{ .position = [2]f32{ 0, 0 } };
    p2 = Particle{ .position = [2]f32{ 2, 2 } };
    try std.testing.expect(p1.scalarDistanceToParticle(p2) == 2);
    std.log.debug("{any}", .{p1.scalarDistanceToParticle(p2)});
    p1 = Particle{ .position = [2]f32{ 1, 1 } };
    p2 = Particle{ .position = [2]f32{ 4, 5 } };
    try std.testing.expect(p1.scalarDistanceToParticle(p2) == 5);
    std.log.debug("{any}", .{p1.scalarDistanceToParticle(p2)});
}

const System = struct {
    particles: [3]*Particle,
    elements: std.ArrayList(*Particle),
    allocator: std.mem.Allocator,

    pub fn init(particles: [3]*Particle, allocator: std.mem.Allocator) System {
        return System{ .particles = particles, .elements = std.ArrayList(*Particle).init(allocator), .allocator = allocator };
    }

    pub fn deinit(self: System) void {
        self.elements.deinit();
    }

    pub fn addParticle(self: *System, particle: *Particle) !void {
        try self.elements.append(particle);
    }

    pub fn iterate(self: *System) void {
        for (self.particles, 0..) |_, i| {
            for (self.particles, 0..) |_, j| {
                if (i == j) {
                    continue;
                }
                const particle: *Particle = self.particles[i];
                const other: *Particle = self.particles[j];
                const distance: @Vector(2, f32) = particle.distanceToParticle(other);
                const scalarDistanceVector: @Vector(2, f32) = @splat(math.pow(f32, particle.scalarDistanceToParticle(other), 3));
                const acc: @Vector(2, f32) = G * other.mass * distance / scalarDistanceVector;
                particle.*.position += particle.*.velocity;
                particle.*.velocity += acc;
            }
        }
    }

    pub fn getParticles(self: System) [3]*Particle {
        return self.particles;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);
    var p1 = Particle{ .position = Screen_center, .mass = [2]f32{ 1_000_000_000, 1_000_000_000 } };
    var p2 = Particle{ .position = [2]i32{ 0, 0 }, .velocity = [2]f32{ 0.005, 0 }, .mass = [2]f32{ 500_000_000, 500000000 } };
    var p3 = Particle{ .position = [2]i32{ Screen_width, 0 }, .velocity = [2]f32{ 0, 0.005 }, .mass = [2]f32{ 500_000_000, 500000000 } };
    const particles = [3]*Particle{ &p1, &p2, &p3 };
    var system = System.init(particles, allocator);
    defer system.deinit();
    try system.addParticle(&p1);
    try system.addParticle(&p2);
    try system.addParticle(&p3);

    rl.initWindow(Screen_width, Screen_height, "2-Body Simulation");
    defer rl.closeWindow();

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.white);
        for (system.getParticles()) |particle| {
            rl.drawCircle(@intFromFloat(particle.*.position[0]), @intFromFloat(particle.*.position[1]), 5, rl.Color.dark_gray);
        }
        system.iterate();
    }
}
