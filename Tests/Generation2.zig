const std = @import("std");
const api = @import("r4os_contract2");
const c = @cImport({
    @cInclude("r4os/generation2.h");
});

test "new generation has distinct identities and exact compact layouts in C and Zig" {
    @setEvalBranchQuota(100_000);
    try std.testing.expectEqual(@as(usize, 24), @sizeOf(api.R4LQuery2));
    try std.testing.expectEqual(@as(usize, 120), @sizeOf(api.R4XStartContext2));
    try std.testing.expect(!@hasField(api.R4XStartContext2, "reserved_runtime"));
    try std.testing.expect(!@hasField(api.R4LQuery2, "kernel_bridge"));
    inline for (.{ "R4XStartR4Sys2", "R4XStartR4Desk2", "R4XStartR4Draw2", "R4XStartR4Net2", "R4XStartR4Audio2", "R4XStartR4Dev2" }) |name| {
        const T = @field(api, name);
        const C = @field(c, name);
        try std.testing.expectEqual(@sizeOf(T), @sizeOf(C));
        try std.testing.expectEqual(@alignOf(T), @alignOf(C));
        inline for (std.meta.fields(T)) |f| try std.testing.expectEqual(@offsetOf(T, f.name), @offsetOf(C, f.name));
        try std.testing.expectEqual(@as(u32, 1), (T{}).abi_version);
    }
    try std.testing.expect(!@hasField(api.R4XStartR4Sys2, "reserved_shell_run"));
    try std.testing.expect(!@hasField(api.R4XStartR4Dev2, "reserved_program_registry_summary_v1"));
    try std.testing.expect((api.R4XStartR4Sys2{}).magic != (api.shared.R4XStartR4Sys{}).magic);
}

test "generation2 typed calls preserve the canonical C function signature and declared prefix" {
    const Provider = struct {
        fn write(bytes: [*]const u8, length: u32) callconv(.c) i32 {
            return if (length == 4 and std.mem.eql(u8, bytes[0..length], "API2")) -20002 else -1;
        }
    };
    var table: api.R4XStartR4Sys2 = .{ .write = @intFromPtr(&Provider.write) };
    const view: ?*const api.R4XStartR4Sys2 = &table;
    const call = api.function(api.R4SysFns2, view, "write") orelse return error.MissingFunction;
    try std.testing.expectEqual(@as(i32, -20002), call("API2", 4));
    table.size = 16;
    try std.testing.expect(api.function(api.R4SysFns2, view, "write") == null);
    table.size = @sizeOf(api.R4XStartR4Sys2);
    table.write = 0;
    try std.testing.expect(api.function(api.R4SysFns2, view, "write") == null);
}
