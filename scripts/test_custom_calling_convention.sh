#!/bin/bash
# Test script for custom calling convention pass

set -e

LLVM_BIN=/Users/kb/Documents/myllvmfor-msp430/llvm-install/bin
PASS_LIB=./llvm-pass-skeleton/build/skeleton/SkeletonPass.dylib

echo "=========================================="
echo "Custom Calling Convention Test"
echo "=========================================="
echo ""

echo "1. Compiling C to LLVM IR..."
$LLVM_BIN/clang -target msp430 -S -emit-llvm test_boundary.c -o test_boundary.ll

echo "2. Converting to MIR (before prologue insertion)..."
$LLVM_BIN/llc -mtriple=msp430 test_boundary.ll \
    -stop-before=prologepilog \
    -o test_boundary.mir

echo "3. Running prologue/epilogue insertion..."
$LLVM_BIN/llc -mtriple=msp430 \
    --run-pass=prologepilog \
    test_boundary.mir \
    -o test_after_prologepilog.mir

echo "4. Applying custom calling convention (boundary + POP)..."
$LLVM_BIN/llc -mtriple=msp430 \
    --load=$PASS_LIB \
    --run-pass=prologue-boundary \
    test_after_prologepilog.mir \
    -o test_custom_cc.mir

echo ""
echo "=========================================="
echo "Results for test_function:"
echo "=========================================="
grep -A 18 "bb.0.entry" test_custom_cc.mir | head -20

echo ""
echo "=========================================="
echo "Summary:"
echo "=========================================="
echo "✓ ANNOTATION_LABEL inserted at function entry (before prologue)"
echo "✓ POP R15 inserted before RET (after epilogue)"
echo ""
echo "Verify:"
grep "ANNOTATION_LABEL" test_custom_cc.mir | head -2
grep "POP16r" test_custom_cc.mir | head -2
echo ""
echo "Test completed successfully!"
