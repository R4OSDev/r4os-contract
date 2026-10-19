# R4OS Platform Contract

This repository is the canonical API and ABI definition for the R4OS platform.
It contains the R4M0 container contract, shared layouts and error codes,
platform API groups, generated bindings, conformance fixtures, and the
contract generator.

R4DEV v17 appends `smp_kernel_check` and `performance_smp_tlb` after the
preserved 416-byte prefix (total432). Fixed v1 payloads separately expose
explicit owned functional SMP work (224bytes) and passive remote-TLB/clock
facts (184bytes). Exact own task/ACK/backing receipts determine success;
global timeout injection remains isolated. Existing slots, layouts and
constants are preserved.

Optional Runtime-R4L APIs are intentionally not defined here; each independent
library owns its own contract and bindings.

R4DEV v29 appends the passive 192-byte `CpuIdleInfo` receipt. Separate
`CpuIdleDescriptor` and `CpuIdlePolicy` records extend the optional driver CPU
mechanism to184 bytes. ACPI declarations and software entry attempts are
distinct from unavailable physical residency, wake-latency and energy data.
Every previous fixed record, table prefix and callback meaning is preserved.

## Build and validation

Use the repository starter with the workspace toolchain:

    ./Build.sh test      # Linux
    Build.bat test       # Windows

Both delegate to Build.ps1; it falls back to Zig on PATH outside the workspace.

Generated files are checked during normal builds. Intentional contract changes
must use the repository's explicit generator write workflow and update the
matching baseline.

`Generated/SDK/Rust/` is the standalone `no_std` Rust projection of the same
canonical platform and technical ABI. `write` generates Zig/C first, then
reflects their current typed definitions into Rust. Normal builds and `check`
compare Rust output without writing it; `test` also compiles both Rust targets
and runs the existing Contract gate with a native Rust/Zig/C callback fixture.
Use the pinned workspace Rust launcher; standalone tests require Rust 1.99.0.
See `Generated/Inventory/RustABI.json` and the workspace guide
`Docs/API/RustContractBindings.txt`. Adding this binding leaves API versions,
the canonical schema/baseline and existing Zig/C consumers unchanged.

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
change waits. Consumer fence acknowledgements add two constants without
changing payload layouts. R4DESK v15 appends the optional
`desktop_activity_notify` slot; all old function slots are unchanged.
Opaque color bytes carry the existing R4GFX
description; they do not add kernel color or window-presentation policy.
The service implementation is available; Desktop and Vulkan WSI consumers
are still being integrated.

R4DEV v18 appends `storage_block_queue_check` at offset432 after the unchanged
432-byte prefix. `ProgramKernelBlockQueueCheck` v1 is fixed240bytes. It reports
only its own synthetic cases, exact request/task/device receipts and retained
resources; no global queue reset, physical test disk or separate score.

R4DEV v19 appends `storage_nvme_check` at offset440 after the unchanged
440-byte prefix; its fixed v1 report is296bytes. The optional technical
`StorageObservedRequest` is80bytes and retains the complete56-byte
`StorageRequest` prefix. Only the observation flag and an advertised backend
capability select it. Its synchronous104-byte callback record identifies the
actual CQE, IRQ-driven worker and acknowledged DMA release before logical
completion. Normal56-byte requests and their callbacks remain unchanged.

R4DEV v20 appends `usb_contract_check` at offset448 after the unchanged
448-byte layout prefix. Its fixed32-byte v1 report covers the existing local
ring-cycle and event-router cases. It is bounded and reentrant, borrows only
caller output and touches no live USB controller, mailbox or hardware.

SerialLink retirement (0.84.34 / package0.64.20)
--------------------------------------------
R4NET slots27-31 and all published names/signatures/payload layouts remain
frozen. These five compatibility stubs always return err_no_fn and touch no
buffer, UART, loader or work queue. SerialLink runtime/modules/SDK facades are
removed. A table pointer does not imply that the retired transport is available.
Only the five descriptions changed in the controlled documentation baseline;
all other schema values and generated Zig/C/Rust bindings are byte-identical.

Machine Check receipts (0.64.34 / 0.85.32)
----------------------------------------
R4DEV30 appends passive `cpu_machine_info` and `cpu_machine_bank` after its
unchanged656-byte prefix (complete table672bytes). Independent fixed144-byte
`CpuMachineInfo` and112-byte `CpuMachineBank` distinguish retained boot-passive
scans from terminal #MC captures. Bank copies require exact CPU/original epoch/
capture sequence; refusal/end leaves output and tails unchanged. Actual bank
count, read faults, truncation, status validity and changed readbacks remain
explicit. No query runs CPU instructions, callbacks, recovery or status clears.
Existing CrashReport, DriverApi37, DriverCpuPowerApi184 and R4SYS27 stay fixed.
CPUPOWER's appended model-support flags describe documented decode profiles,
without claiming actual bank presence, enabled reporting or current health.
