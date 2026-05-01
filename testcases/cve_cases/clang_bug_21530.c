/*
 * Clang Bug 21530 — Strict aliasing violation in type-punning conversions
 * https://bugs.llvm.org/show_bug.cgi?id=21530
 *
 * Clang's alias analysis assumed that a load through a float* and a store
 * through an int* to the same address cannot alias (strict aliasing rule,
 * C11 §6.5 ¶7).  This caused it to reorder the load ahead of the store,
 * so the load read the old value rather than the newly written one.
 *
 * The pattern is extremely common in embedded / networking code for
 * serialisation, endian conversion, and bit-level float manipulation.
 *
 * UB type  : Strict aliasing violation (C11 §6.5 ¶7)
 * -O0 effect: store then load through the same address — reads new value
 * -O2 effect: alias analysis assumes int* and float* cannot point to the
 *             same object; load is moved before store (or CSE'd to old
 *             value) — reads stale/wrong value
 *
 * Real-world impact: wrong floating-point results in crypto, codecs,
 * physics engines using bit-manipulation tricks (e.g. fast inverse sqrt).
 */

#include <stdio.h>
#include <stdint.h>
#include <string.h>

/*
 * Pattern 1: direct type-pun via cast (classic strict aliasing violation).
 * Reading an int's bit pattern as a float — UB in C without memcpy.
 */
float bits_to_float_clang21530(uint32_t bits)
{
    /*
     * UB: the compiler is allowed to assume a float* and uint32_t* never
     * alias.  At -O2 it may fold or reorder the load, returning a
     * stale/wrong value or eliminating the load entirely.
     *
     * Correct approach: memcpy(&f, &bits, sizeof f);
     */
    return *((float *)&bits);   /* strict aliasing violation */
}

/*
 * Pattern 2: write through one type, read through another (in-memory).
 * This is closer to the original Clang bug report scenario.
 */
float reinterpret_via_memory_clang21530(uint32_t x)
{
    uint32_t storage = x;

    /*
     * At -O0: the store to `storage` happens, then the float* load
     *         reads the just-written bits — gives the reinterpreted float.
     * At -O2: Clang's alias analysis sees a uint32_t store followed by a
     *         float load to what appears (after inlining) to be the same
     *         address.  Because uint32_t* and float* cannot alias per the
     *         standard, the load may be hoisted above the store or replaced
     *         with an earlier cached value — wrong result.
     */
    float result = *((float *)&storage);   /* UB: aliasing violation */
    return result;
}

/*
 * Pattern 3: the "fast inverse square root" trick from Quake III Arena.
 * Famous for relying on strict aliasing UB.  Without -fno-strict-aliasing
 * or memcpy, the result can differ between optimisation levels.
 */
float fast_inv_sqrt_clang21530(float number)
{
    long i;
    float x2, y;
    const float threehalfs = 1.5F;

    x2 = number * 0.5F;
    y  = number;

    /* Evil UB bit hack — reads float as long, does int arithmetic,
     * writes back as float.  The two casts violate strict aliasing. */
    i  = *(long *)&y;              /* UB */
    i  = 0x5f3759df - (i >> 1);
    y  = *(float *)&i;             /* UB */

    /* Newton–Raphson refinement */
    y  = y * (threehalfs - (x2 * y * y));
    return y;
}

int main(void)
{
    uint32_t ieee_one = 0x3f800000u;   /* IEEE 754 representation of 1.0f */

    printf("bits_to_float(0x3f800000) = %f  (expected 1.0)\n",
           bits_to_float_clang21530(ieee_one));

    printf("reinterpret(0x3f800000)   = %f  (expected 1.0)\n",
           reinterpret_via_memory_clang21530(ieee_one));

    printf("fast_inv_sqrt(4.0)        = %f  (expected ~0.5)\n",
           fast_inv_sqrt_clang21530(4.0f));

    return 0;
}
