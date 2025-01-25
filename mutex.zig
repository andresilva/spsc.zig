const std = @import("std");

pub fn Ring(comptime T: type, cap: usize) type {
    return struct {
        items: [cap]T = undefined,
        head_index: usize = 0,
        tail_index: usize = 0,
        mutex: std.Thread.Mutex = .{},

        pub const capacity = cap;

        pub fn enqueue(self: *@This(), t: T) bool {
            self.mutex.lock();
            defer self.mutex.unlock();

            if (self.len() == capacity) {
                return false;
            }

            self.items[self.head_index % capacity] = t;
            self.head_index += 1;

            return true;
        }

        pub fn dequeue(self: *@This()) ?T {
            self.mutex.lock();
            defer self.mutex.unlock();

            if (self.len() == 0) {
                return null;
            }

            const t = self.items[self.tail_index % capacity];
            self.tail_index += 1;

            return t;
        }

        fn len(self: *@This()) usize {
            return self.head_index - self.tail_index;
        }

        pub fn isEmpty(self: *@This()) bool {
            self.mutex.lock();
            defer self.mutex.unlock();

            return self.len() == 0;
        }
    };
}
