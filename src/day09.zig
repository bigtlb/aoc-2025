const std = @import("std");
const util = @import("util.zig");
const math = std.math;

const Pair = struct {
    a: usize,
    b: usize,
    square: u64,
};

const Point = struct {
    x: i64,
    y: i64,
};

const Edge = struct {
    a: Point,
    b: Point,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFile(allocator, 9);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
        allocator.free(lines);
    }

    try util.printColor(.cyan, "Day 09\n", .{});
    try util.printColor(.green, "Part 1: {d}\n", .{try part1(allocator, lines)});
    try util.printColor(.green, "Part 2: {d}\n", .{try part2(allocator, lines)});
}

fn doesRectangleIntersect(edges: []const Edge, a: Point, b: Point) bool {
    const min_x = @min(a.x, b.x);
    const max_x = @max(a.x, b.x);
    const min_y = @min(a.y, b.y);
    const max_y = @max(a.y, b.y);

    for (edges) |edge| {
        const edge_min_x = @min(edge.a.x, edge.b.x);
        const edge_max_x = @max(edge.a.x, edge.b.x);
        const edge_min_y = @min(edge.a.y, edge.b.y);
        const edge_max_y = @max(edge.a.y, edge.b.y);

        // Exact Go logic: bounding box overlap test
        if (min_x < edge_max_x and max_x > edge_min_x and
            min_y < edge_max_y and max_y > edge_min_y)
        {
            return true; // Intersection found
        }
    }
    return false; // No intersection
}

fn getLargestSquarePairs(points: []const Point, loopBounded: bool) !?Pair {
    const point_len = points.len;
    if (point_len < 2) return null;

    // Convert polygon points to edges
    var edges = std.array_list.Managed(Edge).init(std.heap.page_allocator);
    defer edges.deinit();

    var i: usize = 0;
    while (i < points.len - 1) : (i += 1) {
        try edges.append(.{ .a = points[i], .b = points[i + 1] });
    }
    // Close the polygon
    try edges.append(.{ .a = points[points.len - 1], .b = points[0] });

    var largest_pair: ?Pair = null;
    var largest_square: u64 = 0;

    var from_idx: usize = 0;
    while (from_idx < point_len) : (from_idx += 1) {
        var to_idx: usize = from_idx;
        while (to_idx < point_len) : (to_idx += 1) {
            const from_point = points[from_idx];
            const to_point = points[to_idx];

            const square = (@abs(from_point.x - to_point.x) + 1) * (@abs(from_point.y - to_point.y) + 1);

            if (square > largest_square and
                (loopBounded == false or
                    doesRectangleIntersect(edges.items, from_point, to_point) == false))
            {
                if (loopBounded) {
                    // try util.print("Found larger square {d} at points {} and {}\n", .{ square, from_point, to_point });
                }
                largest_square = square;
                largest_pair = .{ .a = from_idx, .b = to_idx, .square = square };
            }
        }
    }

    return largest_pair;
}

// parses the input file and returns a cleaner format
fn makePoints(allocator: std.mem.Allocator, lines: [][]u8) ![]Point {
    var point_list = std.array_list.Managed(Point).init(allocator);

    for (lines) |line| {
        var it = std.mem.splitScalar(u8, line, ',');
        const x = try std.fmt.parseInt(i64, it.next().?, 10);
        const y = try std.fmt.parseInt(i64, it.next().?, 10);
        try point_list.append(.{ .x = x, .y = y });
    }

    // try util.print("Made point list with {d} points.\n", .{point_list.items.len});
    // try util.print("Which means there will be {d} pairs to test.\n", .{(point_list.items.len * (point_list.items.len - 1)) / 2});
    return point_list.toOwnedSlice();
}

fn part1(allocator: std.mem.Allocator, lines: [][]u8) !u64 {
    try util.print("\n--- Day 09 Part 1 ---\n", .{});
    const points = try makePoints(allocator, lines);
    defer allocator.free(points);

    var largest_pair = try getLargestSquarePairs(points, false);

    // const a = largest_pair.?.a;
    // const b = largest_pair.?.b;
    // const square: u64 = largest_pair.?.square;
    // try util.print("Largest pair: a={}, b={}, square={d}\n", .{ points[a], points[b], square });
    return largest_pair.?.square;
}

fn part2(allocator: std.mem.Allocator, lines: [][]u8) !u64 {
    try util.print("\n--- Day 09 Part 2 ---\n", .{});
    const points = try makePoints(allocator, lines);
    defer allocator.free(points);

    var largest_pair = try getLargestSquarePairs(points, true);

    // const a = largest_pair.?.a;
    // const b = largest_pair.?.b;
    // const square: u64 = largest_pair.?.square;
    // try util.print("Largest pair: a={}, b={}, square={d}\n", .{ points[a], points[b], square });
    return largest_pair.?.square;
}

const input =
    \\7,1
    \\11,1
    \\11,7
    \\9,7
    \\9,5
    \\2,5
    \\2,3
    \\7,3
;

test "day09 part1" {
    const lines = try util.linesToSlice(std.testing.allocator, input);
    defer {
        for (lines) |line| {
            std.testing.allocator.free(line);
        }
        std.testing.allocator.free(lines);
    }

    const result = try part1(std.testing.allocator, lines);
    // try util.printColor(.blue, "Day 09 Part 1 result: {d}\n", .{result});
    try std.testing.expectEqual(50, result);
}

test "day09 part2" {
    const lines = try util.linesToSlice(std.testing.allocator, input);
    defer {
        for (lines) |line| {
            std.testing.allocator.free(line);
        }
        std.testing.allocator.free(lines);
    }

    const result = try part2(std.testing.allocator, lines);
    try util.print("Day 09 Part 2 result: {d}\n", .{result});
    try std.testing.expectEqual(24, result);
}
