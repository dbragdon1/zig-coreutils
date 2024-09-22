const std = @import("std");

test "count lines" {}

pub fn count(reader: std.fs.File.Reader, filename: []const u8) !void {
    var buffer: [4096]u8 = undefined;

    var wc: usize = 0; // word count
    var lc: usize = 0; // line count
    var bc: usize = 0; // byte count

    while (true) {
        const bytesRead = try reader.read(&buffer);

        bc += bytesRead;

        if (bytesRead == 0) {
            break;
        }

        for (buffer) |byte| {
            if (byte == '\n') {
                wc += 1;
                lc += 1;
            } else if (byte == ' ') {
                wc += 1;
            }
        }
    }

    std.debug.print(" {d} {d} {d} {s}\n", .{ lc, wc, bc, filename });
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);

    defer args.deinit();

    _ = args.skip(); // skip the program name

    var arg_count: usize = 0;
    var filename: []const u8 = "-";

    while (args.next()) |arg| {
        filename = arg;
        arg_count += 1;
        break;
    }

    var reader: std.fs.File.Reader = undefined;

    if (arg_count == 0) {
        const stdin = std.io.getStdIn();
        reader = stdin.reader();
        try count(reader, filename);
    } else {
        var file = std.fs.cwd().openFile(filename, .{}) catch |err| switch (err) {
            std.posix.OpenError.AccessDenied => {
                std.debug.print("wc: {s}: Access denied\n", .{filename});
                return;
            },
            std.posix.OpenError.FileNotFound => {
                std.debug.print("wc: {s}: No such file or directory\n", .{filename});
                return;
            },
            else => {
                std.debug.print("wc: {s}: Unexpected Error\n", .{filename});
                return;
            },
        };

        defer file.close();
        reader = file.reader();
        try count(reader, filename);
    }
}
