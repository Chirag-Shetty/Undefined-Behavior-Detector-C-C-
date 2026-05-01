// Test: null pointer dereference in dead code
// At -O0 the null-deref block exists; at -O2 the entire dead block
// (and the unreachable path) is eliminated.
#include <stdio.h>

int use_ptr(int *ptr) {
    if (ptr) {
        return *ptr;
    } else {
        // UB: dereferencing null — optimizer eliminates this path
        int *null_ptr = 0;
        return *null_ptr;   // dead at -O2: UB means this path is impossible
    }
}

int main(void) {
    int x = 42;
    printf("%d\n", use_ptr(&x));
    return 0;
}
