/*
 * CVE-2017-11164 — PCRE 8.41 (pcre_exec.c)
 * Modelled UB pattern: signed integer overflow in match offset arithmetic
 *
 * The real CVE involved uncontrolled recursion in match(), but the root
 * cause in many PCRE security reports of this era was using signed `int`
 * for string offsets: when an attacker supplies a very large subject string
 * or pattern, the offset arithmetic overflows.  The compiler at -O2 exploits
 * the "signed overflow never happens" axiom to eliminate the bounds check
 * entirely, turning a recoverable error path into an out-of-bounds read.
 *
 * UB type  : Signed integer overflow (C11 §6.5 ¶5)
 * -O0 effect: the if-branch is evaluated at runtime; INT_MAX input returns -1
 * -O2 effect: `offset + 1024` overflows for INT_MAX; the comparison
 *             `offset + 1024 < offset` is ALWAYS false (nsw assumption),
 *             so the error return is dead-code-eliminated — bounds check gone.
 *
 * Real fix : use size_t / ptrdiff_t for all offsets, or __builtin_add_overflow
 */

#include <stdio.h>
#include <limits.h>
#include <string.h>

#define PCRE_ERROR_BADOFFSET   (-24)
#define PCRE_ERROR_NOMATCH     (-1)
#define PCRE_INTERNAL_BUFSIZE  1024

/*
 * Simplified pcre_exec() entry-point showing the vulnerable offset check.
 * In the real PCRE source this is spread across match() helper calls.
 */
int pcre_exec_simplified(const char *subject, int length, int startoffset)
{
    /*
     * BUG: startoffset is a signed int.  When startoffset is near INT_MAX,
     * startoffset + PCRE_INTERNAL_BUFSIZE overflows.
     *
     * At -O0: the runtime addition wraps to a negative number, so the
     *         comparison `startoffset + PCRE_INTERNAL_BUFSIZE < startoffset`
     *         can be TRUE and we correctly return the error code.
     *
     * At -O2: the compiler sees `x + 1024 < x` on a signed int and, because
     *         signed overflow is UB, concludes this is ALWAYS false.  The
     *         entire if-block is eliminated — the security check disappears.
     */
    if (startoffset + PCRE_INTERNAL_BUFSIZE < startoffset) {   /* UB here */
        return PCRE_ERROR_BADOFFSET;          /* dead at -O2 */
    }

    if (startoffset < 0 || startoffset > length) {
        return PCRE_ERROR_BADOFFSET;
    }

    /* ... simplified matching logic ... */
    return (startoffset < length) ? 0 : PCRE_ERROR_NOMATCH;
}

int main(void)
{
    char subject[] = "hello world";
    int  len       = (int)strlen(subject);

    printf("normal offset 3 : %d\n", pcre_exec_simplified(subject, len, 3));
    printf("bad offset -1   : %d\n", pcre_exec_simplified(subject, len, -1));
    /* At -O0: returns PCRE_ERROR_BADOFFSET (-24)
     * At -O2: the overflow check is gone; behaviour is implementation-defined */
    printf("overflow offset : %d\n", pcre_exec_simplified(subject, len, INT_MAX));
    return 0;
}
