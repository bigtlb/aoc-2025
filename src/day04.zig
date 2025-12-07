const std = @import("std");
const util = @import("util.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFile(allocator, 4);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
        allocator.free(lines);
    }

    try util.printColor(.cyan, "Day 04\n", .{});
    try util.printColor(.green, "Part 1: {d}\n", .{try part1(allocator, lines)});
    try util.printColor(.green, "Part 2: {d}\n", .{try part2(allocator, lines)});
}

fn createInitialGrid(allocator: std.mem.Allocator, lines: []const []const u8) ![][]u8 {
    const grid: [][]u8 = try allocator.alloc([]u8, lines.len);
    for (grid, 0..lines.len) |*row, y| {
        row.* = try allocator.alloc(u8, lines[y].len);
        @memcpy(row.*, lines[y]);
    }
    return grid;
}

fn freeGrid(allocator: std.mem.Allocator, grid: [][]u8) void {
    for (grid) |row| {
        allocator.free(row);
    }
    allocator.free(grid);
}

fn isAccessible(lines: []const []const u8, y: usize, x: usize) bool {
    const directions = [8][2]isize{
        .{ -1, -1 }, .{ -1, 0 }, .{ -1, 1 }, // top row
        .{ 0, -1 }, .{ 0, 1 }, // left and right
        .{ 1, -1 }, .{ 1, 0 }, .{ 1, 1 }, // bottom row
    };

    var roll_count: usize = 0;

    for (directions) |dir| {
        const new_y = @as(isize, @intCast(y)) + dir[0];
        const new_x = @as(isize, @intCast(x)) + dir[1];

        // Check if the new position is within bounds
        if (new_y >= 0 and new_y < lines.len and new_x >= 0 and new_x < lines[0].len) {
            if (lines[@intCast(new_y)][@intCast(new_x)] == '@') {
                roll_count += 1;
            }
        }
    }

    return roll_count < 4;
}

fn gatherRolls(allocator: std.mem.Allocator, grid: [][]u8) !u64 {
    const ref_grid = try createInitialGrid(allocator, grid);
    defer freeGrid(allocator, ref_grid);

    for (ref_grid, 0..ref_grid.len) |line, y| {
        for (line, 0..line.len) |c, x| {
            if (c == '@') {
                grid[y][x] = if (isAccessible(ref_grid, y, x)) 'x' else '@';
            }
        }
    }
    // Count all the '@' in grid
    var result: usize = 0;
    for (grid) |row| {
        // try util.print("{s}\n", .{row});
        result += std.mem.count(u8, row, "x");
        // Set all the x's to .
        for (row) |*c| {
            if (c.* == 'x') c.* = '.';
        }
    }
    return result;
}

fn part1(allocator: std.mem.Allocator, lines: []const []const u8) !u64 {
    try util.printColor(.yellow, "\n--- Day 04 Part 1 ---\n", .{});
    const grid = try createInitialGrid(allocator, lines);
    defer freeGrid(allocator, grid);

    const result = try gatherRolls(allocator, grid);
    return result;
}

fn part2(allocator: std.mem.Allocator, lines: []const []const u8) !u64 {
    try util.printColor(.yellow, "\n--- Day 04 Part 2 ---\n", .{});
    const grid = try createInitialGrid(allocator, lines);
    defer freeGrid(allocator, grid);

    var result: usize = 0;
    var idx: usize = 0;
    var count = try gatherRolls(allocator, grid);

    // try util.printColor(.green, "\nLoop 0\n", .{});
    while (count > 0) {
        result += count;
        idx += 1;
        // try util.printColor(.green, "\nLoop {d}\n", .{idx});
        count = try gatherRolls(allocator, grid);
    }
    return result;
}
const input =
    \\..@@.@@@@.
    \\@@@.@.@.@@
    \\@@@@@.@.@@
    \\@.@@@@..@.
    \\@@.@@@@.@@
    \\.@@@@@@@.@
    \\.@.@.@.@@@
    \\@.@@@.@@@@
    \\.@@@@@@@@.
    \\@.@.@@@.@.
;

test "day04 part1" {
    const lines = try util.linesToSlice(std.testing.allocator, input);
    defer {
        for (lines) |line| {
            std.testing.allocator.free(line);
        }
        std.testing.allocator.free(lines);
    }

    const result = try part1(std.testing.allocator, lines);
    try util.printColor(.blue, "Day 04 Part 1 result: {d}\n", .{result});
    try std.testing.expectEqual(13, result);
}

test "day04 part2" {
    const lines = try util.linesToSlice(std.testing.allocator, input);
    defer {
        for (lines) |line| {
            std.testing.allocator.free(line);
        }
        std.testing.allocator.free(lines);
    }

    const result = try part2(std.testing.allocator, lines);
    try util.printColor(.blue, "Day 04 Part 2 result: {d}\n", .{result});
    // try std.testing.expectEqual(43, result);
}
