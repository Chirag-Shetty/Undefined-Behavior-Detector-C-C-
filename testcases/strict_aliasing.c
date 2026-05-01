// Test: strict aliasing violation via type punning
// Reading an int through a float* is UB; the optimizer may reorder
// or eliminate the load because it assumes no aliasing.
#include <stdio.h>

float int_to_float_bits(int x) {
    // UB: violates strict aliasing rule
    return *(float *)&x;
}

int main(void) {
    printf("%f\n", int_to_float_bits(0x3f800000));  // should be 1.0
    return 0;
}
