const std = @import("std");
const util = @import("util.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFile(allocator, 5);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
        allocator.free(lines);
    }

    try util.printColor(.cyan, "Day 05\n", .{});
    try util.printColor(.green, "Part 1: {d}\n", .{try part1(allocator, lines)});
    try util.printColor(.green, "Part 2: {d}\n", .{try part2(allocator, lines)});
}

const Range = struct {
    start: u64,
    end: u64,
};

// parses the input file and returns a cleaner format
fn loadRanges(allocator: std.mem.Allocator, lines: []const []const u8, lastRangeLine: *u64) ![]Range {
    var ranges = std.array_list.Managed(Range).init(allocator);
    errdefer ranges.deinit();

    var curLine: u64 = 0;
    var line = lines[curLine];
    while (line.len > 0) {
        // try util.print("Parsing range: {s}\n", .{line});
        var it = std.mem.splitScalar(u8, line, '-');
        const startRange: u64 = try std.fmt.parseInt(u64, it.next().?, 10);
        const endRange: u64 = try std.fmt.parseInt(u64, it.next().?, 10);
        try ranges.append(Range{ .start = startRange, .end = endRange });
        curLine += 1;
        line = lines[curLine];
    }

    lastRangeLine.* = curLine;
    return ranges.toOwnedSlice();
}

fn part1(allocator: std.mem.Allocator, lines: []const []const u8) !u64 {
    try util.print("\n--- Day 05 Part 1 ---\n", .{});
    var curLine: u64 = 0;
    const ranges = try loadRanges(allocator, lines, &curLine);
    defer allocator.free(ranges);

    var freshIngredients: u64 = 0;
    for (curLine + 1..lines.len) |idx| {
        const ingredient = try std.fmt.parseInt(u64, lines[idx], 10);
        if (isFresh(ranges, ingredient)) freshIngredients += 1;
    }
    return freshIngredients;
}

fn isFresh(ranges: []const Range, ingredient: u64) bool {
    for (ranges) |range| {
        if (ingredient >= range.start and ingredient <= range.end) {
            return true;
        }
    }
    return false;
}

fn part2(allocator: std.mem.Allocator, lines: []const []const u8) !u64 {
    try util.print("\n--- Day 05 Part 2 ---\n", .{});
    var curLine: u64 = 0;
    const ranges = try loadRanges(allocator, lines, &curLine);
    defer allocator.free(ranges);

    std.sort.heap(Range, ranges, {}, struct {
        fn lessThan(_: void, a: Range, b: Range) bool {
            return a.start < b.start;
        }
    }.lessThan);

    //copy the ranges into a new array
    const rangesCopy = try allocator.alloc(Range, ranges.len);
    defer allocator.free(rangesCopy);
    std.mem.copyForwards(Range, rangesCopy, ranges);

    var rangeLen = ranges.len;

    // Scan from beginnning to end of the ranges, if one range starts inside of another range, then combine the ranges in the first position, and move the rest of the ranges down
    var rids: u64 = 0;
    try util.print("Total ranges: {d}\n", .{rangeLen});
    while (rids < rangeLen - 1) {
        if (rangesCopy[rids].end >= rangesCopy[rids + 1].start) {
            try util.print("Merging Range({d}, {d}) and Range({d},{d})\n", .{ rangesCopy[rids].start, rangesCopy[rids].end, rangesCopy[rids + 1].start, rangesCopy[rids + 1].end });
            if (rangesCopy[rids].end < rangesCopy[rids + 1].end) {
                rangesCopy[rids].end = rangesCopy[rids + 1].end;
            }
            std.mem.copyForwards(Range, rangesCopy[rids + 1 ..], rangesCopy[rids + 2 ..]);
            rangeLen -= 1;
            // Repeat check for this index
        } else rids += 1;
    }
    try util.print("Remaining ranges: {d}\n", .{rangeLen});
    var result: u64 = 0;
    for (rangesCopy[0..rangeLen]) |range| {
        try util.print("Range({d}, {d})\n", .{ range.start, range.end });
        result += (range.end - range.start + 1);
        try util.print("Result: {d}\n", .{result});
    }
    return result;
}
const input =
    \\3-5
    \\10-14
    \\16-20
    \\12-18
    \\
    \\1
    \\5
    \\8
    \\11
    \\17
    \\32
;

test "day05 part1" {
    const lines = try util.linesToSlice(std.testing.allocator, input);
    defer std.testing.allocator.free(lines);

    const result = try part1(std.testing.allocator, lines);
    try util.printColor(.blue, "Day 05 Part 1 result: {d}\n", .{result});
    try std.testing.expectEqual(3, result);
}

test "day05 part2" {
    const lines = try util.linesToSlice(std.testing.allocator, input);
    defer std.testing.allocator.free(lines);

    const result = try part2(std.testing.allocator, lines);
    try util.print("Day 05 Part 2 result: {d}\n", .{result});
    try std.testing.expectEqual(14, result);
}
