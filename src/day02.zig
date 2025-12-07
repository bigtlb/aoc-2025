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
    try util.print("\n--- Day 02 Part 1 ---\n", .{});
    var ranges = try parseRange(allocator, lines[0]);
    defer ranges.deinit();
    var total_covered: u64 = 0;
    var count: usize = 0;

    // Find the maximum value across all ranges to calculate max digits
    var max_val: u64 = 0;
    for (ranges.items) |r| {
        if (r.end > max_val) max_val = r.end;
    }

    // Calculate the number of digits in max_val
    const max_digits = if (max_val == 0) 1 else blk: {
        var temp = max_val;
        var d: u32 = 0;
        while (temp > 0) : (temp /= 10) {
            d += 1;
        }
        break :blk d;
    };

    // Round up to nearest even number for repeated-digit patterns
    const max_even_digits = if (max_digits % 2 == 0) max_digits else max_digits + 1;

    try util.print("Max value: {d}, Max digits: {d}, Checking up to {d}-digit patterns\n", .{ max_val, max_digits, max_even_digits });

    // Generate all repeated-digit numbers once, then check against all ranges
    var digits: u32 = 2;
    while (digits <= max_even_digits) : (digits += 2) {
        const half = digits / 2;
        const min_half = std.math.pow(u64, 10, half - 1);
        const max_half = std.math.pow(u64, 10, half) - 1;

        var half_num = min_half;
        while (half_num <= max_half) : (half_num += 1) {
            // Create the repeated number (e.g., 123 -> 123123)
            const num = half_num * std.math.pow(u64, 10, half) + half_num;

            // Early exit if we've exceeded all possible ranges
            if (num > max_val) break;

            // Check if this number falls in any range
            for (ranges.items) |r| {
                if (num >= r.start and num <= r.end) {
                    count += 1;
                    total_covered += num;
                    break; // Don't count the same number twice if ranges overlap
                }
            }
        }
    }

    try util.print("Found {d} matching numbers\n", .{count});
    return total_covered;
}

fn isRepeatedPattern(num: u64) bool {
    // Convert number to string to check pattern repetition
    var buf: [20]u8 = undefined;
    const digits = std.fmt.bufPrint(&buf, "{d}", .{num}) catch return false;
    const len = digits.len;

    // Try each possible pattern length (must divide evenly into total length)
    for (1..len / 2 + 1) |pattern_len| {
        if (len % pattern_len != 0) continue; // Pattern must divide evenly

        const repetitions = len / pattern_len;
        if (repetitions < 2) continue; // Need at least 2 repetitions

        // Check if the first pattern repeats throughout
        const pattern = digits[0..pattern_len];
        var is_match = true;
        var i: usize = pattern_len;
        while (i < len) : (i += pattern_len) {
            if (!std.mem.eql(u8, pattern, digits[i .. i + pattern_len])) {
                is_match = false;
                break;
            }
        }

        if (is_match) return true; // Found a repeating pattern
    }

    return false; // No repeating pattern found
}

fn part2(allocator: std.mem.Allocator, lines: []const []const u8) !u64 {
    try util.print("\n--- Day 02 Part 2 ---\n", .{});
    var ranges = try parseRange(allocator, lines[0]);
    defer ranges.deinit();
    var total_invalid: u64 = 0;
    var count: usize = 0;

    for (ranges.items) |r| {
        try util.print("Checking range {d}-{d}\n", .{ r.start, r.end });
        for (r.start..r.end + 1) |num| {
            if (isRepeatedPattern(num)) {
                total_invalid += num;
                count += 1;
            }
        }
    }

    try util.print("Found {d} invalid numbers (repeating patterns)\n", .{count});
    return total_invalid;
}

const input =
    \\11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124
;

test "day02 part1" {
    const lines_list = try util.linesToSlice(std.testing.allocator, input);
    defer {
        for (lines_list) |line| {
            std.testing.allocator.free(line);
        }
        std.testing.allocator.free(lines_list);
    }

    const result = try part1(std.testing.allocator, lines_list);
    try util.printColor(.blue, "Day 02 Part 1 result: {d}\n", .{result});
    try std.testing.expectEqual(1227775554, result);
}

test "day02 part2" {
    const lines_list = try util.linesToSlice(std.testing.allocator, input);
    defer {
        for (lines_list) |line| {
            std.testing.allocator.free(line);
        }
        std.testing.allocator.free(lines_list);
    }

    const result = try part2(std.testing.allocator, lines_list);
    try util.print("Day 02 Part 2 result: {d}\n", .{result});
    try std.testing.expectEqual(4174379265, result);
}
