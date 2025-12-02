const std = @import("std");
const util = @import("util.zig");

const Range = struct {
    start: u64,
    end: u64,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFile(allocator, 2);
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

// parse a string like input (- and ,) into an array of ranges {start, end}
fn parseRange(allocator: std.mem.Allocator, range_str: []const u8) !std.array_list.Managed(Range) {
    var list = std.array_list.Managed(Range).init(allocator);
    errdefer list.deinit();
    try util.print("Parsing ranges from: {s}\n", .{range_str});

    var it = std.mem.splitScalar(u8, range_str, ',');
    while (it.next()) |part| {
        var range_it = std.mem.splitScalar(u8, part, '-');
        const start_str = range_it.next() orelse return error.InvalidRangeFormat;
        const end_str = range_it.next() orelse return error.InvalidRangeFormat;

        const start = try std.fmt.parseInt(u64, start_str, 10);
        const end = try std.fmt.parseInt(u64, end_str, 10);

        try list.append(Range{ .start = start, .end = end });
    }

    return list;
}

fn part1(allocator: std.mem.Allocator, lines: []const []const u8) !u64 {
    try util.print("\n--- Day 01 Part 1 ---\n", .{});
    var ranges = try parseRange(allocator, lines[0]);
    defer ranges.deinit();
    var total_covered: u64 = 0;
    for (ranges.items) |r| {
        try util.print("Range: {d}-{d}\n", .{ r.start, r.end });
        for (r.start..r.end + 1) |num| {
            const digits = std.fmt.allocPrint(allocator, "{d}", .{num}) catch continue;
            defer allocator.free(digits);
            // If this number is digits repeated twice it counts (e.g., 55, 123123)
            const len = digits.len;
            if (len % 2 == 0) {
                const half = len / 2;
                if (std.mem.eql(u8, digits[0..half], digits[half..len])) {
                    try util.print("  Covered number: {d}\n", .{num});
                    total_covered += num;
                }
            }
        }
    }
    return total_covered;
}

fn part2(allocator: std.mem.Allocator, lines: []const []const u8) !i64 {
    var ranges = try parseRange(allocator, lines[0]);
    defer ranges.deinit();
    // TODO: Implement part 2 solution
    return 0;
}
const input =
    \\11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124
;

test "day02 part1" {
    const lines_list = try util.linesToSlice(std.testing.allocator, input);
    defer std.testing.allocator.free(lines_list);

    const result = try part1(std.testing.allocator, lines_list);
    try util.printColor(.blue, "Day 02 Part 1 result: {d}\n", .{result});
    try std.testing.expectEqual(1227775554, result);
}

test "day02 part2" {
    const lines_list = try util.linesToSlice(std.testing.allocator, input);
    defer std.testing.allocator.free(lines_list);

    const result = try part2(std.testing.allocator, lines_list);
    try util.print("Day 02 Part 2 result: {d}\n", .{result});
    try std.testing.expectEqual(@as(i64, 0), result);
}
