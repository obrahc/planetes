const std = @import("std");
const math = std.math;
const main = @import("main.zig");
const particle = @import("particle.zig");

const massFactor = [2]f64{ 1E21, 1E21 };
const G: @Vector(2, f64) = @splat(6.6743 * math.pow(f64, 10, -11));

pub const System = struct {
    elements: std.ArrayList(*particle.Particle),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) System {
        return System{ .elements = std.ArrayList(*particle.Particle).init(allocator), .allocator = allocator };
    }

    pub fn deinit(self: System) void {
        for (self.elements.items) |p| {
            self.allocator.destroy(p);
        }
        self.elements.deinit();
    }

    pub fn addParticle(self: *System, position: @Vector(2, f64), velocity: @Vector(2, f64), mass: @Vector(2, f64)) !void {
        const p = try self.*.allocator.create(particle.Particle);
        p.* = particle.Particle{ .position = position, .velocity = velocity, .mass = mass };
        try self.*.elements.append(p);
    }

    fn integrate(_: *System, p: *particle.Particle, o: *particle.Particle) void {
        // Fix integration when distances are really small
        const distance: @Vector(2, f64) = p.distanceToParticle(o);
        const scalarDistanceVector: @Vector(2, f64) = @splat(math.pow(f64, p.scalarDistanceToParticle(o), 3));
        const acc: @Vector(2, f64) = G * (o.mass / massFactor) * distance / scalarDistanceVector;
        //        std.debug.print("{any}, {any}, {any}, {any}\n", .{ acc, particle.mass, distance, scalarDistanceVector });
        p.*.position += p.*.velocity;
        p.*.velocity += acc;
    }

    pub fn iterate(self: *System) void {
        for (self.elements.items, 0..) |_, i| {
            for (self.elements.items, 0..) |_, j| {
                if (i == j) {
                    continue;
                }
                const p: *particle.Particle = self.elements.items[i];
                const other: *particle.Particle = self.elements.items[j];
                self.integrate(p, other);
            }
        }
    }

    pub fn getParticles(self: System) []*particle.Particle {
        return self.elements.items;
    }

    // TODO: ClearAll method

};
