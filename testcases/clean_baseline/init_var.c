// init_var.c — every variable initialized at declaration, no UB
// Expected: tool reports CLEAN (exit 0)
#include <stdio.h>

/* All arithmetic is unsigned or uses explicit casts — no signed overflow UB */
unsigned int factorial(unsigned int n) {
    unsigned int result = 1u;
    for (unsigned int i = 2u; i <= n; i++) {
        result *= i;
    }
    return result;
}

int main(void) {
    printf("%u\n", factorial(5));   /* 120 */
    printf("%u\n", factorial(0));   /* 1 */
    return 0;
}
