const std = @import("std");
const thread = @import("thread.zig");

const MutexRing = @import("mutex.zig").Ring;

const stdout = std.io.getStdOut().writer();

fn producer(queue: anytype, start: *std.time.Instant, warmup: usize, ops: usize) void {
    thread.setAffinity(1);

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

fn consumer(queue: anytype, end: *std.time.Instant, warmup: usize, ops: usize) void {
    thread.setAffinity(2);

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
    ops: usize = 100_000_000,
};

fn benchmark(opts: Benchmark) !void {
    thread.setAffinity(0);

    const warmup = opts.type.capacity * 4;
    var queue = opts.type{};

    var start: std.time.Instant = undefined;
    var end: std.time.Instant = undefined;

    var p = try std.Thread.spawn(.{}, producer, .{ &queue, &start, warmup, opts.ops });
    var c = try std.Thread.spawn(.{}, consumer, .{ &queue, &end, warmup, opts.ops });

    p.join();
    c.join();

    const elapsed = end.since(start);

    try stdout.print("{any} - ops/sec: {d:.2}M\n", .{ opts.type, @as(f64, @floatFromInt(opts.ops)) / @as(f64, @floatFromInt(elapsed)) * 1_000 });
}

pub fn main() !void {
    try benchmark(.{ .type = MutexRing(u64, 32) });
}
