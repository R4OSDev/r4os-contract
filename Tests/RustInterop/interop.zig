const std = @import("std");
const abi = @import("r4os_technical_abi");
extern fn r4os_rust_write() callconv(.c) abi.R4SysFns.write;
extern fn r4os_rust_call_write(abi.R4SysFns.write) callconv(.c) i32;
extern fn r4os_rust_service_call() callconv(.c) abi.R4SysFns.service_call;
extern fn r4os_rust_driver_work(*const abi.DriverWorkRequest, *u32) callconv(.c) i32;
extern fn r4os_rust_optional_callback(?abi.DriverWorkHandler, usize) callconv(.c) i32;
extern fn r4os_rust_protocol_buffer(*const abi.ProtocolBuffer, *abi.ProtocolBuffer) callconv(.c) i32;
extern fn r4os_rust_enum(abi.DriverType) callconv(.c) abi.DriverType;
extern fn r4os_rust_default_header(*abi.ServiceMessageHeader) callconv(.c) void;
extern fn r4os_c_rust_call(abi.R4SysFns.write, [*]const u8, u32) callconv(.c) i32;

fn zigWrite(data: [*]const u8, size: u32) callconv(.c) i32 {
    if (size != 9 or !std.mem.eql(u8, data[0..size], "R4OS-Rust")) return -1;
    return -32123;
}
fn work(context: usize) callconv(.c) i32 {
    return if (context == 0x8123_4567_89ab_cdef) -32768 else -1;
}

test "canonical Rust/Zig/C callbacks, nullability, stack arguments and SIMD consumer" {
    const rust_write = r4os_rust_write();
    try std.testing.expectEqual(@as(i32, -12345), rust_write("R4OS-Rust", 9));
    try std.testing.expectEqual(@as(i32, -32123), r4os_rust_call_write(zigWrite));
    try std.testing.expectEqual(@as(i32, -12345), r4os_c_rust_call(rust_write, "R4OS-Rust", 9));

    var header: abi.ServiceMessageHeader = .{};
    var reply: [3]u8 = undefined;
    const service_call = r4os_rust_service_call();
    try std.testing.expectEqual(@as(i32, -32767), service_call(0xfedc_ba98, 0xabc7, "R4OS-Rust", 9, &header, &reply, 3, 0xfedc_ba98_7654_3210));
    try std.testing.expectEqual(@as(u16, 0xabc7), header.op);
    try std.testing.expectEqual(@as(u32, 0xfedc_ba98), header.request_id);
    try std.testing.expectEqual(@as(i32, -32767), header.status);
    try std.testing.expectEqualStrings("ACK", &reply);

    const request: abi.DriverWorkRequest = .{ .handler = work, .context = 0x8123_4567_89ab_cdef, .serial_key = 0x8123_4567_89ab_cdef, .deadline_tick = 0xfedc_ba98_7654_3210, .budget_ticks = 4 };
    var ticket: u32 = 0;
    try std.testing.expectEqual(@as(i32, -32768), r4os_rust_driver_work(&request, &ticket));
    try std.testing.expectEqual(@as(u32, 0xfedc_ba98), ticket);
    try std.testing.expectEqual(abi.err_no_fn, r4os_rust_optional_callback(null, 0));
    try std.testing.expectEqual(@as(i32, -32768), r4os_rust_optional_callback(work, request.context));

    var data = [_]u8{0} ** 16;
    const source: abi.ProtocolBuffer = .{ .data = &data, .len = 9, .capacity = 16, .flags = 0x8000_0001 };
    var output: abi.ProtocolBuffer = .{};
    try std.testing.expectEqual(@as(i32, 17), r4os_rust_protocol_buffer(&source, &output));
    try std.testing.expectEqual(source.data, output.data);
    try std.testing.expectEqual(source.flags, output.flags);
    var null_source = source;
    null_source.data = null;
    try std.testing.expectEqual(@as(i32, 17), r4os_rust_protocol_buffer(&null_source, &output));
    try std.testing.expectEqual(@as(?*anyopaque, null), output.data);
    try std.testing.expectEqual(abi.DriverType.display, r4os_rust_enum(.net));
    header.status = -1;
    r4os_rust_default_header(&header);
    const original_header: abi.ServiceMessageHeader = .{};
    try std.testing.expectEqual(original_header.magic, header.magic);
    try std.testing.expectEqual(@as(i32, 0), header.status);
}
