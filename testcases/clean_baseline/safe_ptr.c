// safe_ptr.c — memcpy-based type punning (correct approach, no aliasing UB)
// Expected: tool reports CLEAN (exit 0)
#include <stdio.h>
#include <string.h>

/* memcpy is the ISO-approved way to reinterpret bits without aliasing UB */
float u32_to_float(unsigned int bits) {
    float result;
    memcpy(&result, &bits, sizeof result);
    return result;
}

int main(void) {
    printf("%.6f\n", u32_to_float(0x3f800000u));  /* should be 1.0 */
    return 0;
}
