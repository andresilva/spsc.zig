const std = @import("std");

pub fn Ring(comptime T: type, cap: usize) type {
    return struct {
        items: [capacity]T = undefined,
        head: usize = 0,
        tail: usize = 0,
        mutex: std.Thread.Mutex = .{},

        pub const capacity = cap;

        pub fn enqueue(self: *@This(), item: T) bool {
            self.mutex.lock();
            defer self.mutex.unlock();

            if (self.head -% self.tail == capacity) {
                return false;
            }

            self.items[self.head % capacity] = item;
            self.head +%= 1;

            return true;
        }

        pub fn dequeue(self: *@This()) ?T {
            self.mutex.lock();
            defer self.mutex.unlock();

            if (self.head == self.tail) {
                return null;
            }

            const item = self.items[self.tail % capacity];
            self.tail +%= 1;

            return item;
        }

        pub fn isEmpty(self: *@This()) bool {
            self.mutex.lock();
            defer self.mutex.unlock();

            return self.head == self.tail;
        }

        pub fn isFull(self: *@This()) bool {
            self.mutex.lock();
            defer self.mutex.unlock();

            return self.head -% self.tail == capacity;
        }
    };
}
