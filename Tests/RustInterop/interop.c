#include <r4os/abi_generated.h>
#include <emmintrin.h>

// A SIMD-capable module consumer calls the integer/pointer Platform ABI.
// Live vector and floating-point data are retained across the Rust call.
int32_t r4os_c_rust_call(R4SysWriteFn callback, const uint8_t *data, uint32_t size) {
    const __m128i original = _mm_set_epi32(0x12345678, 0x23456789, 0x3456789a, 0x456789ab);
    volatile double multiplier = 1.25;
    const double floating = multiplier * 4.0;
    __m128i saved = original;
    // The barrier prevents the vector from being regenerated as constants.
    __asm__ volatile("" : "+x"(saved) : : "memory");
    const int32_t result = callback(data, size);
    __asm__ volatile("" : "+x"(saved) : : "memory");
    if (_mm_movemask_epi8(_mm_cmpeq_epi8(original, saved)) != 0xffff) return -1;
    if (floating != 5.0) return -2;
    return result;
}
