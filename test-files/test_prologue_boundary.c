/**
 * Comprehensive test for Prologue Boundary Pass
 *
 * This test file contains functions with different task attributes
 * (discard, immediate, normal) and varying stack usage to verify
 * that the correct boundary markers are inserted.
 *
 * Expected boundary values:
 * - discard:   0xDEAD
 * - immediate: 0xCAFE
 * - normal:    0xBEEF
 *
 * Compile with:
 *   clang -target msp430 -S -emit-llvm test_prologue_boundary.c -o test_prologue_boundary.ll
 *   opt -load-pass-plugin=./build/skeleton/SkeletonPass.so \
 *       -passes="prologue-boundary" test_prologue_boundary.ll -S -o test_prologue_boundary_opt.ll
 *   llc -mtriple=msp430 test_prologue_boundary_opt.ll -o test_prologue_boundary.s
 */

// =============================================================================
// NORMAL FUNCTIONS (Expected boundary: 0xBEEF)
// =============================================================================

/**
 * Normal function with no local variables
 * Expected: PUSH #0xBEEF, PUSH #<stack_size>
 */
int normal_no_locals(int a, int b) {
    return a + b;
}

/**
 * Normal function with small local variables
 * Expected: PUSH #0xBEEF, PUSH #<stack_size>
 */
int normal_with_small_locals(int a, int b) {
    int x = a * 2;
    int y = b * 3;
    return x + y;
}

/**
 * Normal function with larger local variables
 * Expected: PUSH #0xBEEF, PUSH #<stack_size>
 */
int normal_with_large_locals(int a, int b) {
    int arr[10];
    for (int i = 0; i < 10; i++) {
        arr[i] = a + b + i;
    }
    return arr[5];
}

/**
 * Normal function that calls another function
 * Expected: PUSH #0xBEEF, PUSH #<stack_size>
 */
int normal_with_call(int a, int b) {
    return normal_no_locals(a, b) + 10;
}

// =============================================================================
// DISCARD FUNCTIONS (Expected boundary: 0xDEAD)
// =============================================================================

/**
 * Discard function with no local variables
 * Expected: PUSH #0xDEAD, PUSH #<stack_size>
 */
__attribute__((annotate("discard")))
int discard_no_locals(int a, int b) {
    return a + b;
}

/**
 * Discard function with local variables
 * Expected: PUSH #0xDEAD, PUSH #<stack_size>
 */
__attribute__((annotate("discard")))
int discard_with_locals(int a, int b) {
    int x = a * 2;
    int y = b * 3;
    int z = x + y;
    return z;
}

/**
 * Discard function with array
 * Expected: PUSH #0xDEAD, PUSH #<stack_size>
 */
__attribute__((annotate("discard")))
int discard_with_array(int a) {
    int arr[5];
    for (int i = 0; i < 5; i++) {
        arr[i] = a + i;
    }
    return arr[2];
}

// =============================================================================
// IMMEDIATE FUNCTIONS (Expected boundary: 0xCAFE)
// =============================================================================

/**
 * Immediate function with no local variables
 * Expected: PUSH #0xCAFE, PUSH #<stack_size>
 */
__attribute__((annotate("immediate")))
int immediate_no_locals(int a, int b) {
    return a - b;
}

/**
 * Immediate function with local variables
 * Expected: PUSH #0xCAFE, PUSH #<stack_size>
 */
__attribute__((annotate("immediate")))
int immediate_with_locals(int a, int b) {
    int temp1 = a << 1;
    int temp2 = b >> 1;
    return temp1 + temp2;
}

/**
 * Immediate function with array
 * Expected: PUSH #0xCAFE, PUSH #<stack_size>
 */
__attribute__((annotate("immediate")))
int immediate_with_array(int x) {
    int data[8];
    for (int i = 0; i < 8; i++) {
        data[i] = x * i;
    }
    return data[7];
}

/**
 * Immediate function with multiple returns
 * Each return should be preceded by: ADD #4, SP
 * Expected: PUSH #0xCAFE, PUSH #<stack_size>
 */
__attribute__((annotate("immediate")))
int immediate_multiple_returns(int a, int b) {
    if (a > b) {
        return a;  // Should have ADD #4, SP before RET
    } else if (a < b) {
        return b;  // Should have ADD #4, SP before RET
    } else {
        return 0;  // Should have ADD #4, SP before RET
    }
}

// =============================================================================
// MIXED USAGE SCENARIOS
// =============================================================================

/**
 * Normal function calling discard function
 * Expected: normal has 0xBEEF, discard has 0xDEAD
 */
int normal_calls_discard(int a) {
    return discard_no_locals(a, a + 1);
}

/**
 * Discard function calling immediate function
 * Expected: discard has 0xDEAD, immediate has 0xCAFE
 */
__attribute__((annotate("discard")))
int discard_calls_immediate(int a) {
    return immediate_no_locals(a, a - 1);
}

/**
 * Immediate function calling normal function
 * Expected: immediate has 0xCAFE, normal has 0xBEEF
 */
__attribute__((annotate("immediate")))
int immediate_calls_normal(int a) {
    return normal_no_locals(a, a + 2);
}

// =============================================================================
// INTERRUPT FUNCTIONS (No padding, ADD #4, SP)
// =============================================================================

/**
 * Normal interrupt function
 * Expected: PUSH #0xBEEF, PUSH #<stack_size> (no PUSH #0 padding)
 *           ADD #4, SP (not #6)
 */
__attribute__((interrupt(2)))
void isr_normal(void) {
    volatile int x = 42;
}

/**
 * Discard interrupt function
 * Expected: PUSH #0xDEAD, PUSH #<stack_size> (no PUSH #0 padding)
 *           ADD #4, SP (not #6)
 */
__attribute__((interrupt(3), annotate("discard")))
void isr_discard(void) {
    volatile int x = 100;
}

/**
 * Immediate interrupt function
 * Expected: PUSH #0xCAFE, PUSH #<stack_size> (no PUSH #0 padding)
 *           ADD #4, SP (not #6)
 */
__attribute__((interrupt(4), annotate("immediate")))
void isr_immediate(void) {
    volatile int x = 200;
}

// =============================================================================
// MAIN FUNCTION FOR TESTING
// =============================================================================

/**
 * Main function to exercise all test cases
 * Expected: PUSH #0xBEEF (normal function)
 */
int main(void) {
    int result = 0;

    // Test normal functions
    result += normal_no_locals(1, 2);
    result += normal_with_small_locals(3, 4);
    result += normal_with_large_locals(5, 6);
    result += normal_with_call(7, 8);

    // Test discard functions
    result += discard_no_locals(9, 10);
    result += discard_with_locals(11, 12);
    result += discard_with_array(13);

    // Test immediate functions
    result += immediate_no_locals(14, 15);
    result += immediate_with_locals(16, 17);
    result += immediate_with_array(18);
    result += immediate_multiple_returns(19, 20);

    // Test mixed scenarios
    result += normal_calls_discard(21);
    result += discard_calls_immediate(22);
    result += immediate_calls_normal(23);

    return result;
}
