const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const allocator = init.gpa;
    const stdout = std.Io.File.stdout();

    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len != 2) {
        std.debug.print("Usage: {s} <filename>\n", .{args[0]});
        return;
    }

    const filepath = args[1];
    const file = try std.Io.Dir.cwd().openFile(io, filepath, .{});
    defer file.close(io);

    const newfile = try std.Io.Dir.cwd().createFile(io, "output/output.csv", .{});
    defer newfile.close(io);
    
    var cleaned: std.ArrayList(u8) = .empty;
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
        while (i < bytes_read - 1) : (i += 2) { // keeps first byte and ignores empty
            try cleaned.append(allocator, data[i]);
            //        std.debug.print("{any}\n", .{buffer[i..i+2]});
            //        std.debug.print("{c}\n", .{buffer[i]});
        }
    }
    // contents points to heap allocated utf8 of entire file
    const contents = cleaned.items;

    // Iterate lines by tokenizing with \r\n
    var lines = std.mem.tokenizeAny(u8, contents, "\r\n");
    var writebuf: [124]u8 = undefined;

    const headerPrint = try std.fmt.bufPrint(&writebuf, "group,ml,amount\n", .{});
    try newfile.writeStreamingAll(io, headerPrint);
    try stdout.writeStreamingAll(io, headerPrint);
    
    while (true) {
        if (lines.next()) |line| {
            // iterate fields for each line by tokenizing with \t {9}
            //            var fields = std.mem.tokenizeScalar(u8, line, '\t');
            var fields = std.mem.splitScalar(u8, line, '\t');
            const x_mAU = fields.next() orelse unreachable;
            const y_mAU = fields.next() orelse unreachable;

            // Converting first two columns to f32 ensures header lines are skipped
            const x_mAU_d = std.fmt.parseFloat(f32, x_mAU) catch continue;
            const y_mAU_d = std.fmt.parseFloat(f32, y_mAU) catch continue;

            const absPrint = try std.fmt.bufPrint(&writebuf, "mAU,{d},{d}\n", .{ x_mAU_d, y_mAU_d });
            try newfile.writeStreamingAll(io, absPrint);
            try stdout.writeStreamingAll(io, absPrint);

            const x_Cond = fields.next() orelse continue;
            const y_Cond = fields.next() orelse continue;

            const x_Cond_d = std.fmt.parseFloat(f32, x_Cond) catch continue;
            const y_Cond_d = std.fmt.parseFloat(f32, y_Cond) catch continue;
            const condPrint = try std.fmt.bufPrint(&writebuf, "Cond,{d},{d}\n", .{ x_Cond_d, y_Cond_d });
            try newfile.writeStreamingAll(io, condPrint);
            try stdout.writeStreamingAll(io, condPrint);

            const x_Conc = fields.next() orelse continue;
            const y_Conc = fields.next() orelse continue;

            const x_Conc_d = std.fmt.parseFloat(f32, x_Conc) catch continue;
            const y_Conc_d = std.fmt.parseFloat(f32, y_Conc) catch continue;
            const concPrint = try std.fmt.bufPrint(&writebuf, "Conc,{d},{d}\n", .{ x_Conc_d, y_Conc_d });
            try newfile.writeStreamingAll(io, concPrint);
            try stdout.writeStreamingAll(io, concPrint);

        } else {
            break;
        }
    }
    std.debug.print("\n", .{});
    std.log.info("Output also written to ./output/output.csv\n", .{});
}
