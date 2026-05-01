/*
 * GCC Bug 58640 — Uninitialized variable in complex control flow
 * https://gcc.gnu.org/bugzilla/show_bug.cgi?id=58640
 *
 * GCC 4.8/4.9 incorrectly constant-folded uses of variables that were
 * initialized only on some paths through a function.  The optimizer
 * treated the uninitialized read as UB and assumed the value it needed
 * for the best optimization, producing wrong results.
 *
 * The original bug was a miscompilation where a struct field was used
 * before being set on one branch; the compiler folded a conditional
 * to a constant and eliminated the error-handling path.
 *
 * UB type  : Use of uninitialized variable (C11 §J.2)
 * -O0 effect: reads whatever is on the stack; result is indeterminate
 * -O2 effect: optimizer assumes the unread variable equals 0 (or whatever
 *             value lets it fold the comparison) → comparison eliminated,
 *             error path dead-code-eliminated, always returns "success"
 */

#include <stdio.h>

typedef struct {
    int  code;
    int  value;
} Result;

/*
 * Simplified model: `r.code` is only set when `mode > 0`.
 * If mode <= 0, reading r.code is UB.
 * At -O2 the optimizer may fold `r.code == 0` to a constant.
 */
int process_gcc58640(int mode, int input)
{
    Result r;   /* NOT initialized here — intentional model of bug 58640 */

    if (mode > 0) {
        r.code  = (input > 100) ? 1 : 0;
        r.value = input;   /* simple assignment — no nsw arithmetic */
    }
    /* Else: r.code and r.value are UNINITIALIZED — UB if read below */

    /*
     * At -O0: r.code may be 0 (from zero-init stack frame) or garbage.
     *         The comparison evaluates at runtime.
     * At -O2: compiler knows reading uninitialized r.code is UB, so it
     *         may assume r.code == 0 and constant-fold the comparison,
     *         eliminating the error branch entirely.
     */
    if (r.code != 0) {           /* UB when mode <= 0 */
        return -1;               /* "error" path — dead at -O2 for mode<=0 */
    }

    return 0;   /* "success" */
}

/*
 * Second pattern: single uninitialized variable, simpler isolation.
 * Matches the classic compiler-explorer demonstration of bug 58640.
 */
int uninit_branch_gcc58640(int flag)
{
    int status;   /* uninitialized */

    if (flag) {
        status = 1;
    }
    /* status uninitialized if !flag — UB to read below */

    return status;   /* UB when flag == 0 */
}

int main(void)
{
    printf("mode=1 input=200: %d\n", process_gcc58640(1, 200));
    printf("mode=1 input=50 : %d\n", process_gcc58640(1, 50));
    /* At -O0: may return -1 or 0 (stack-dependent)
     * At -O2: the check is folded — likely always returns 0 */
    printf("mode=0 input=50 : %d\n", process_gcc58640(0, 50));

    printf("uninit flag=1   : %d\n", uninit_branch_gcc58640(1));
    /* At -O0: indeterminate; At -O2: constant-folded */
    printf("uninit flag=0   : %d\n", uninit_branch_gcc58640(0));
    return 0;
}
