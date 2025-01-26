const std = @import("std");

pub fn Ring(comptime T: type, cap: usize) type {
    return struct {
        // NOTE: all fields aligned to cache line to avoid false sharing.
        // NOTE: we add an extra slot to the ring to be able to distinguish between
        // an empty and full ring. the ring is considered empty when the head and tail
        // are equal, and it's considered full when the head and tail are one slot apart.
        items: [capacity + 1]T align(std.atomic.cache_line) = undefined,
        head: std.atomic.Value(usize) align(std.atomic.cache_line) = std.atomic.Value(usize).init(0),
        tail: std.atomic.Value(usize) align(std.atomic.cache_line) = std.atomic.Value(usize).init(0),
        cached_head: usize align(std.atomic.cache_line) = 0,
        cached_tail: usize align(std.atomic.cache_line) = 0,

        comptime {
            std.debug.assert(@alignOf(@This()) == std.atomic.cache_line);
        }

        pub const capacity = cap;

        pub fn enqueue(self: *@This(), t: T) bool {
            const head = self.head.load(.unordered);

            if (isFull(head, self.cached_tail)) {
                self.cached_tail = self.tail.load(.acquire);
                if (isFull(head, self.cached_tail)) {
                    return false;
                }
            }

            self.items[head] = t;

            if (head == capacity) {
                self.head.store(0, .release);
            } else {
                self.head.store(head + 1, .release);
            }

            return true;
        }

        fn isFull(head: usize, tail: usize) bool {
            if (head < tail) {
                return head == tail - 1;
            } else if (tail < head) {
                return tail == head - capacity;
            } else {
                return false;
            }
        }

        pub fn dequeue(self: *@This()) ?T {
            const tail = self.tail.load(.unordered);

            if (self.cached_head == tail) {
                self.cached_head = self.head.load(.acquire);
                if (self.cached_head == tail) {
                    return null;
                }
            }

            const t = self.items[tail];

            if (tail == capacity) {
                self.tail.store(0, .release);
            } else {
                self.tail.store(tail + 1, .release);
            }

            return t;
        }

        pub fn isEmpty(self: *@This()) bool {
            return self.head.load(.unordered) == self.tail.load(.unordered);
        }
    };
}
