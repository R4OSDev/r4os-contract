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
extern fn r4os_rust_pmu_measure() callconv(.c) abi.R4DevFns.cpu_pmu_measure;
extern fn r4os_c_pmu_work(u64, u32) callconv(.c) i32;
extern fn r4os_rust_acceleration_info() callconv(.c) abi.R4DevFns.cpu_acceleration_info;
extern fn r4os_rust_acceleration_work() callconv(.c) abi.R4DevFns.cpu_acceleration_work;
extern fn r4os_c_pure_work(u64, u32) callconv(.c) i32;

fn zigWrite(data: [*]const u8, size: u32) callconv(.c) i32 {
    if (size != 9 or !std.mem.eql(u8, data[0..size], "R4OS-Rust")) return -1;
    return -32123;
}
fn work(context: usize) callconv(.c) i32 {
    return if (context == 0x8123_4567_89ab_cdef) -32768 else -1;
}

fn pmuWork(context: u64, iterations: u32) callconv(.c) i32 {
    return if (context == 0x8123_4567_89ab_cdef and iterations == 4096) -30007 else -1;
}
fn pureWork(context: u64, iterations: u32) callconv(.c) i32 {
    return if (context == 0x8123_4567_89ab_cdef and iterations == 64) -30017 else -1;
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

test "PMU typed borrowed callback slot and seven-argument C ABI preserve result tail" {
    const measure = r4os_rust_pmu_measure();
    const sentinel: u64 = 0xfedc_ba98_7654_3210;
    var guarded: extern struct { result: abi.CpuPmuResult = .{}, tail: u64 = sentinel } = .{};
    const callbacks = [_]abi.PmuWorkFn{ pmuWork, r4os_c_pmu_work };
    for (callbacks, [_]i32{ -30007, -30005 }) |callback, expected| {
        guarded.result.size = @sizeOf(@TypeOf(guarded));
        try std.testing.expectEqual(@as(i32, 0), measure(0xfedc_ba98, sentinel, abi.cpu_pmu_event_branch_misses, 4096, &callback, 0x8123_4567_89ab_cdef, &guarded.result));
        try std.testing.expectEqual(sentinel, guarded.tail);
        try std.testing.expectEqual(sentinel, guarded.result.epoch);
        try std.testing.expectEqual(@as(u64, 0x8123_4567_89ab_cdef), guarded.result.generation);
        try std.testing.expectEqual(expected, guarded.result.callback_result);
        try std.testing.expectEqual(@as(u32, 256), guarded.result.size);
        try std.testing.expectEqual(abi.cpu_pmu_result_flag_callback_started | abi.cpu_pmu_result_flag_callback_returned, guarded.result.flags);
    }
    const original = guarded;
    var zero: u64 = 0;
    for ([_]?*const abi.PmuWorkFn{ null, @ptrCast(&zero) }) |callback_slot| {
        try std.testing.expectEqual(abi.cpu_capabilities_error_invalid, measure(0xfedc_ba98, sentinel, abi.cpu_pmu_event_branch_misses, 4096, callback_slot, 0x8123_4567_89ab_cdef, &guarded.result));
        try std.testing.expectEqualSlices(u8, std.mem.asBytes(&original), std.mem.asBytes(&guarded));
    }
}

test "pure acceleration ABI keeps typed Rust Zig C slots, nullable refusal and128byte tails" {
    const sentinel: u64 = 0xfedc_ba98_7654_3210;
    var info: extern struct { value: abi.CpuAccelerationInfo = .{}, tail: u64 = sentinel } = .{};
    info.value.size = @sizeOf(@TypeOf(info));
    try std.testing.expectEqual(@as(i32, 0), r4os_rust_acceleration_info()(&info.value));
    try std.testing.expectEqual(sentinel, info.tail);
    try std.testing.expectEqual(sentinel, info.value.epoch);
    try std.testing.expectEqual(@as(u32, 128), info.value.size);
    try std.testing.expectEqual(@as(u64, 63), info.value.hardware_mask);
    try std.testing.expectEqual(@as(u64, 31), info.value.common_hardware_mask);
    var value: extern struct { value: abi.CpuAccelerationWork = .{}, tail: u64 = sentinel } = .{};
    const callbacks = [_]abi.CpuPureWorkFn{ pureWork, r4os_c_pure_work };
    const submit = r4os_rust_acceleration_work();
    for (callbacks, [_]i32{ -30017, -30015 }) |callback, expected| {
        value.value.size = @sizeOf(@TypeOf(value));
        try std.testing.expectEqual(@as(i32, 0), submit(abi.cpu_accel_work_kind_sha256, 64, &callback, 0x8123_4567_89ab_cdef, &value.value));
        try std.testing.expectEqual(sentinel, value.tail);
        try std.testing.expectEqual(sentinel, value.value.epoch);
        try std.testing.expectEqual(@as(u32, 128), value.value.size);
        try std.testing.expectEqual(@as(u32, 64), value.value.iterations);
        try std.testing.expectEqual(expected, value.value.callback_result);
        try std.testing.expectEqual(abi.cpu_accel_work_flag_callback_started | abi.cpu_accel_work_flag_callback_returned, value.value.flags);
    }
    const before = value;
    var zero: u64 = 0;
    for ([_]?*const abi.CpuPureWorkFn{ null, @ptrCast(&zero) }) |slot| {
        try std.testing.expectEqual(abi.cpu_capabilities_error_invalid, submit(abi.cpu_accel_work_kind_sha256, 64, slot, 0x8123_4567_89ab_cdef, &value.value));
        try std.testing.expectEqualSlices(u8, std.mem.asBytes(&before), std.mem.asBytes(&value));
    }
    info.value.version = 0;
    const old = info;
    try std.testing.expectEqual(abi.cpu_capabilities_error_invalid, r4os_rust_acceleration_info()(&info.value));
    try std.testing.expectEqualSlices(u8, std.mem.asBytes(&old), std.mem.asBytes(&info));
}
