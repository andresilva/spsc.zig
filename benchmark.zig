const std = @import("std");
const thread = @import("thread.zig");

const AtomicRing = @import("atomic.zig").Ring;
const MutexRing = @import("mutex.zig").Ring;

const stdout = std.io.getStdOut().writer();

fn producer(queue: anytype, start: *std.time.Instant, cpu: ?usize, warmup: usize, ops: usize) void {
    if (cpu) |c| thread.setAffinity(c);

    // warmup
    for (0..warmup) |i| {
        while (!queue.enqueue(i)) {}
    }

    while (!queue.isEmpty()) {
        std.time.sleep(1000);
    }

    start.* = std.time.Instant.now() catch unreachable;

    for (0..ops) |i| {
        while (!queue.enqueue(i)) {}
    }
}

fn consumer(queue: anytype, end: *std.time.Instant, cpu: ?usize, warmup: usize, ops: usize) void {
    if (cpu) |c| thread.setAffinity(c);

    // warm up
    for (0..warmup) |i| {
        while (true) {
            if (queue.dequeue()) |c| {
                if (c != i) {
                    @panic("it's over");
                }
                break;
            }
        }
    }

    for (0..ops) |i| {
        while (true) {
            if (queue.dequeue()) |c| {
                if (c != i) {
                    @panic("it's over");
                }
                break;
            }
        }
    }

    end.* = std.time.Instant.now() catch unreachable;
}

const Benchmark = struct {
    type: type,
    ops: usize = 1_000_000_000,
    cpus: ?[2]usize = null,
};

fn benchmark(opts: Benchmark) !void {
    if (opts.cpus) |_| thread.setAffinity(0);

    const warmup = opts.type.capacity * 4;
    var queue = opts.type{};

    var start: std.time.Instant = undefined;
    var end: std.time.Instant = undefined;

    var p = try std.Thread.spawn(.{}, producer, .{ &queue, &start, if (opts.cpus) |cpus| cpus[0] else null, warmup, opts.ops });
    var c = try std.Thread.spawn(.{}, consumer, .{ &queue, &end, if (opts.cpus) |cpus| cpus[1] else null, warmup, opts.ops });

    p.join();
    c.join();

    const elapsed = end.since(start);

    try stdout.print("{any} - ops/sec: {d:.2}M\n", .{ opts.type, @as(f64, @floatFromInt(opts.ops)) / @as(f64, @floatFromInt(elapsed)) * 1_000 });
}

pub fn main() !void {
    const sizes = [_]comptime_int{
        8,
        16,
        32,
        64,
        128,
        256,
        512,
        1024,
        2048,
        4096,
    };

    // This is based on AMD Ryzen 9 5950X
    const cpus = .{
        .{
            "no affinity",
            null,
        },
        .{
            "same smt",
            .{ 1, 17 },
        },
        .{
            "same ccd",
            .{ 1, 2 },
        },
        .{
            "different ccd",
            .{ 1, 8 },
        },
    };

    inline for (cpus) |c| {
        try stdout.print("=======================================\n", .{});
        try stdout.print("topology: {s}, cpus: {any}\n", .{ c[0], c[1] });
        try stdout.print("=======================================\n\n", .{});

        inline for (sizes) |size| {
            try benchmark(.{ .type = MutexRing(u64, size), .cpus = c[1] });
            try benchmark(.{ .type = AtomicRing(u64, size), .cpus = c[1] });
            try stdout.print("\n", .{});
        }
    }
}
