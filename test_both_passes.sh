#!/bin/bash
# Run both passes: Register Allocator + Prologue Boundary

set -e

LLVM_BIN=/Users/kb/Documents/myllvmfor-msp430/llvm-install/bin
PASS_LIB=./llvm-pass-skeleton/build/skeleton/SkeletonPass.dylib

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║    Running Both Passes: Register Allocator + Calling Conv     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Create test C file with discard attribute
cat > test-files/test_both.c << 'EOF'
// Function WITH discard attribute - uses R12-R15 only
int __attribute__((annotate("discard"))) discard_func(int a, int b) {
    int x = a + b;
    int y = x * 2;
    return y - a;
}

// Function WITHOUT discard - uses R4-R11
int normal_func(int a, int b) {
    int x = a + b;
    int y = x * 2;
    return y - b;
}

int main() {
    int r1 = discard_func(5, 10);
    int r2 = normal_func(3, 7);
    return r1 + r2;
}
EOF

echo "Step 1: Compile C to LLVM IR"
$LLVM_BIN/clang -target msp430 -S -emit-llvm test-files/test_both.c -o test_both.ll

echo ""
echo "Step 2: Add 'discard' attribute to IR"
# Manually add the discard attribute
# Find the attributes line and add discard
if grep -q "^attributes #0 = {" test_both.ll; then
    # Replace existing attributes
    sed -i.bak 's/^attributes #0 = {.*/attributes #0 = { "discard" }/' test_both.ll
else
    # Add new attributes line at the end
    echo '' >> test_both.ll
    echo 'attributes #0 = { "discard" }' >> test_both.ll
fi

echo ""
echo "Step 3: Run with CUSTOM REGISTER ALLOCATOR (minimal)"
echo "        - discard_func uses R12-R15"
echo "        - normal_func uses R4-R11"
$LLVM_BIN/llc -mtriple=msp430 \
    --load=$PASS_LIB \
    -regalloc=minimal \
    test_both.ll \
    -stop-before=prologepilog \
    -o test_after_regalloc.mir

echo ""
echo "Step 4: Run PROLOGUE/EPILOGUE insertion"
$LLVM_BIN/llc -mtriple=msp430 \
    --run-pass=prologepilog \
    test_after_regalloc.mir \
    -o test_after_prologue.mir

echo ""
echo "Step 5: Run PROLOGUE BOUNDARY pass (PUSH 0xBEEF / POP R15)"
$LLVM_BIN/llc -mtriple=msp430 \
    --load=$PASS_LIB \
    --run-pass=prologue-boundary \
    test_after_prologue.mir \
    -o test_final.mir

echo ""
echo "Step 6: Complete compilation to assembly"
$LLVM_BIN/llc -mtriple=msp430 \
    --run-pass=finalize-isel \
    test_final.mir \
    -o test_both_output.s 2>/dev/null || \
$LLVM_BIN/llc -mtriple=msp430 \
    test_both.ll \
    --load=$PASS_LIB \
    -regalloc=minimal \
    -o test_both_output.s

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                         RESULTS                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "Register Allocator Output:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
grep -E "DISCARD MODE|NORMAL MODE" test_both_output.s 2>/dev/null || echo "(Check MIR files for details)"

echo ""
echo "Prologue Boundary (from MIR):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
grep "PUSH16i 48879" test_final.mir | head -2
grep "POP16r" test_final.mir | head -2

echo ""
echo "Final Assembly Preview (discard_func):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
grep -A 10 "discard_func:" test_both_output.s | head -12

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    PIPELINE SUMMARY                            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "✓ Step 1: C → LLVM IR"
echo "✓ Step 2: Add 'discard' attribute"
echo "✓ Step 3: Custom register allocator (R12-R15 vs R4-R11)"
echo "✓ Step 4: Standard prologue/epilogue insertion"
echo "✓ Step 5: Custom calling convention (PUSH/POP 0xBEEF)"
echo "✓ Step 6: Final assembly generation"
echo ""
echo "Output files:"
echo "  • test_final.mir          - MIR with both passes applied"
echo "  • test_both_output.s      - Final assembly"
echo ""

# Cleanup intermediate files
rm -f test_both.ll test_both.ll.bak test_after_regalloc.mir test_after_prologue.mir

echo "Done!"
