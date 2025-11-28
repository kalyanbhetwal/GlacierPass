#!/bin/bash
set -e

LLVM_BIN=/Users/kb/Documents/myllvmfor-msp430/llvm-install/bin
PASS_LIB=./llvm-pass-skeleton/build/skeleton/SkeletonPass.dylib

echo "=== Step 1: C to LLVM IR ==="
$LLVM_BIN/clang -target msp430 -S -emit-llvm test_boundary.c -o test.ll

echo ""
echo "=== Step 2: LLVM IR to MIR (before prologue) ==="
$LLVM_BIN/llc -mtriple=msp430 test.ll -stop-before=prologepilog -o test_pre.mir

echo ""
echo "=== Step 3: Insert prologue/epilogue ==="
$LLVM_BIN/llc -mtriple=msp430 --run-pass=prologepilog test_pre.mir -o test_post_prologue.mir

echo ""
echo "=== Step 4: Apply custom calling convention (PUSH 0xBEEF + POP R15) ==="
$LLVM_BIN/llc -mtriple=msp430 \
    --load=$PASS_LIB \
    --run-pass=prologue-boundary \
    test_post_prologue.mir \
    -o test_with_cc.mir

echo ""
echo "=== Step 5: Complete compilation to assembly ==="
$LLVM_BIN/llc -mtriple=msp430 \
    --run-pass=finalize-isel,localstackslotalloc,dead-mi-elimination,machine-scheduler,post-RA-sched,gc-lowering,branch-folder,tailduplication,machine-cp,postrapseudos,implicit-null-checks,shrink-wrap,stackmap-liveness,livedebugvalues,machine-block-freq,machine-opt-remark-emitter,prologue-epilogue-insertion,block-placement,asm-printer \
    test_with_cc.mir \
    -o test_final_asm.s 2>&1 | head -50

if [ -f test_final_asm.s ]; then
    echo ""
    echo "=== SUCCESS! Generated assembly ==="
    echo "File: test_final_asm.s"
else
    echo "Trying simpler approach..."
    # Just compile from LLVM IR with the calling convention applied via inline modification
fi
