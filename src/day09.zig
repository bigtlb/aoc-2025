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

fn areCornersInside(points: []const Point, a: Point, b: Point) bool {
    const corners = getRectangleCorners(a, b);

    for (corners) |corner| {
        if (!isPointInPolygon(corner, points)) {
            return false;
        }
    }
    return true;
}

fn getRectangleCorners(a: Point, b: Point) [4]Point {
    const min_x = @min(a.x, b.x);
    const max_x = @max(a.x, b.x);
    const min_y = @min(a.y, b.y);
    const max_y = @max(a.y, b.y);

    return [_]Point{
        .{ .x = min_x, .y = min_y },
        .{ .x = max_x, .y = min_y },
        .{ .x = max_x, .y = max_y },
        .{ .x = min_x, .y = max_y },
    };
}

fn doEdgesIntersect(rect_corners: [4]Point, polygon: []const Point) bool {
    if (polygon.len < 3) return false;

    // Check each rectangle edge against each polygon edge
    var rect_i: usize = 0;
    while (rect_i < 4) : (rect_i += 1) {
        const rect_start = rect_corners[rect_i];
        const rect_end = rect_corners[(rect_i + 1) % 4];

        var poly_i: usize = 0;
        while (poly_i < polygon.len) : (poly_i += 1) {
            const poly_start = polygon[poly_i];
            const poly_end = polygon[(poly_i + 1) % polygon.len];

            // Skip if they share an endpoint (sharing edges is allowed)
            if (rect_start.x == poly_start.x and rect_start.y == poly_start.y) continue;
            if (rect_start.x == poly_end.x and rect_start.y == poly_end.y) continue;
            if (rect_end.x == poly_start.x and rect_end.y == poly_start.y) continue;
            if (rect_end.x == poly_end.x and rect_end.y == poly_end.y) continue;

            if (doLineSegmentsIntersect(rect_start, rect_end, poly_start, poly_end)) {
                return true;
            }
        }
    }
    return false;
}

fn doLineSegmentsIntersect(rectangle_start: Point, rectangle_end: Point, polygon_start: Point, polygon_end: Point) bool {
    // Check if rectangle edge and polygon edge intersect
    const counter_clockwise1 = ccw(rectangle_start, rectangle_end, polygon_start);
    const counter_clockwise2 = ccw(rectangle_start, rectangle_end, polygon_end);
    const counter_clockwise3 = ccw(polygon_start, polygon_end, rectangle_start);
    const counter_clockwise4 = ccw(polygon_start, polygon_end, rectangle_end);

    // General case
    if (counter_clockwise1 * counter_clockwise2 < 0 and counter_clockwise3 * counter_clockwise4 < 0) {
        return true;
    }

    // Special cases (collinear)
    if (counter_clockwise1 == 0 and isPointOnLineSegment(polygon_start, rectangle_start, rectangle_end)) return true;
    if (counter_clockwise2 == 0 and isPointOnLineSegment(polygon_end, rectangle_start, rectangle_end)) return true;
    if (counter_clockwise3 == 0 and isPointOnLineSegment(rectangle_start, polygon_start, polygon_end)) return true;
    if (counter_clockwise4 == 0 and isPointOnLineSegment(rectangle_end, polygon_start, polygon_end)) return true;

    return false;
}

fn ccw(a: Point, b: Point, c: Point) i64 {
    // Returns positive if counter-clockwise, negative if clockwise, 0 if collinear
    return (b.x_coordinate - a.x_coordinate) * (c.y_coordinate - a.y_coordinate) - (b.y_coordinate - a.y_coordinate) * (c.x_coordinate - a.x_coordinate);
}

fn isPointOnLineSegment(point: Point, a: Point, b: Point) bool {
    // Check if point lies on the line segment between a and b
    const cross = (point.y - a.y) * (b.x - a.x) - (point.x - a.x) * (b.y - a.y);
    if (cross != 0) return false; // Not collinear

    const dot = (point.x - a.x) * (point.x - b.x) + (point.y - a.y) * (point.y - b.y);
    if (dot > 0) return false; // Point is beyond the segment

    const squared_length = (b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y);
    if (dot + squared_length < 0) return false; // Point is before the segment

    return true;
}

fn isPointInPolygon(point: Point, polygon: []const Point) bool {
    if (polygon.len < 3) return false;

    var inside = false;
    var i: usize = 0;
    const n = polygon.len;

    while (i < n) : (i += 1) {
        const j = (i + 1) % n;
        const vi = polygon[i];
        const vj = polygon[j];

        // Check if point is on edge (sharing edges is allowed)
        if (isPointOnLineSegment(point, vi, vj)) {
            return true;
        }

        // Ray casting: cast horizontal ray to the right
        if (((vi.y > point.y) != (vj.y > point.y)) and
            (point.x < (vj.x - vi.x) * (point.y - vi.y) / (vj.y - vi.y) + vi.x))
        {
            inside = !inside;
        }
    }

    return inside;
}

fn isRectangleFullyContained(points: []const Point, a: Point, b: Point) bool {
    // First check corners are inside
    if (!areCornersInside(points, a, b)) return false;

    // Then check no polygon edges intersect rectangle interior
    const rect_corners = getRectangleCorners(a, b);
    return !doEdgesIntersect(rect_corners, points);
}

fn getLargestSquarePairs(points: []const Point, loopBounded: bool) !?Pair {
    const point_len = points.len;
    if (point_len < 2) return null;

    var largest_pair: ?Pair = null;
    var largest_square: u64 = 0;

    var i: usize = 0;
    while (i < point_len) : (i += 1) {
        var j: usize = i + 1;
        while (j < point_len) : (j += 1) {
            const square = @abs(points[i].x - points[j].x + 1) * @abs(points[i].y - points[j].y + 1);
            if (square > largest_square and
                (loopBounded == false or
                    isRectangleFullyContained(points, points[i], points[j])))
            {
                largest_square = square;
                largest_pair = .{ .a = i, .b = j, .square = square };
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

    return point_list.toOwnedSlice();
}

fn part1(allocator: std.mem.Allocator, lines: [][]u8) !u64 {
    try util.print("\n--- Day 09 Part 1 ---\n", .{});
    const points = try makePoints(allocator, lines);
    defer allocator.free(points);

    var largest_pair = try getLargestSquarePairs(points, false);

    const a = largest_pair.?.a;
    const b = largest_pair.?.b;
    const square: u64 = largest_pair.?.square;
    try util.print("Largest pair: a={}, b={}, square={d}\n", .{ points[a], points[b], square });
    return largest_pair.?.square;
}

fn part2(allocator: std.mem.Allocator, lines: [][]u8) !u64 {
    try util.print("\n--- Day 09 Part 2 ---\n", .{});
    const points = try makePoints(allocator, lines);
    defer allocator.free(points);

    var largest_pair = try getLargestSquarePairs(points, true);

    const a = largest_pair.?.a;
    const b = largest_pair.?.b;
    const square: u64 = largest_pair.?.square;
    try util.print("Largest pair: a={}, b={}, square={d}\n", .{ points[a], points[b], square });
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
    try util.printColor(.blue, "Day 09 Part 1 result: {d}\n", .{result});
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
    try std.testing.expectEqual(0, result);
}
