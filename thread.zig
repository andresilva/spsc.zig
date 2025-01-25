const std = @import("std");

// Set the affinity of the current thread to the given CPU.
pub fn setAffinity(cpu: usize) void {
    var cpu_set: std.os.linux.cpu_set_t = undefined;
    @memset(&cpu_set, 0);

    const cpu_elt = cpu / (@sizeOf(usize) * 8);
    const cpu_mask = @as(usize, 1) << @truncate(cpu % (@sizeOf(usize) * 8));
    cpu_set[cpu_elt] |= cpu_mask;

    _ = std.os.linux.syscall3(.sched_setaffinity, @as(usize, @bitCast(@as(isize, 0))), @sizeOf(std.os.linux.cpu_set_t), @intFromPtr(&cpu_set));
}
