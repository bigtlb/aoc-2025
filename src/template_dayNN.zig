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

    try util.printColor(.cyan, "Day NN\n", .{});
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

test "dayNN part1" {
    const lines = [_][]const u8{
        "example line 1",
        "example line 2",
    };
    const result = try part1(&lines);
    try util.printColor(.blue, "Part 1 result: {d}\n", .{result});
    try std.testing.expectEqual(@as(i64, 0), result);
}

test "dayNN part2" {
    const lines = [_][]const u8{
        "example line 1",
        "example line 2",
    };
    const result = try part2(&lines);
    try util.print("Part 2 result: {d}\n", .{result});
    try std.testing.expectEqual(@as(i64, 0), result);
}
