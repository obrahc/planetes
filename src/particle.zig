const std = @import("std");
const math = std.math;

pub const Particle = struct {
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
