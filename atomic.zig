const std = @import("std");

pub fn Ring(comptime T: type, cap: usize) type {
    return struct {
        items: [cap]T = undefined,
        head: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),
        tail: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),

        pub const capacity = cap;

        pub fn enqueue(self: *@This(), t: T) bool {
            const head = self.head.load(.unordered);
            const tail = self.tail.load(.acquire);

            if (head - tail == capacity) {
                return false;
            }

            self.items[head % capacity] = t;
            self.head.store(head + 1, .release);

            return true;
        }

        pub fn dequeue(self: *@This()) ?T {
            const head = self.head.load(.acquire);
            const tail = self.tail.load(.unordered);

            if (head - tail == 0) {
                return null;
            }

            const t = self.items[tail % capacity];
            self.tail.store(tail + 1, .release);

            return t;
        }

        pub fn isEmpty(self: *@This()) bool {
            return self.head.load(.seq_cst) - self.tail.load(.seq_cst) == 0;
        }
    };
}
