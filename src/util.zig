const std = @import("std");
const builtin = @import("builtin");

/// Read input file and return lines as an ArrayList of strings
/// Caller owns the returned ArrayList and all strings within it
pub fn readInputFile(allocator: std.mem.Allocator, day: u8) ![][]u8 {
    var lines = std.array_list.Managed([]u8).init(allocator);
    errdefer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    // Build the file path
    var path_buf: [256]u8 = undefined;
    const path = try std.fmt.bufPrint(&path_buf, "input/day{d:0>2}.txt", .{day});

    // Open and read the file
    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        printColor(.red, "Error: Could not open file '{s}': {s}\n", .{ path, @errorName(err) }) catch {};
        std.process.exit(1);
    };
    defer file.close();

    const file_size = try file.getEndPos();
    const content = try allocator.alloc(u8, file_size);
    defer allocator.free(content);

    _ = try file.readAll(content);

    // Split into lines
    var it = std.mem.splitScalar(u8, content, '\n');
    while (it.next()) |line| {
        // Trim carriage return if present (Windows line endings)
        const trimmed = std.mem.trimRight(u8, line, "\r");
        if (trimmed.len > 0) {
            const line_copy = try allocator.dupe(u8, trimmed);
            try lines.append(line_copy);
        }
    }

    return lines.toOwnedSlice();
}

// Shared buffer and writer singleton
var stdout_buf: [4096]u8 = undefined;
var stdout_file_writer: ?std.fs.File.Writer = null;
var stdout_writer: ?*std.io.Writer = null;

fn getWriter() *std.io.Writer {
    if (stdout_writer == null) {
        stdout_file_writer = if (builtin.is_test)
            std.fs.File.stderr().writer(&stdout_buf)
        else
            std.fs.File.stdout().writer(&stdout_buf);
        stdout_writer = &stdout_file_writer.?.interface;
    }
    return stdout_writer.?;
}

/// Print text to stdout using the new writer pattern
pub fn print(comptime fmt: []const u8, args: anytype) !void {
    const writer = getWriter();
    try writer.print(fmt, args);
    try writer.flush();
}

/// ANSI color codes
pub const Color = enum {
    reset,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,

    pub fn code(self: Color) []const u8 {
        return switch (self) {
            .reset => "\x1b[0m",
            .red => "\x1b[31m",
            .green => "\x1b[32m",
            .yellow => "\x1b[33m",
            .blue => "\x1b[34m",
            .magenta => "\x1b[35m",
            .cyan => "\x1b[36m",
            .white => "\x1b[37m",
        };
    }
};

/// Print colored text to stdout
pub fn printColor(color: Color, comptime fmt: []const u8, args: anytype) !void {
    const writer = getWriter();
    try writer.writeAll(color.code());
    try writer.print(fmt, args);
    try writer.writeAll(Color.reset.code());
    try writer.flush();
}

/// Convert a multiline string to a slice of lines for testing
/// Caller owns the returned ArrayList
pub fn linesToSlice(allocator: std.mem.Allocator, input: []const u8) ![][]const u8 {
    var lines_list = std.array_list.Managed([]const u8).init(allocator);
    errdefer lines_list.deinit();

    var it = std.mem.splitScalar(u8, input, '\n');
    while (it.next()) |line| {
        try lines_list.append(line);
    }

    return lines_list.toOwnedSlice();
}

test "color codes" {
    try std.testing.expectEqualStrings("\x1b[31m", Color.red.code());
    try std.testing.expectEqualStrings("\x1b[0m", Color.reset.code());
}
