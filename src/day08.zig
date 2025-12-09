const std = @import("std");
const util = @import("util.zig");

const Pair = struct {
    a: usize,
    b: usize,
    dist: i64,
};

const Point = struct {
    x: i64,
    y: i64,
    z: i64,
};

fn squaredEuclidianDistance(a: Point, b: Point) i64 {
    return (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y) + (a.z - b.z) * (a.z - b.z);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFile(allocator, 8);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
        allocator.free(lines);
    }

    try util.printColor(.cyan, "Day 08\n", .{});
    try util.printColor(.green, "Part 1: {d}\n", .{try part1(allocator, lines, 1000)});
    try util.printColor(.green, "Part 2: {d}\n", .{try part2(allocator, lines)});
}

// parses the input file and returns a cleaner format
fn makePoints(allocator: std.mem.Allocator, lines: []const []const u8) ![]const Point {
    var pointList = std.array_list.Managed(Point).init(allocator);
    errdefer pointList.deinit();

    for (lines) |line| {
        var it = std.mem.splitScalar(u8, line, ',');
        pointList.append(.{
            .x = try std.fmt.parseInt(i64, it.next().?, 10),
            .y = try std.fmt.parseInt(i64, it.next().?, 10),
            .z = try std.fmt.parseInt(i64, it.next().?, 10),
        }) catch |err| return err;
    }
    return pointList.toOwnedSlice();
}

fn getShortestDistancePairs(allocator: std.mem.Allocator, points: []const Point, n: usize) ![]const Pair {

    // Implement logic to find the n shortest distance between any pairs using the squarEuclidianDistance function

    const point_len = points.len;
    if (point_len < 2 or n == 0) return &[_]Pair{};

    const total_pairs = (point_len * (point_len - 1)) / 2;
    const k_eff = if (n > total_pairs) total_pairs else n;

    var pairs = try std.array_list.Managed(Pair).initCapacity(allocator, total_pairs);

    var i: usize = 0;
    while (i < point_len) : (i += 1) {
        var j: usize = i + 1;
        while (j < point_len) : (j += 1) {
            const d = squaredEuclidianDistance(points[i], points[j]);
            try pairs.append(.{ .a = i, .b = j, .dist = d });
        }
    }

    std.sort.heap(Pair, pairs.items, {}, struct {
        fn lessThan(_: void, a: Pair, b: Pair) bool {
            return a.dist < b.dist;
        }
    }.lessThan);

    const all_pairs = try pairs.toOwnedSlice();
    defer allocator.free(all_pairs);
    return allocator.dupe(Pair, all_pairs[0..k_eff]);
}

fn getDistancesToAllPairs(allocator: std.mem.Allocator, points: []const Point) ![]const Pair {
    return getShortestDistancePairs(allocator, points, points.len * (points.len - 1) / 2);
}

fn addPairToCircuit(allocator: std.mem.Allocator, circuits: *std.array_list.Managed(std.AutoHashMap(usize, void)), pair: Pair) !void {
    // Scan the circuits to see// Find which circuit (if any) contains point a
    var a_circuit: ?*std.AutoHashMap(usize, void) = null;
    var b_circuit: ?*std.AutoHashMap(usize, void) = null;
    var b_circuit_idx: ?usize = null;

    for (circuits.items) |*circuit| {
        if (circuit.get(pair.a)) |_| {
            a_circuit = circuit;
            break;
        }
    }

    // Find which circuit (if any) contains point b
    for (circuits.items, 0..) |*circuit, idx| {
        if (circuit.get(pair.b)) |_| {
            b_circuit = circuit;
            b_circuit_idx = idx;
            break;
        }
    }

    // If they are both in circuits, combine those circuits
    // If one is in a circuit but the other isn't, add it to that circuit
    // If neither is in a circuit, create a new circuit

    if (a_circuit == null and b_circuit == null) {
        // try util.print("Creating new circuit with points {d} and {d}\n", .{ pair.a, pair.b });
        var junctions = std.AutoHashMap(usize, void).init(allocator);
        try junctions.put(pair.a, {});
        try junctions.put(pair.b, {});
        try circuits.append(junctions);
    } else if (a_circuit == null and b_circuit != null) {
        // try util.print("Adding point {d} to existing circuit containing point {d}\n", .{ pair.a, pair.b });
        b_circuit.?.put(pair.a, {}) catch unreachable;
    } else if (a_circuit != null and b_circuit == null) {
        // try util.print("Adding point {d} to existing circuit containing point {d}\n", .{ pair.b, pair.a });
        a_circuit.?.put(pair.b, {}) catch unreachable;
    } else if (a_circuit == b_circuit) {
        // try util.print("Points are already in the same circuit\n", .{});
    } else if (a_circuit != null and b_circuit != null) {
        // try util.print("Combining two circuits\n", .{});
        // Add b_circuit elements to a_circuit, and remove b circuit from the circuist list.
        var keys = b_circuit.?.iterator();
        while (keys.next()) |entry| {
            a_circuit.?.put(entry.key_ptr.*, {}) catch unreachable;
        }
        // Remove b_circuit from circuits list
        if (b_circuit_idx) |idx| {
            var removed = circuits.orderedRemove(idx);
            removed.deinit();
        }
    }
}

fn part1(allocator: std.mem.Allocator, lines: [][]u8, n: usize) !usize {
    try util.print("\n--- Day 08 Part 1 ---\n", .{});
    const points = try makePoints(allocator, lines);
    defer allocator.free(points);

    const shortest_distance_pairs = try getShortestDistancePairs(allocator, points, n);
    defer allocator.free(shortest_distance_pairs);

    // An array of circuits. Each circuits contains points that are in the circuit, referenced by their index in the point array,
    // which is also how they are reference in the pairs
    var circuits = std.array_list.Managed(std.AutoHashMap(usize, void)).init(allocator);
    defer {
        for (circuits.items) |*circuit| {
            circuit.deinit();
        }
        circuits.deinit();
    }

    for (shortest_distance_pairs) |pair| {
        // try util.print("Processing pair: a={d}, b={d}, dist={d}\n", .{ pair.a, pair.b, pair.dist });
        try addPairToCircuit(allocator, &circuits, pair);
    }

    // Get the count of each circuit hashmap, and then sort that count largest first
    var counts = try allocator.alloc(usize, circuits.items.len);
    defer allocator.free(counts);
    for (0..circuits.items.len) |i| {
        counts[i] = circuits.items[i].count();
    }
    std.sort.heap(usize, counts, {}, struct {
        fn lessThan(context: void, a: usize, b: usize) bool {
            _ = context;
            return a > b; // Sort descending
        }
    }.lessThan);

    // for (counts) |count| {
    //     try util.print("Circuit size: {d}\n", .{count});
    // }

    // return the multiple of the top three counts
    return counts[0] * counts[1] * counts[2];
}

fn part2(allocator: std.mem.Allocator, lines: [][]u8) !i64 {
    try util.print("\n--- Day 08 Part 2 ---\n", .{});
    const points = try makePoints(allocator, lines);
    defer allocator.free(points);

    const shortest_distance_pairs = try getDistancesToAllPairs(allocator, points);
    defer allocator.free(shortest_distance_pairs);

    // An array of circuits. Each circuits contains points that are in the circuit,
    // referenced by their index in the point array,
    // which is also how they are reference in the pairs
    var circuits = std.array_list.Managed(std.AutoHashMap(usize, void)).init(allocator);
    defer {
        for (circuits.items) |*circuit| {
            circuit.deinit();
        }
        circuits.deinit();
    }

    var cur_idx: usize = 0;
    var last_processed_pair: ?Pair = null;
    while (circuits.items.len == 0 or circuits.items.len > 1 or (circuits.items.len == 1 and circuits.items[0].count() < points.len)) : (cur_idx += 1) {
        const cur_pair = shortest_distance_pairs[cur_idx];
        last_processed_pair = cur_pair;
        // try util.print("Processing pair: a={d}, b={d}, dist={d}\n", .{ cur_pair.a, cur_pair.b, cur_pair.dist });
        try addPairToCircuit(allocator, &circuits, cur_pair);
    }

    // Get the count of each circuit hashmap, and then sort that count largest first
    var counts = try allocator.alloc(usize, circuits.items.len);
    defer allocator.free(counts);
    for (0..circuits.items.len) |i| {
        counts[i] = circuits.items[i].count();
    }
    std.sort.heap(usize, counts, {}, struct {
        fn lessThan(context: void, a: usize, b: usize) bool {
            _ = context;
            return a > b; // Sort descending
        }
    }.lessThan);

    // for (counts) |count| {
    //     try util.print("Circuit size: {d}\n", .{count});
    // }

    // try util.print("Last pair: a={d}, b={d}, dist={d}\n", .{ last_processed_pair.?.a, last_processed_pair.?.b, last_processed_pair.?.dist });
    // try util.print("Pair coordinates: ({d},{d}) -> ({d},{d})\n", .{ points[last_processed_pair.?.a].x, points[last_processed_pair.?.a].y, points[last_processed_pair.?.b].x, points[last_processed_pair.?.b].y });
    return points[last_processed_pair.?.a].x * points[last_processed_pair.?.b].x;
}
const input =
    \\162,817,812
    \\57,618,57
    \\906,360,560
    \\592,479,940
    \\352,342,300
    \\466,668,158
    \\542,29,236
    \\431,825,988
    \\739,650,466
    \\52,470,668
    \\216,146,977
    \\819,987,18
    \\117,168,530
    \\805,96,715
    \\346,949,466
    \\970,615,88
    \\941,993,340
    \\862,61,35
    \\984,92,344
    \\425,690,689
;

test "day08 part1" {
    const lines = try util.linesToSlice(std.testing.allocator, input);
    defer {
        for (lines) |line| {
            std.testing.allocator.free(line);
        }
        std.testing.allocator.free(lines);
    }

    const result = try part1(std.testing.allocator, lines, 10);
    try util.printColor(.blue, "Day 08 Part 1 result: {d}\n", .{result});
    try std.testing.expectEqual(40, result);
}

test "day08 part2" {
    const lines = try util.linesToSlice(std.testing.allocator, input);
    defer {
        for (lines) |line| {
            std.testing.allocator.free(line);
        }
        std.testing.allocator.free(lines);
    }

    const result = try part2(std.testing.allocator, lines);
    try util.print("Day 08 Part 2 result: {d}\n", .{result});
    try std.testing.expectEqual(25272, result);
}
