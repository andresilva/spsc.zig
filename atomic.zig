const std = @import("std");

pub fn Ring(comptime T: type, cap: usize) type {
    return struct {
        // NOTE: all fields aligned to cache line to avoid false sharing
        items: [capacity]T align(std.atomic.cache_line) = undefined,
        head: std.atomic.Value(usize) align(std.atomic.cache_line) = std.atomic.Value(usize).init(0),
        tail: std.atomic.Value(usize) align(std.atomic.cache_line) = std.atomic.Value(usize).init(0),
        cached_head: usize align(std.atomic.cache_line) = 0,
        cached_tail: usize align(std.atomic.cache_line) = 0,

        comptime {
            std.debug.assert(@alignOf(@This()) == std.atomic.cache_line);
        }

        pub const capacity = std.math.ceilPowerOfTwoAssert(usize, cap);
        pub const mask = capacity - 1;

        pub fn enqueue(self: *@This(), t: T) bool {
            const head = self.head.load(.unordered);

            if (head - self.cached_tail == capacity) {
                self.cached_tail = self.tail.load(.acquire);
                if (head - self.cached_tail == capacity) {
                    return false;
                }
            }

            self.items[head & mask] = t;
            self.head.store(head +% 1, .release);

            return true;
        }

        pub fn dequeue(self: *@This()) ?T {
            const tail = self.tail.load(.unordered);

            if (self.cached_head == tail) {
                self.cached_head = self.head.load(.acquire);
                if (self.cached_head == tail) {
                    return null;
                }
            }

            const t = self.items[tail & mask];
            self.tail.store(tail +% 1, .release);

            return t;
        }

        pub fn isEmpty(self: *@This()) bool {
            return self.head.load(.seq_cst) == self.tail.load(.seq_cst);
        }
    };
}
