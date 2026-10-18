//! One module CPU contract for Zig/C builders and the kernel boot gate.
//! Compiler-implied ISA features are accounted for; tuning preferences do
//! not introduce additional architectural requirements.
const std = @import("std");

pub const Requirement = struct {
    name: []const u8,
    leaf: u32,
    subleaf: u32,
    register: enum { eax, ebx, ecx, edx },
    bit: u5,
    zig_features: []const []const u8,
    c_flag: ?[]const u8 = null,
};
pub const Profile = struct {
    format: u32,
    name: []const u8,
    cpu_model: []const u8,
    xcr0_mask: u64,
    tuning_features: []const []const u8,
    requirements: []const Requirement,
};

pub fn load(allocator: std.mem.Allocator) Profile {
    const parsed = std.json.parseFromSlice(Profile, allocator, @embedFile("CpuBaseline.json"), .{}) catch
        @panic("Invalid canonical Module/CpuBaseline.json");
    const profile = parsed.value;
    if (profile.format != 1 or !std.mem.eql(u8, profile.cpu_model, "x86_64") or
        profile.xcr0_mask != 7 or profile.requirements.len == 0 or profile.requirements.len > 32)
        @panic("Review the module CPU contract before changing its architecture or XSTATE layout");
    for (profile.requirements, 0..) |requirement, i| {
        if (requirement.name.len == 0) @panic("Missing module CPU requirement name");
        for (profile.requirements[0..i]) |previous| {
            if (std.mem.eql(u8, previous.name, requirement.name) or
                (previous.leaf == requirement.leaf and previous.subleaf == requirement.subleaf and
                    previous.register == requirement.register and previous.bit == requirement.bit))
                @panic("Duplicate module CPU requirement");
        }
    }
    return profile;
}

fn feature(name: []const u8) std.Target.x86.Feature {
    return std.meta.stringToEnum(std.Target.x86.Feature, name) orelse
        @panic("Unknown module CPU compiler feature");
}

pub fn target(b: *std.Build) std.Build.ResolvedTarget {
    const profile = load(b.allocator);
    var isa = std.Target.Cpu.Feature.Set.empty;
    for (profile.requirements) |requirement| {
        for (requirement.zig_features) |name| isa.addFeature(@intFromEnum(feature(name)));
    }
    const resolved = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .cpu_model = .{ .explicit = &std.Target.x86.cpu.x86_64 },
        .os_tag = .freestanding,
        .abi = .none,
        .ofmt = .elf,
        .cpu_features_add = isa,
    });
    var accounted = isa;
    for (profile.tuning_features) |name| accounted.addFeature(@intFromEnum(feature(name)));
    // Reject new implicit instructions after a toolchain change. Includes
    // CRC32 implied by SSE4.2 and the generic x86_64 baseline instructions.
    if (!std.meta.eql(accounted, resolved.result.cpu.features))
        @panic("Module CPU compiler dependencies differ from the canonical boot contract");
    return resolved;
}

pub fn cFlags(allocator: std.mem.Allocator) []const []const u8 {
    const profile = load(allocator);
    var flags: std.array_list.Managed([]const u8) = .init(allocator);
    for (profile.requirements) |requirement| {
        if (requirement.c_flag) |flag| flags.append(flag) catch @panic("OOM");
    }
    return flags.toOwnedSlice() catch @panic("OOM");
}
