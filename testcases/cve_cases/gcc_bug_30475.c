/*
 * GCC Bug 30475 — Signed/pointer overflow check silently removed
 * https://gcc.gnu.org/bugzilla/show_bug.cgi?id=30475
 *
 * This is one of the most cited examples of a compiler legitimately
 * (per the standard) removing a programmer's security check.
 *
 * The pattern:  if (base + offset < base)  // overflow check
 * The problem:  signed integer overflow is UB; the compiler KNOWS the
 *               comparison is always false (nsw axiom) and removes it.
 *
 * Historically this caused real security holes in:
 *   - The Linux kernel (pointer-wrap null-deref bypass)
 *   - zlib / libpng (buffer-size checks)
 *   - Various network protocol parsers
 *
 * UB type  : Signed integer overflow (C11 s6.5 p5)
 * -O0 effect: addition wraps for large offsets; branch taken => NULL returned
 * -O2 effect: `base + offset < base` is always false => security check gone,
 *             function always returns `base + offset` even when overflowed.
 */

#include <stdio.h>
#include <limits.h>
#include <stdint.h>

/*
 * Intended: safe buffer pointer advance.
 * Returns NULL if advancing by `offset` bytes would wrap the pointer.
 * At -O2 the wrap check is eliminated -- callers can get a bad pointer.
 */
char *safe_advance_gcc30475(char *base, int offset)
{
    /*
     * Classic vulnerable pattern from GCC bug 30475.
     * `base + offset` has undefined behaviour if it overflows a signed
     * ptrdiff_t — on most architectures char* arithmetic uses signed math.
     *
     * At -O0: wraps at runtime for INT_MAX; returns NULL (correct)
     * At -O2: `base + offset < base` is provably false (nsw) → branch
     *         eliminated → always returns the (possibly wrapped) pointer
     */
    if (base + offset < base) {       /* UB: signed ptr-diff overflow */
        return (char *)0;             /* dead at -O2 */
    }
    return base + offset;
}

/*
 * Second pattern: pure integer version (same bug, cleaner isolation).
 * Security-critical code often does the bounds check on integers first.
 */
int compute_end_gcc30475(int start, int length)
{
    if (start + length < start) {     /* UB: signed overflow */
        return -1;                    /* "overflow error" — dead at -O2 */
    }
    return start + length;
}

int main(void)
{
    char buf[64] = "hello";

    /* Pointer version */
    char *p1 = safe_advance_gcc30475(buf, 4);
    char *p2 = safe_advance_gcc30475(buf, INT_MAX);   /* should be NULL */
    printf("advance  4   : %s\n",  p1 ? p1 : "(null)");
    printf("advance MAX  : %s\n",  p2 ? "(non-null!)" : "(null)");

    /* Integer version */
    printf("end  10+5    : %d\n",  compute_end_gcc30475(10, 5));
    printf("end MAX+1    : %d\n",  compute_end_gcc30475(INT_MAX, 1));
    /* At -O0: -1  (overflow detected)
     * At -O2: -2147483648 or similar (overflow check gone) */
    return 0;
}
