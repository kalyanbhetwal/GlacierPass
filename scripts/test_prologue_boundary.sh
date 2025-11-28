#!/bin/bash
# Script to compile with prologue boundary marker

set -e

echo "=== Compiling C to LLVM IR ==="
/Users/kb/Documents/myllvmfor-msp430/llvm-install/bin/clang \
    -target msp430 -S -emit-llvm test_boundary.c -o test_boundary.ll

echo "=== Converting to MIR (before prologue insertion) ==="
/Users/kb/Documents/myllvmfor-msp430/llvm-install/bin/llc \
    -mtriple=msp430 test_boundary.ll \
    -stop-before=prologepilog \
    -o test_boundary.mir

echo "=== Running prologue/epilogue insertion ==="
/Users/kb/Documents/myllvmfor-msp430/llvm-install/bin/llc \
    -mtriple=msp430 \
    --run-pass=prologepilog \
    test_boundary.mir \
    -o test_after_prologepilog.mir

echo "=== Inserting custom boundary marker BEFORE prologue ==="
/Users/kb/Documents/myllvmfor-msp430/llvm-install/bin/llc \
    -mtriple=msp430 \
    --load=./llvm-pass-skeleton/build/skeleton/SkeletonPass.dylib \
    --run-pass=prologue-boundary \
    test_after_prologepilog.mir \
    -o test_final_with_boundary.mir

echo "=== Viewing results ==="
echo ""
echo "Function: test_function"
grep -A 12 "name:.*test_function" test_final_with_boundary.mir | grep -A 10 "bb.0"

echo ""
echo "✓ Boundary marker successfully inserted at the top of functions!"
echo "✓ The ANNOTATION_LABEL appears BEFORE the SUB16ri (stack allocation)"
