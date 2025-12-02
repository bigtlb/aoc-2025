const std = @import("std");
const util = @import("util.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFile(allocator, 1);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
        allocator.free(lines);
    }

    try util.printColor(.cyan, "Day 01\n", .{});
    try util.printColor(.green, "Part 1: {d}\n", .{try part1(lines)});
    try util.printColor(.green, "Part 2: {d}\n", .{try part2(lines)});
}

fn part1(lines: []const []const u8) !usize {
    try util.print("\n--- Part 1 ---\n", .{});
    var dial_num: i16 = 50;
    var counter: usize = 0;

    for (lines) |line| {
        if (line.len == 0) continue;

        const direction = line[0];
        const value = try std.fmt.parseInt(i16, line[1..], 10);

        // try util.print("Current dial: {d},\tInstruction: {c}{d},\t", .{ dial_num, direction, value });
        dial_num = @mod(if (direction == 'L')
            dial_num - value
        else if (direction == 'R')
            dial_num + value
        else
            dial_num, 100);

        if (dial_num == 0) {
            counter += 1;
        }
        // try util.print("New dial: {d}\n", .{dial_num});
    }

    return counter;
}

fn part2(lines: []const []const u8) !usize {
    try util.print("\n--- Part 2 ---\n", .{});
    var dial_num: i32 = 50;
    var counter: usize = 0;

    for (lines) |line| {
        if (line.len == 0) continue;

        const direction = line[0];
        const value = try std.fmt.parseInt(i32, line[1..], 10);

        const new_val = if (direction == 'L')
            dial_num - value
        else if (direction == 'R')
            dial_num + value
        else
            dial_num;

        // Count how many times we cross 0
        // Since dial_num is always 0-99, we just need abs of the end block
        const end_div = @divFloor(new_val, 100);
        const wraps: usize = @intCast(@abs(end_div));

        if (wraps > 0) {
            counter += wraps;
        }

        dial_num = @mod(new_val, 100);
    }

    return counter;
}

test "day01 part1" {
    const input =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;

    const lines_list = try util.linesToSlice(std.testing.allocator, input);
    defer std.testing.allocator.free(lines_list);

    const result = try part1(lines_list);
    try util.printColor(.blue, "Part 1 result: {d}\n", .{result});
    try std.testing.expectEqual(3, result);
}

test "day01 part2" {
    const input =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;

    const lines_list = try util.linesToSlice(std.testing.allocator, input);
    defer std.testing.allocator.free(lines_list);

    const result = try part2(lines_list);
    try util.printColor(.blue, "Part 2 result: {d}\n", .{result});
    try std.testing.expectEqual(6, result);
}
