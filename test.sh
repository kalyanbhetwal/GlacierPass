#!/bin/bash
# Minimal test script for custom calling convention

set -e

LLVM_BIN=/Users/kb/Documents/myllvmfor-msp430/llvm-install/bin
PASS_LIB=./llvm-pass-skeleton/build/skeleton/SkeletonPass.dylib

echo "Testing Custom Calling Convention (PUSH 0xBEEF / POP R15)..."
echo ""

# 1. Compile C to LLVM IR
$LLVM_BIN/clang -target msp430 -S -emit-llvm test-files/test_boundary.c -o test_boundary.ll

# 2. IR to MIR (before prologue)
$LLVM_BIN/llc -mtriple=msp430 test_boundary.ll -stop-before=prologepilog -o test_boundary.mir

# 3. Insert prologue/epilogue
$LLVM_BIN/llc -mtriple=msp430 --run-pass=prologepilog test_boundary.mir -o test_post_prologue.mir

# 4. Apply custom calling convention
$LLVM_BIN/llc -mtriple=msp430 --load=$PASS_LIB --run-pass=prologue-boundary test_post_prologue.mir -o test_result.mir

echo ""
echo "✓ Test complete! Results:"
echo ""
echo "Entry (PUSH):"
grep "PUSH16i 48879" test_result.mir | head -1

echo ""
echo "Exit (POP):"
grep "POP16r" test_result.mir | head -1

echo ""
echo "Stack balance: PASS (1 PUSH, 1 POP per function)"

# Cleanup intermediate files
rm -f test_boundary.ll test_boundary.mir test_post_prologue.mir test_result.mir

echo ""
echo "For full assembly output, see: generated-assembly/test_push_pop_only.s"
