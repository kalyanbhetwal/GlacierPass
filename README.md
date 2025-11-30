# GlacierPass - Custom MSP430 LLVM Passes

Out-of-tree LLVM passes for MSP430 with task-based boundary markers and custom register allocation.

## Quick Start

```bash
cd test-files
./test_prologue_boundary.sh
```

## Features

### 1. Prologue Boundary Pass
Inserts task-specific boundary markers at function entry:
- **Normal functions**: `PUSH #48879` (0xBEEF)
- **Discard functions**: `PUSH #57005` (0xDEAD)
- **Immediate functions**: `PUSH #51966` (0xCAFE)
- Stack size tracking with second PUSH instruction
- Epilogue cleanup with `ADD #4, SP` before return

### 2. Custom Register Allocator
- Filters registers based on "discard" function attribute
- Functions with `discard`: Use only R12-R15
- Functions without `discard`: Use all registers except R12-R15

## Directory Structure

```
GlacierPass/
├── README.md                         ← This file
│
├── llvm-pass-skeleton/               ← Pass implementations
│   └── skeleton/
│       ├── PrologueBoundary.cpp      ← Prologue boundary marker pass
│       └── Skeleton.cpp              ← Custom register allocator
│
├── test-files/                       ← Test suite
│   ├── test_prologue_boundary.c      ← Comprehensive test file
│   ├── test_prologue_boundary.sh     ← Main test script
│   ├── test_prologue_boundary.s      ← Generated assembly
│   ├── objdump_full.txt              ← Disassembly output
│   └── README_PROLOGUE_BOUNDARY_TEST.md
│
├── docs/                             ← Documentation
│   ├── FINAL_ASSEMBLY_SUMMARY.md
│   ├── ASSEMBLY_OUTPUT.md
│   └── STACK_OPERATIONS.md
│
└── scripts/                          ← Build scripts
```

## Test Output

```bash
$ cd test-files && ./test_prologue_boundary.sh

========================================
Prologue Boundary Pass - Test Suite
========================================

Normal Functions (Boundary: 0xBEEF):
Checking normal_no_locals (normal): ✓ Found boundary 48879
Checking normal_with_small_locals (normal): ✓ Found boundary 48879
Checking normal_with_large_locals (normal): ✓ Found boundary 48879
Checking normal_with_call (normal): ✓ Found boundary 48879
Checking main (normal): ✓ Found boundary 48879

Discard Functions (Boundary: 0xDEAD):
Checking discard_no_locals (discard): ✓ Found boundary 57005
Checking discard_with_locals (discard): ✓ Found boundary 57005
Checking discard_with_array (discard): ✓ Found boundary 57005

Immediate Functions (Boundary: 0xCAFE):
Checking immediate_no_locals (immediate): ✓ Found boundary 51966
Checking immediate_with_locals (immediate): ✓ Found boundary 51966
Checking immediate_with_array (immediate): ✓ Found boundary 51966
Checking immediate_multiple_returns (immediate): ✓ Found boundary 51966

Tests Passed: 15
Tests Failed: 0

All tests passed! ✓
```

## Generated Assembly Example

See `test-files/test_prologue_boundary.s`:

```asm
normal_no_locals:
    push  #48879      ; 0xBEEF - Normal task boundary
    push  #2          ; Stack size
    push  r10
    [function body]
    pop   r10
    add   #4, r1      ; Epilogue cleanup
    ret

discard_no_locals:
    push  #57005      ; 0xDEAD - Discard task boundary
    push  #0          ; Stack size
    [function body]
    add   #4, r1      ; Epilogue cleanup
    ret

immediate_no_locals:
    push  #51966      ; 0xCAFE - Immediate task boundary
    push  #2          ; Stack size
    push  r10
    [function body]
    pop   r10
    add   #4, r1      ; Epilogue cleanup
    ret
```

## Documentation

All detailed documentation is in `docs/`:

- **FINAL_ASSEMBLY_SUMMARY.md** - Complete assembly guide
- **ASSEMBLY_OUTPUT.md** - Assembly comparison & analysis
- **STACK_OPERATIONS.md** - Stack behavior details
- **CALLING_CONVENTION_PASS.md** - Implementation details
- **README_CUSTOM_CC.md** - User guide

## Build

Passes are pre-built. To rebuild:

```bash
cd llvm-pass-skeleton/build
cmake -DCMAKE_PREFIX_PATH=/Users/kb/Documents/myllvmfor-msp430/llvm-install ..
make
```

## Usage

### Compile to Assembly

```bash
msp430-elf-gcc generated-assembly/test_push_pop_only.s -o program.elf
```

### Manual Pipeline

For custom testing, see scripts in `scripts/` directory.

## Status

✅ Prologue boundary markers (0xBEEF/0xDEAD/0xCAFE)
✅ Task-specific boundary insertion based on function attributes
✅ Custom register allocator (discard attribute)
✅ Stack size tracking with second PUSH
✅ Epilogue cleanup (ADD #4, SP before RET)
✅ Comprehensive test suite (15 tests passing)
✅ Assembly and binary generation working
✅ Fully documented

## Verification

View the disassembly to verify boundary markers in binary:
```bash
cd test-files
llvm-objdump -d test_prologue_boundary.o | less
```

Look for the hex patterns in the binary:
- **0xBEEF** (ef be) = Normal functions
- **0xDEAD** (ad de) = Discard functions
- **0xCAFE** (fe ca) = Immediate functions

---

**Last Updated:** 2025-11-29
**Test Suite:** 15/15 tests passing
