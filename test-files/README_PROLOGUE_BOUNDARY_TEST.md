# Prologue Boundary Pass - Test Documentation

## Overview

This directory contains comprehensive tests for the Prologue Boundary Pass, which instruments MSP430 functions with task-specific boundary markers and stack size information.

## Test Files

- **test_prologue_boundary.c** - C source file with test functions
- **test_prologue_boundary.sh** - Automated test script
- **README_PROLOGUE_BOUNDARY_TEST.md** - This documentation

## What is Being Tested

The Prologue Boundary Pass inserts the following instrumentation:

### Prologue (Function Entry)
1. `ANNOTATION_LABEL <boundary_value>` - Compiler annotation (not in stack)
2. `PUSH #<boundary_value>` - 2 bytes on stack
3. `PUSH #<stack_size>` - 2 bytes on stack

### Epilogue (Before Return)
1. `ADD #4, SP` - Remove boundary + stack_size from stack

### Task Types and Boundary Values

| Task Type | Boundary Value | Hex    | Decimal |
|-----------|----------------|--------|---------|
| Normal    | 0xBEEF         | 0xBEEF | 48879   |
| Immediate | 0xCAFE         | 0xCAFE | 51966   |
| Discard   | 0xDEAD         | 0xDEAD | 57005   |

## Test Coverage

### Normal Functions (Boundary: 0xBEEF)
- `normal_no_locals()` - No local variables
- `normal_with_small_locals()` - Small local variables
- `normal_with_large_locals()` - Array allocation
- `normal_with_call()` - Function calls
- `main()` - Main function

### Discard Functions (Boundary: 0xDEAD)
- `discard_no_locals()` - No local variables
- `discard_with_locals()` - Multiple local variables
- `discard_with_array()` - Array allocation

### Immediate Functions (Boundary: 0xCAFE)
- `immediate_no_locals()` - No local variables
- `immediate_with_locals()` - Local variables
- `immediate_with_array()` - Array allocation
- `immediate_multiple_returns()` - Multiple return paths (tests epilogue cleanup)

### Mixed Scenarios
- `normal_calls_discard()` - Normal calling discard
- `discard_calls_immediate()` - Discard calling immediate
- `immediate_calls_normal()` - Immediate calling normal

## Compilation Pipeline

The test follows this pipeline (same as `test_both_passes.sh`):

1. **C → LLVM IR**: Compile C source to LLVM IR
2. **Add Attributes**: Add "discard" and "immediate" attributes to IR
3. **Register Allocation**: Run custom RAMinimal allocator (`-regalloc=minimal`)
4. **Stop before prologepilog**: Generate MIR before standard prologue/epilogue
5. **Run prologepilog pass**: Insert standard prologue/epilogue code
6. **Run prologue-boundary pass**: Add custom boundary markers and stack size
7. **Generate Assembly**: Complete compilation to assembly

**Critical:** The prologue boundary pass MUST run after the standard `prologepilog` pass.

## Running the Tests

### Prerequisites

1. LLVM toolchain with MSP430 support
2. Built Skeleton pass library
3. clang and llc in PATH or LLVM_PATH set

### Quick Start

```bash
cd /Users/kb/Documents/myllvmfor-msp430/GlacierPass/test-files
./test_prologue_boundary.sh
```

### Manual Testing

The correct pipeline for testing requires multiple steps:

```bash
# Step 1: Compile C to LLVM IR
clang -target msp430 -S -emit-llvm test_prologue_boundary.c -o test_prologue_boundary.ll

# Step 2: Add attributes to IR (if needed)
# For functions with __attribute__((annotate("discard"))) or __attribute__((annotate("immediate")))

# Step 3: Run custom register allocator (stop before prologepilog)
llc -mtriple=msp430 \
    -load=../llvm-pass-skeleton/build/skeleton/SkeletonPass.dylib \
    -regalloc=minimal \
    -mcpu=msp430 \
    test_prologue_boundary.ll \
    -stop-before=prologepilog \
    -o test_after_regalloc.mir

# Step 4: Run standard prologue/epilogue insertion
llc -mtriple=msp430 \
    --run-pass=prologepilog \
    test_after_regalloc.mir \
    -o test_after_prologue.mir

# Step 5: Run custom prologue boundary pass
llc -mtriple=msp430 \
    -load=../llvm-pass-skeleton/build/skeleton/SkeletonPass.dylib \
    --run-pass=prologue-boundary \
    test_after_prologue.mir \
    -o test_final.mir

# Step 6: Generate final assembly
llc -mtriple=msp430 \
    test_final.mir \
    -o test_prologue_boundary.s

# Step 7: Inspect the assembly
cat test_prologue_boundary.s
```

**Important:** The prologue boundary pass must run **AFTER** the standard `prologepilog` pass, otherwise the stack frame setup will interfere with our custom boundary markers.

### What to Look For in Assembly

For a function like `immediate_no_locals`:

```asm
immediate_no_locals:
    ; Boundary marker (inserted by pass)
    push    #51966          ; 0xCAFE for immediate task

    ; Stack size (inserted by pass)
    push    #<size>         ; Actual stack frame size

    ; Original function body...

    ; Epilogue cleanup (inserted by pass)
    add     #4, r1          ; Remove boundary + stack_size
    ret
```

## Verification Checklist

For each function, verify:

- [x] Correct boundary value is pushed (0xBEEF/0xCAFE/0xDEAD)
- [x] Stack size is pushed after boundary
- [x] Epilogue contains `ADD #4, SP` before return
- [x] Multiple return paths all have epilogue cleanup
- [x] Functions calling each other maintain correct boundaries

## Stack Size Information

The stack size pushed onto the stack represents the **static frame allocation** and includes:

✓ Local variables (compile-time known sizes)
✓ Spilled registers (from register allocation)
✓ Saved callee-saved registers
✓ Alignment padding

✗ The 4 bytes added by this pass (boundary + stack_size)
✗ Dynamic allocations (alloca, VLAs)
✗ Nested function call overhead

## Expected Output

When all tests pass:

```
========================================
Prologue Boundary Pass - Test Suite
========================================

Step 1: Compiling C to LLVM IR...
✓ LLVM IR generated successfully
Step 2: Compiling to MSP430 assembly...
✓ Assembly generated successfully

========================================
Verifying Boundary Markers
========================================

Normal Functions (Boundary: 0xBEEF):
Checking normal_no_locals (normal): ✓ Found boundary 48879
  → Checking stack size for normal_no_locals: ✓ Stack size present
  → Checking epilogue for normal_no_locals: ✓ Epilogue cleanup found (ADD #4, SP)
...

========================================
Test Summary
========================================
Tests Passed: 18
Tests Failed: 0

All tests passed! ✓
```

## Troubleshooting

### Boundary not found
- Check that the pass is properly loaded
- Verify function attributes are correctly set
- Inspect LLVM IR to ensure attributes are preserved

### Stack size missing
- Verify `MachineFrameInfo::getStackSize()` is being called
- Check that PUSH16i opcode is available for MSP430

### Epilogue cleanup missing
- Ensure all return paths are being instrumented
- Verify ADD16ri opcode lookup is successful
- Check that RET/RETI opcodes are correctly identified

## Related Files

- **PrologueBoundaryPass.cpp** - Pass implementation
- **Skeleton.cpp** - Custom register allocator (may affect stack size)

## Future Enhancements

- [ ] Test with functions that have no returns (infinite loops)
- [ ] Test with tail call optimization enabled
- [ ] Test with exception handling (if supported)
- [ ] Add performance benchmarks
- [ ] Test stack overflow detection using boundary markers
