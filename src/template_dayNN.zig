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

    try util.printColor(.cyan, "Day 02\n", .{});
    try util.printColor(.green, "Part 1: {d}\n", .{try part1(lines)});
    try util.printColor(.green, "Part 2: {d}\n", .{try part2(lines)});
}

fn part1(lines: []const []const u8) !i64 {
    _ = lines;
    // TODO: Implement part 1 solution
    return 0;
}

fn part2(lines: []const []const u8) !i64 {
    _ = lines;
    // TODO: Implement part 2 solution
    return 0;
}
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

test "day02 part1" {
    const lines_list = try util.linesToSlice(std.testing.allocator, input);
    defer std.testing.allocator.free(lines_list);

    const result = try part1(lines_list);
    try util.printColor(.blue, "Day 02 Part 1 result: {d}\n", .{result});
    try std.testing.expectEqual(@as(i64, 0), result);
}

test "day02 part2" {
    const lines_list = try util.linesToSlice(std.testing.allocator, input);
    defer std.testing.allocator.free(lines_list);

    const result = try part2(lines_list);
    try util.print("Day 02 Part 2 result: {d}\n", .{result});
    try std.testing.expectEqual(@as(i64, 0), result);
}
