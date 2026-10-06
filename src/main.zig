const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const allocator = init.gpa;
//    const stdout = std.Io.File.stdout();

    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len != 2) {
        std.debug.print("Usage: {s} <filename>\n", .{args[0]});
        return;
    }

    const filepath = args[1];
    const file = try std.Io.Dir.cwd().openFile(io, filepath, .{});
    defer file.close(io);

    var cleaned:std.ArrayList(u8) = .empty;
    defer cleaned.deinit(allocator);

    var buffer: [1024]u8 = undefined;
    while (true) {
        const bytes_read = file.readStreaming(io, &.{&buffer}) catch |err| {
            if (err == error.EndOfStream) break;
            return err;
        };
        if (bytes_read == 0) {
            break;
        }

    const data = buffer[0..bytes_read];
    
    var i: u16 = 0;
    while (i < bytes_read - 1) : (i += 2) {
        try cleaned.append(allocator, data[i]);
//        std.debug.print("{any}\n", .{buffer[i..i+2]});
//        std.debug.print("{c}\n", .{buffer[i]});
    }

    }
    // Cleaned.items is heap allocated utf8 of entire file
    const contents = cleaned.items;
    std.debug.print("{s}\n", .{contents});
    std.debug.print("First character is: {c}, encoded by {any}\n", .{ contents[0], contents[0] });
    std.debug.print("Second character is: {c}, encoded by {any}\n", .{ contents[1], contents[1] });    
    // next iterate lines by tokenizing with /r/n {13, 10}

    // iterate fields for each line by tokenizing with \t {9}


}
