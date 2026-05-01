// Test: signed integer overflow — x + 1 > x is always true at -O2
// because the compiler assumes signed overflow never happens (UB),
// so it eliminates the branch entirely.
#include <stdio.h>
#include <limits.h>

int check_overflow(int x) {
    // At -O0: evaluates the comparison at runtime
    // At -O2: optimizer knows signed overflow is UB, so x+1 > x is ALWAYS
    //         true → the else branch is dead-code eliminated
    if (x + 1 > x) {
        return 1;   // "no overflow"
    } else {
        return 0;   // "overflow happened" — DEAD at -O2
    }
}

int main(void) {
    printf("INT_MAX check: %d\n", check_overflow(INT_MAX));
    printf("Normal check:  %d\n", check_overflow(42));
    return 0;
}
