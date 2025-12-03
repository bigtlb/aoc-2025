const std = @import("std");
const util = @import("util.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFile(allocator, 3);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
        allocator.free(lines);
    }

    try util.printColor(.cyan, "Day 03\n", .{});
    try util.printColor(.green, "Part 1: {d}\n", .{try part1(lines)});
    try util.printColor(.green, "Part 2: {d}\n", .{try part2(lines)});
}

fn getMaxDigits(line: []const u8, numDigits: u8) u64 {
    // Find the largest set of numberof_digits in the string that are consecutive (not necessarily contiguous) in line
    var buf: [4096]u8 = undefined;
    std.mem.copyForwards(u8, &buf, line);
    var current_len = line.len;

    while (current_len > numDigits) {
        // Try removing each digit position and find which gives max result
        var best_buf: [4096]u8 = undefined;
        var best_len: usize = 0;
        var best_index: usize = 0;

        for (0..current_len) |skip_index| {
            // Build temp buffer without digit at skip_index
            var temp_buf: [4096]u8 = undefined;
            var temp_idx: usize = 0;

            for (buf[0..current_len], 0..) |c, i| {
                if (i != skip_index) {
                    temp_buf[temp_idx] = c;
                    temp_idx += 1;
                }
            }

            // Compare as digit strings: larger is better
            if (skip_index == 0) {
                // First iteration, just save it
                std.mem.copyForwards(u8, &best_buf, &temp_buf);
                best_len = temp_idx;
                best_index = skip_index;
            } else {
                // Compare temp_buf with best_buf lexicographically
                const cmp = std.mem.order(u8, temp_buf[0..temp_idx], best_buf[0..best_len]);
                if (cmp == .gt) {
                    std.mem.copyForwards(u8, &best_buf, &temp_buf);
                    best_len = temp_idx;
                    best_index = skip_index;
                }
            }
        }

        // Remove the digit at best_index from buf
        std.mem.copyForwards(u8, buf[best_index .. current_len - 1], buf[best_index + 1 .. current_len]);
        current_len -= 1;
    }

    const result = std.fmt.parseInt(u64, buf[0..current_len], 10) catch 0;
    util.print("Max digits: {d}\n", .{result}) catch {};
    // Parse the buf slice into a u64 and return
    return result;
}

fn part1(lines: []const []const u8) !u64 {
    try util.printColor(.yellow, "\n--- Day 03 Part 1 ---\n", .{});
    var total: u64 = 0;
    for (lines) |line| {
        total += getMaxDigits(line, 2);
    }
    return total;
}

fn part2(lines: []const []const u8) !u64 {
    try util.printColor(.yellow, "\n--- Day 03 Part 1 ---\n", .{});
    var total: u64 = 0;
    for (lines) |line| {
        total += getMaxDigits(line, 12);
    }
    return total;
}
const input =
    \\987654321111111
    \\811111111111119
    \\234234234234278
    \\818181911112111
;

test "day03 part1" {
    const lines = try util.linesToSlice(std.testing.allocator, input);
    defer std.testing.allocator.free(lines);

    const result = try part1(lines);
    try util.printColor(.blue, "Day 03 Part 1 result: {d}\n", .{result});
    try std.testing.expectEqual(357, result);
}

test "day03 part2" {
    const lines = try util.linesToSlice(std.testing.allocator, input);
    defer std.testing.allocator.free(lines);

    const result = try part2(lines);
    try util.print("Day 03 Part 2 result: {d}\n", .{result});
    try std.testing.expectEqual(3121910778619, result);
}
