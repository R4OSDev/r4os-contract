#![no_std]

use r4os_contract as abi;

#[panic_handler]
fn panic(_: &core::panic::PanicInfo<'_>) -> ! {
    // A rejected test contract traps immediately, including on a host caller.
    unsafe { core::arch::asm!("ud2", options(noreturn, nostack)) }
}

unsafe extern "C" fn write(data: *const u8, len: u32) -> i32 {
    assert_eq!(len, 9);
    assert!(!data.is_null());
    // SAFETY: the fixture supplies the live nine-byte source for this call.
    let data = unsafe { core::slice::from_raw_parts(data, len as usize) };
    assert_eq!(data, b"R4OS-Rust");
    -12345
}

#[unsafe(no_mangle)]
pub extern "C" fn r4os_rust_write() -> abi::R4SysFns::write {
    write
}

#[unsafe(no_mangle)]
/// # Safety
/// `callback` must accept the live fixture bytes for the duration of the call.
pub unsafe extern "C" fn r4os_rust_call_write(callback: abi::R4SysFns::write) -> i32 {
    // SAFETY: bytes are immutable static storage; callback was supplied by the fixture.
    unsafe { callback(b"R4OS-Rust".as_ptr(), 9) }
}

unsafe extern "C" fn service_call(
    id: u32,
    opcode: u16,
    request: *const u8,
    request_len: u32,
    header: *mut abi::ServiceMessageHeader,
    reply: *mut u8,
    capacity: u32,
    deadline: u64,
) -> i32 {
    assert_eq!(id, 0xfedc_ba98);
    assert_eq!(opcode, 0xabc7);
    assert_eq!(request_len, 9);
    assert_eq!(capacity, 3);
    assert_eq!(deadline, 0xfedc_ba98_7654_3210);
    // SAFETY: each pointer refers to the exact caller-owned fixture allocation.
    unsafe {
        assert_eq!(write(request, request_len), -12345);
        (*header).op = opcode;
        (*header).request_id = id;
        (*header).status = -32767;
        (*header).payload_len = 3;
        core::ptr::copy_nonoverlapping(b"ACK".as_ptr(), reply, 3);
    }
    -32767
}

#[unsafe(no_mangle)]
pub extern "C" fn r4os_rust_service_call() -> abi::R4SysFns::service_call {
    service_call
}

#[unsafe(no_mangle)]
/// # Safety
/// The fixture keeps `request` and `ticket` alive and exclusively owns the output.
pub unsafe extern "C" fn r4os_rust_driver_work(
    request: *const abi::DriverWorkRequest,
    ticket: *mut u32,
) -> i32 {
    // SAFETY: caller supplies an initialized canonical request, including its callback.
    let request = unsafe { &*request };
    assert_eq!(request.version, abi::driver_work_request_version);
    assert_eq!(
        request.size as usize,
        core::mem::size_of::<abi::DriverWorkRequest>()
    );
    assert_eq!(request.serial_key, 0x8123_4567_89ab_cdef);
    assert_eq!(request.deadline_tick, 0xfedc_ba98_7654_3210);
    assert_eq!(request.budget_ticks, 4);
    // SAFETY: callback and context belong to the live request; output is caller-owned.
    unsafe {
        *ticket = 0xfedc_ba98;
        (request.handler)(request.context)
    }
}

#[unsafe(no_mangle)]
/// # Safety
/// A supplied callback must accept the live context for this synchronous call.
pub unsafe extern "C" fn r4os_rust_optional_callback(
    callback: Option<abi::DriverWorkHandler>,
    context: usize,
) -> i32 {
    match callback {
        None => abi::err_no_fn,
        // SAFETY: the test supplies a C callback accepting this fixture context.
        Some(callback) => unsafe { callback(context) },
    }
}

#[unsafe(no_mangle)]
/// # Safety
/// Both descriptors and the source data must remain live for this synchronous call.
pub unsafe extern "C" fn r4os_rust_protocol_buffer(
    source: *const abi::ProtocolBuffer,
    output: *mut abi::ProtocolBuffer,
) -> i32 {
    // SAFETY: caller owns two separate canonical descriptors; no data is dereferenced.
    unsafe {
        assert_eq!((*source).len, 9);
        assert_eq!((*source).capacity, 16);
        assert_eq!((*source).flags, 0x8000_0001);
        *output = *source;
    }
    17
}

#[unsafe(no_mangle)]
pub extern "C" fn r4os_rust_enum(value: abi::DriverType) -> abi::DriverType {
    assert_eq!(value, abi::DriverType::net);
    abi::DriverType::display
}

#[unsafe(no_mangle)]
/// # Safety
/// `output` must refer to a writable, aligned canonical message header.
pub unsafe extern "C" fn r4os_rust_default_header(output: *mut abi::ServiceMessageHeader) {
    // SAFETY: caller exclusively owns the output fixture.
    unsafe { output.write(abi::ServiceMessageHeader::default()) };
}

// Only ABI transport peers: no CPU/register operation or hardware counter.
unsafe extern "C" fn pmu_measure(
    cpu: u32,
    epoch: u64,
    event: u32,
    iterations: u32,
    work: *const abi::PmuWorkFn,
    context: u64,
    output: *mut abi::CpuPmuResult,
) -> i32 {
    assert_eq!(cpu, 0xfedc_ba98);
    assert_eq!(epoch, 0xfedc_ba98_7654_3210);
    assert_eq!(event, abi::cpu_pmu_event_branch_misses);
    assert_eq!(iterations, abi::cpu_pmu_max_iterations);
    if work.is_null() || !work.is_aligned() || output.is_null() || !output.is_aligned() {
        return abi::cpu_capabilities_error_invalid;
    }
    // SAFETY: the fixture retains the borrowed function slot and exclusive
    // output. Check zero bits before materializing a nonnull Rust function.
    let result = unsafe {
        if work.cast::<u64>().read() == 0
            || (*output).version != 1
            || (*output).size < core::mem::size_of::<abi::CpuPmuResult>() as u32
        {
            return abi::cpu_capabilities_error_invalid;
        }
        work.read()(context, iterations)
    };
    // SAFETY: only the fixed256-byte result is copied; caller tail remains.
    unsafe {
        output.write(abi::CpuPmuResult {
            cpu_index: cpu,
            epoch,
            generation: 0x8123_4567_89ab_cdef,
            event_id: event,
            iterations,
            callback_result: result,
            status: abi::cpu_pmu_status_callback_aborted,
            // No physical data is invented by an ABI-only fixture.
            flags: abi::cpu_pmu_result_flag_callback_started
                | abi::cpu_pmu_result_flag_callback_returned,
            ..Default::default()
        });
    }
    0
}

#[unsafe(no_mangle)]
pub extern "C" fn r4os_rust_pmu_measure() -> abi::R4DevFns::cpu_pmu_measure {
    pmu_measure
}
