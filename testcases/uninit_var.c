// Test: use of uninitialized variable
// At -O0 the load returns whatever is on the stack.
// At -O2 the optimizer may assume the value is 0 (or fold the comparison).
#include <stdio.h>

int is_zero(void) {
    int x;        // uninitialized — UB to read
    return x == 0; // at -O2, optimizer may constant-fold this
}

int main(void) {
    printf("%d\n", is_zero());
    return 0;
}
