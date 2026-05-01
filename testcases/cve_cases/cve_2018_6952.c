/*
 * CVE-2018-6952 — GNU patch through 2.7.6 (pch.c: another_hunk)
 * Modelled UB pattern: pointer/integer arithmetic overflow eliminating
 * a heap-buffer bounds check
 *
 * The real CVE was a double-free in another_hunk(), triggered when a
 * malformed patch file caused the hunk-size counter to underflow.  The
 * underlying root cause was using signed arithmetic for buffer sizes: when
 * the line-count variables wrap, the bounds check `p + n < limit` is
 * evaluated using signed semantics and the compiler eliminates it.
 *
 * UB type  : Signed integer overflow (C11 §6.5 ¶5)
 * -O0 effect: `remaining + extra` may wrap; if-branch can be taken
 * -O2 effect: `remaining + extra < remaining` is always false (nsw axiom);
 *             the buffer-overflow guard is dead-code-eliminated, allowing
 *             reads/writes past the end of the allocated hunk buffer.
 *
 * Real fix : Use size_t for all buffer sizes; validate before addition.
 */

#include <stdio.h>
#include <limits.h>
#include <string.h>

#define PATCH_MAX_HUNK  4096
#define HUNK_ERROR      (-1)
#define HUNK_OK         0

/*
 * Simplified model of another_hunk()'s size accounting.
 * `remaining`  — bytes left in current hunk buffer (signed int in orig code)
 * `extra_lines`— number of extra context lines to append
 */
int another_hunk_simplified(int remaining, int extra_lines)
{
    int bytes_per_line = 80;   /* assumed max line length */

    /*
     * BUG: both operands are signed int.  When extra_lines is large,
     * remaining + extra_lines * bytes_per_line overflows.
     *
     * At -O0: the wrapped (negative) result makes the comparison true
     *         and we correctly reject the input as too large.
     *
     * At -O2: the compiler knows signed overflow is UB, so it deduces
     *         `remaining + extra < remaining` is never true and removes
     *         the guard.  An attacker can cause a heap overwrite by
     *         supplying a crafted patch with large extra_lines.
     */
    int extra = extra_lines * bytes_per_line;          /* may overflow */
    if (remaining + extra < remaining) {               /* UB — eliminated at -O2 */
        return HUNK_ERROR;   /* "hunk too large" — dead at -O2 */
    }

    if (remaining + extra > PATCH_MAX_HUNK) {
        return HUNK_ERROR;
    }

    return HUNK_OK;
}

int main(void)
{
    printf("small hunk  : %d\n", another_hunk_simplified(100,  10));
    printf("large hunk  : %d\n", another_hunk_simplified(100,  200));
    /* At -O0: overflow guard fires → HUNK_ERROR (-1)
     * At -O2: overflow guard eliminated → HUNK_OK (0)  ← security bug */
    printf("huge lines  : %d\n", another_hunk_simplified(1000, INT_MAX / 80));
    return 0;
}
