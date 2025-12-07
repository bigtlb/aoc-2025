const std = @import("std");
const util = @import("util.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFile(allocator, 7);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
        allocator.free(lines);
    }

    try util.printColor(.cyan, "Day 07\n", .{});
    try util.printColor(.green, "Part 1: {d}\n", .{try part1(allocator, lines)});
    try util.printColor(.green, "Part 2: {d}\n", .{try part2(allocator, lines)});
}

fn splitBeam(lines: [][]u8, row: usize) !u64 {
    var count: u64 = 0;
    // try util.print("Processing row {d}, cols: {d}\n", .{ row, lines[row].len });
    if (row + 1 > lines.len - 1) return 0;
    for (lines[row], 0..lines[row].len) |c, col| {
        if (c == 'S' or c == '|') {
            // try util.print("Found beam at row {d}, col {d}\n", .{ row, col });
            const n = lines[row + 1][col];
            if (n == '^') {
                // try util.print("Beam splits at row {d}, col {d}\n", .{ row, col });
                count += 1;
                if (col > 0) lines[row + 1][col - 1] = '|';
                if (col + 1 < lines[row + 1].len) lines[row + 1][col + 1] = '|';
            } else {
                // try util.print("Beam continues at row {d}, col {d}\n", .{ row, col });
                lines[row + 1][col] = '|';
            }
        }
    }
    return count;
}

fn part1(allocator: std.mem.Allocator, lines: [][]u8) !u64 {
    _ = allocator;
    try util.print("\n--- Day 07 Part 1 ---\n", .{});
    var count: u64 = 0;
    for (0..lines.len) |row| {
        count += try splitBeam(lines, row);
    }
    return count;
}

fn countSplitsRecursive(
    lines: [][]u8,
    row: usize,
    col: usize,
    memo: *std.AutoHashMap(u64, u64),
) !u64 {
    // Check bounds
    if (row >= lines.len or col >= lines[row].len) {
        return 0;
    }

    // Check memoization
    const state_hash = (row << 32) | col;
    if (memo.get(state_hash)) |cached| {
        return cached;
    }

    // Move down one row
    const next_row = row + 1;
    if (next_row >= lines.len) {
        // Reached the bottom - this is 1 complete path
        try memo.put(state_hash, 1);
        return 1;
    }

    const next_char = lines[next_row][col];

    var total: u64 = 0;

    if (next_char == '^') {
        // This is a splitter!

        // Count paths going left
        if (col > 0) {
            total += try countSplitsRecursive(lines, next_row, col - 1, memo);
        }

        // Count paths going right
        if (col + 1 < lines[next_row].len) {
            total += try countSplitsRecursive(lines, next_row, col + 1, memo);
        }
    } else {
        // Continue straight down
        total = try countSplitsRecursive(lines, next_row, col, memo);
    }

    try memo.put(state_hash, total);
    return total;
}

fn part2(allocator: std.mem.Allocator, lines: [][]u8) !u64 {
    try util.print("\n--- Day 07 Part 2 ---\n", .{});

    // Find the 'S' starting position
    var start_row: usize = 0;
    var start_col: usize = 0;
    outer: for (lines, 0..) |line, row| {
        for (line, 0..) |c, col| {
            if (c == 'S') {
                start_row = row;
                start_col = col;
                break :outer;
            }
        }
    }

    // Create memoization map
    var memo = std.AutoHashMap(u64, u64).init(allocator);
    defer memo.deinit();

    // Start recursive traversal from S
    const total = try countSplitsRecursive(lines, start_row, start_col, &memo);

    return total;
}
const input =
    \\.......S.......
    \\...............
    \\.......^.......
    \\...............
    \\......^.^......
    \\...............
    \\.....^.^.^.....
    \\...............
    \\....^.^...^....
    \\...............
    \\...^.^...^.^...
    \\...............
    \\..^...^.....^..
    \\...............
    \\.^.^.^.^.^...^.
    \\...............
;

test "day07 part1" {
    var lines = try util.linesToSlice(std.testing.allocator, input);
    _ = &lines; //Suppress warning, since I will need to pass a mutable later
    defer {
        for (lines) |line| {
            std.testing.allocator.free(line);
        }
        std.testing.allocator.free(lines);
    }

    const result = try part1(std.testing.allocator, lines);
    try util.printColor(.blue, "Day 07 Part 1 result: {d}\n", .{result});
    try std.testing.expectEqual(21, result);
}

test "day07 part2" {
    var lines = try util.linesToSlice(std.testing.allocator, input);
    _ = &lines; //Suppress warning, since I will need to pass a mutable later
    defer {
        for (lines) |line| {
            std.testing.allocator.free(line);
        }
        std.testing.allocator.free(lines);
    }

    const result = try part2(std.testing.allocator, lines);
    try util.printColor(.blue, "Day 07 Part 2 result: {d}\n", .{result});
    try std.testing.expectEqual(40, result);
}
