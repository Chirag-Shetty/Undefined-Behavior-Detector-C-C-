// clean_add.c — pure unsigned arithmetic, no UB anywhere
// Expected: tool reports CLEAN (exit 0)
#include <stdio.h>

/* Unsigned arithmetic wraps mod 2^32 — defined behaviour in C */
unsigned int add_u32(unsigned int a, unsigned int b) {
    return a + b;
}

unsigned int mul_u32(unsigned int a, unsigned int b) {
    return a * b;
}

int main(void) {
    printf("%u\n", add_u32(10, 20));
    printf("%u\n", mul_u32(7, 6));
    return 0;
}
