const std = @import("std");

pub fn Ring(comptime T: type, cap: usize) type {
    return struct {
        items: [cap]T = undefined,
        head: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),
        tail: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),

        pub const capacity = cap;

        pub fn enqueue(self: *@This(), t: T) bool {
            if (self.len() == capacity) {
                return false;
            }

            self.items[self.head.load(.seq_cst) % capacity] = t;
            _ = self.head.fetchAdd(1, .seq_cst);

            return true;
        }

        pub fn dequeue(self: *@This()) ?T {
            if (self.len() == 0) {
                return null;
            }

            const t = self.items[self.tail.load(.seq_cst) % capacity];
            _ = self.tail.fetchAdd(1, .seq_cst);

            return t;
        }

        fn len(self: *@This()) usize {
            return self.head.load(.seq_cst) - self.tail.load(.seq_cst);
        }

        pub fn isEmpty(self: *@This()) bool {
            return self.len() == 0;
        }
    };
}
