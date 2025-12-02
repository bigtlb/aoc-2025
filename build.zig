const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Get the day option (1-12, or null for all days)
    const day_option = b.option(u8, "day", "Specify which day to run (1-12)");

    // Run step
    const run_step = b.step("run", "Run solution (use -Dday=N for specific day, or omit for all days)");

    if (day_option) |day| {
        // Run specific day
        if (day < 1 or day > 12) {
            std.debug.print("Error: day must be between 1 and 12\n", .{});
            std.process.exit(1);
        }

        const day_file = std.fmt.allocPrint(b.allocator, "src/day{d:0>2}.zig", .{day}) catch @panic("OOM");
        const exe = b.addExecutable(.{
            .name = std.fmt.allocPrint(b.allocator, "day{d:0>2}", .{day}) catch @panic("OOM"),
            .root_module = b.createModule(.{
                .root_source_file = b.path(day_file),
                .target = target,
                .optimize = optimize,
            }),
        });

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.setCwd(b.path(".")); // Set working directory to project root
        run_step.dependOn(&run_cmd.step);
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
    } else {
        // Run all days that exist
        var day: u8 = 1;
        while (day <= 12) : (day += 1) {
            const day_file = std.fmt.allocPrint(b.allocator, "src/day{d:0>2}.zig", .{day}) catch @panic("OOM");

            // Check if file exists (runtime check during build)
            std.fs.cwd().access(day_file, .{}) catch continue;

            const exe = b.addExecutable(.{
                .name = std.fmt.allocPrint(b.allocator, "day{d:0>2}", .{day}) catch @panic("OOM"),
                .root_module = b.createModule(.{
                    .root_source_file = b.path(day_file),
                    .target = target,
                    .optimize = optimize,
                }),
            });

            const run_cmd = b.addRunArtifact(exe);
            run_cmd.setCwd(b.path(".")); // Set working directory to project root
            run_step.dependOn(&run_cmd.step);
        }
    }

    // Test step
    const test_step = b.step("test", "Run tests (use -Dday=N for specific day, or omit for all days)");

    if (day_option) |day| {
        // Test specific day
        if (day < 1 or day > 12) {
            std.debug.print("Error: day must be between 1 and 12\n", .{});
            std.process.exit(1);
        }

        const day_file = std.fmt.allocPrint(b.allocator, "src/day{d:0>2}.zig", .{day}) catch @panic("OOM");
        const day_test = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(day_file),
                .target = target,
                .optimize = optimize,
            }),
        });

        const run_day_test = b.addRunArtifact(day_test);
        test_step.dependOn(&run_day_test.step);
    } else {
        // Test all days that exist
        var day: u8 = 1;
        while (day <= 12) : (day += 1) {
            const day_file = std.fmt.allocPrint(b.allocator, "src/day{d:0>2}.zig", .{day}) catch @panic("OOM");

            // Check if file exists (runtime check during build)
            std.fs.cwd().access(day_file, .{}) catch continue;

            const day_test = b.addTest(.{
                .root_module = b.createModule(.{
                    .root_source_file = b.path(day_file),
                    .target = target,
                    .optimize = optimize,
                }),
            });

            const run_day_test = b.addRunArtifact(day_test);
            test_step.dependOn(&run_day_test.step);
        }

        // Add util tests
        const util_test = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/util.zig"),
                .target = target,
                .optimize = optimize,
            }),
        });
        const run_util_test = b.addRunArtifact(util_test);
        test_step.dependOn(&run_util_test.step);
    }
}
