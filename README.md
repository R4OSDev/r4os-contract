# R4OS Platform Contract

This repository is the canonical API and ABI definition for the R4OS platform.
It contains the R4M0 container contract, shared layouts and error codes,
platform API groups, generated bindings, conformance fixtures, and the
contract generator.

Optional Runtime-R4L APIs are intentionally not defined here; each independent
library owns its own contract and bindings.

## Build and validation

Use the repository starter with the workspace toolchain:

    ./Build.sh test      # Linux
    Build.bat test       # Windows

Both delegate to Build.ps1; it falls back to Zig on PATH outside the workspace.

Generated files are checked during normal builds. Intentional contract changes
must use the repository's explicit generator write workflow and update the
matching baseline.

The technical `DriverApi` facade lives outside the marked generated exports
block in `Generated/SDK/Zig/abi.zig`; the generator preserves that area.
DriverApi34 appends two optional DMA range-sync callbacks after the unchanged
632-byte v33 prefix (total 648). `ABI/R4DDriver.txt` defines their ownership,
bounds and ordering; SDK conformance and the kernel enforce the layout.

Detailed German migration notes are preserved in
`DOCUMENTATION.de.txt`.

DriverApi v24 and NetBackend v2 provide append-only network capability
selection. Every packet descriptor retains canonical flat fallback bytes;
the current single-queue implementation admits only validated RX TCP/UDP
checksums and rejects all other optional offloads explicitly.

## License

Original R4OS material is licensed under Apache License 2.0. See `LICENSE`,
`NOTICE`, and `THIRD_PARTY_NOTICES.md`.

Kernel provider builders follow the canonical `required` flag: required
callbacks must be supplied, while optional callbacks default to null and
produce a zero capability slot. The table layout and Query import stay
unchanged when a provider omits a capability.

GPU telemetry identifies one exact adapter and memory generation. A surviving
driver advances its memory generation monotonically after a GPU reset. The
common cache accepts that newer epoch, discards the old demand and rejects
older publications or queries. Fault handling publishes unavailable metrics
without reading the device; cached measurements are not reset evidence.

The optional `GfxDriverMemoryApi.device_lost` slot at byte200 extends the table
to208 bytes; its wire version remains1 and every old slot keeps its offset.
The exact driver invalidates native BOs for one adapter and memory epoch.
Logical loss rejects new uses but retains DMA. An independently proven stop
then allows physical backing release once all device/queue leases end, even
while applications retain invalid handles that they can still close. CPU BOs
and newer generations are unaffected. This metadata call neither resets the
GPU nor confirms restoration of the boot framebuffer. The baseline change
also updates the default caller capacity and documents this release rule;
it does not change the layout of release tickets or the outer DriverApi.

The optional display reset pair extends `GfxDriverDisplayApi` from120 to136
bytes without changing wire version1 or the prefix. `device_reset` at120
invalidates one exact display/backend generation; a separate proven-stop
call retires its queue, mode, cursor and additional-output consumers. The
original boot hold remains sealed. `prepare_reset` at128 admits a strictly
newer queue generation and creates a fresh native display generation; it
does not reuse the immutable boot-hold ID or grant access to bootfb. Both
callbacks are required for this capability. Only the existing physical
restore callback can authorize restoration of the held boot framebuffer.

The 0.79.37 `WindowGraphics*` payloads add four userland WINSVC operations
for common GPU-window publication, producer/consumer leases and finite
change waits. Existing table versions, function slots, payloads and numeric
constants remain unchanged. Opaque color bytes carry the existing R4GFX
description; they do not add kernel color or window-presentation policy.
The service implementation is available; Desktop and Vulkan WSI consumers
are still being integrated.
