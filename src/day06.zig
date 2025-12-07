const std = @import("std");
const util = @import("util.zig");

const Op = enum { Add, Multiply };

const Problem = struct { numbers: []u64, operation: Op };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFile(allocator, 6);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
        allocator.free(lines);
    }

    try util.printColor(.cyan, "Day 06\n", .{});
    try util.printColor(.green, "Part 1: {d}\n", .{try part1(allocator, lines)});
    try util.printColor(.green, "Part 2: {d}\n", .{try part2(allocator, lines)});
}

// parses the input file and returns a cleaner format
fn parseInput1(allocator: std.mem.Allocator, lines: []const []const u8) ![]Problem {
    // First, count how many problems we have by counting spaces in first line
    var count: usize = 0;
    var it = std.mem.tokenizeScalar(u8, lines[0], ' ');
    while (it.next()) |_| count += 1;

    var problems = try allocator.alloc(Problem, count);
    errdefer {
        for (problems) |p| {
            allocator.free(p.numbers);
        }
        allocator.free(problems);
    }

    for (problems) |*problem| {
        problem.numbers = try allocator.alloc(u64, lines.len - 1);
    }

    for (lines[0 .. lines.len - 1], 0..lines.len - 1) |line, row_idx| {
        it = std.mem.tokenizeScalar(u8, line, ' ');
        var col_idx: usize = 0;
        while (it.next()) |num_str| {
            const num = std.fmt.parseInt(u64, num_str, 10) catch |err| {
                try util.printColor(.red, "Error: Could not parse number on row {d}, col {d}: {s}\n", .{ row_idx, col_idx, @errorName(err) });
                std.process.exit(1);
            };
            problems[col_idx].numbers[row_idx] = num;
            col_idx += 1;
        }
    }

    var op_it = std.mem.tokenizeScalar(u8, lines[lines.len - 1], ' ');
    var col_idx: usize = 0;
    while (op_it.next()) |op_str| {
        const op = switch (op_str[0]) {
            '+' => Op.Add,
            '*' => Op.Multiply,
            else => return error.InvalidOperation,
        };
        problems[col_idx].operation = op;
        col_idx += 1;
    }

    try util.print("Parsed {d} problems:\n", .{count});
    return problems;
}

// parses the input file and returns a cleaner format
fn parseInput2(allocator: std.mem.Allocator, lines: []const []const u8) ![]Problem {
    var problem_array = std.array_list.Managed(Problem).init(allocator);
    errdefer problem_array.deinit();

    var cur_column: usize = 0;
    var cur_op: u8 = ' ';
    var num_buf: []u8 = try allocator.alloc(u8, lines.len - 1);
    defer allocator.free(num_buf);
    var num_buf_idx: usize = undefined;

    // try util.print("Total columns to process: {d}\n", .{lines[0].len});
    while (cur_column <= lines[0].len) {
        var numbers_array = std.array_list.Managed(u64).init(allocator);
        errdefer numbers_array.deinit();

        var foundNumber: bool = true;

        while (foundNumber) {
            num_buf_idx = 0;
            foundNumber = false;
            if ((cur_column < lines[lines.len - 1].len) and (lines[lines.len - 1][cur_column] != ' ')) {
                cur_op = lines[lines.len - 1][cur_column];
            }

            for (lines[0 .. lines.len - 1]) |line| {
                if (cur_column >= line.len) {
                    // try util.print("Skipping line {s}, column {d} because it is out of bounds\n", .{ line, cur_column });
                    continue;
                }
                // try util.print("Reading line {s}, column {d}: '{c}' current num_buf: '{s}'\n", .{ line, cur_column, line[cur_column], num_buf[0..num_buf_idx] });

                num_buf[num_buf_idx] = line[cur_column];
                num_buf_idx += 1;
                if (line[cur_column] != ' ') {
                    foundNumber = true;
                }
            }

            // try util.print("Finished reading numbers for column {d}, foundNumber: {}\n", .{ cur_column, foundNumber });

            if (foundNumber) {
                const trimmed = std.mem.trim(u8, num_buf[0..num_buf_idx], " ");
                const num = std.fmt.parseInt(u64, trimmed, 10) catch |err| {
                    try util.printColor(.red, "Error: Could not parse number at column {d}: '{s}' {s}\n", .{ cur_column, trimmed, @errorName(err) });
                    std.process.exit(1);
                };
                // try util.print("Parsed number at column {d}: {d}\n", .{ cur_column, num });
                try numbers_array.append(num);
            } else {
                // try util.print("No more numbers found for column {d}, creating problem with operation: {c}\n", .{ cur_column, cur_op });
                problem_array.append(Problem{
                    .numbers = try numbers_array.toOwnedSlice(),
                    .operation = switch (cur_op) {
                        '+' => Op.Add,
                        '*' => Op.Multiply,
                        else => return error.InvalidOperation,
                    },
                }) catch |err| {
                    try util.printColor(.red, "Error: Could not append problem at column {d}: {s}\n", .{ cur_column, @errorName(err) });
                    std.process.exit(1);
                };
                numbers_array.clearRetainingCapacity();
                cur_op = ' ';
                // try util.print("Next problem created at column {d}\n", .{cur_column});
                // try util.print("Numbers collected: ", .{});
                // for (numbers_array.items) |n| {
                //     try util.print("{d} ", .{n});
                // }
                // try util.print("\n", .{});
                // try util.print("Operation: {s}\n", .{switch (cur_op) {
                //     '+' => "Addition",
                //     '*' => "Multiplication",
                //     else => "Unknown",
                // }});
            }
            cur_column += 1;
        }
    }

    // print out each problem and the number and operation
    try util.print("Parsed {d} problems:\n", .{problem_array.items.len});
    cur_column = 0;

    return problem_array.toOwnedSlice();
}

fn compute(problems: []const Problem) !u64 {
    var total: u64 = 0;
    for (problems) |problem| {
        var problemTotal: u64 = problem.numbers[0];
        for (problem.numbers[1..]) |num| {
            problemTotal = switch (problem.operation) {
                .Add => num + problemTotal,
                .Multiply => num * problemTotal,
            };
        }
        // try util.print("Problem total: {d}, Operation: {s}\n", .{ problemTotal, switch (problem.operation) {
        //     .Add => "Addition",
        //     .Multiply => "Multiplication",
        // } });
        total += problemTotal;
    }
    return total;
}

fn part1(allocator: std.mem.Allocator, lines: []const []const u8) !u64 {
    try util.print("\n--- Day 06 Part 1 ---\n", .{});
    const problems = try parseInput1(allocator, lines);
    defer {
        for (problems) |p| {
            allocator.free(p.numbers);
        }
        allocator.free(problems);
    }

    return compute(problems);
}

fn part2(allocator: std.mem.Allocator, lines: []const []const u8) !u64 {
    try util.print("\n--- Day 06 Part 2 ---\n", .{});
    const problems = try parseInput2(allocator, lines);
    defer {
        for (problems) |p| {
            allocator.free(p.numbers);
        }
        allocator.free(problems);
    }

    return compute(problems);
}

const input =
    \\123 328  51 64 
    \\ 45 64  387 23 
    \\  6 98  215 314
    \\*   +   *   +  
;

test "day06 part1" {
    const lines = try util.linesToSlice(std.testing.allocator, input);
    defer {
        for (lines) |line| {
            std.testing.allocator.free(line);
        }
        std.testing.allocator.free(lines);
    }

    const result = try part1(std.testing.allocator, lines);
    try util.printColor(.blue, "Day 06 Part 1 result: {d}\n", .{result});
    try std.testing.expectEqual(4277556, result);
}

test "day06 part2" {
    const lines = try util.linesToSlice(std.testing.allocator, input);
    defer {
        for (lines) |line| {
            std.testing.allocator.free(line);
        }
        std.testing.allocator.free(lines);
    }

    const result = try part2(std.testing.allocator, lines);
    try util.printColor(.blue, "Day 06 Part 2 result: {d}\n", .{result});
    try std.testing.expectEqual(3263827, result);
}
