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
    try util.printColor(.green, "Part 1: {d}\n", .{try part1(allocator, lines)});
    try util.printColor(.green, "Part 2: {d}\n", .{try part2(allocator, lines)});
}

// parses the input file and returns a cleaner format
fn parseInput(allocator: std.mem.Allocator, lines: [][]u8) !void {
    _ = allocator;
    _ = lines;
}

fn part1(allocator: std.mem.Allocator, lines: [][]u8) !u64 {
    try util.print("\n--- Day 02 Part 1 ---\n", .{});
    _ = allocator;
    _ = lines;
    // TODO: Implement part 1 solution
    return 0;
}

fn part2(allocator: std.mem.Allocator, lines: [][]u8) !u64 {
    try util.print("\n--- Day 02 Part 2 ---\n", .{});
    _ = allocator;
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
    const lines = try util.linesToSlice(std.testing.allocator, input);
    defer {
        for (lines) |line| {
            std.testing.allocator.free(line);
        }
        std.testing.allocator.free(lines);
    }

    const result = try part1(std.testing.allocator, lines);
    try util.printColor(.blue, "Day 02 Part 1 result: {d}\n", .{result});
    try std.testing.expectEqual(0, result);
}

test "day02 part2" {
    const lines = try util.linesToSlice(std.testing.allocator, input);
    defer {
        for (lines) |line| {
            std.testing.allocator.free(line);
        }
        std.testing.allocator.free(lines);
    }

    const result = try part2(std.testing.allocator, lines);
    try util.print("Day 02 Part 2 result: {d}\n", .{result});
    try std.testing.expectEqual(0, result);
}
