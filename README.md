# GlacierPass - Custom MSP430 LLVM Passes

Out-of-tree LLVM passes for MSP430 with custom calling convention and register allocation.

## Quick Start

```bash
./test.sh
```

## Features

### 1. Custom Calling Convention
- **PUSH #48879** (0xBEEF) at function entry
- **POP R15** before return
- Stack-based magic number for verification/security

### 2. Custom Register Allocator
- Filters registers based on "discard" function attribute
- Functions with `discard`: Use only R12-R15
- Functions without `discard`: Use all registers except R12-R15

## Directory Structure

```
GlacierPass/
├── test.sh                           ← Quick test (run this!)
├── README.md                         ← This file
│
├── llvm-pass-skeleton/               ← Pass implementations
│   └── skeleton/
│       ├── PrologueBoundary.cpp      ← Calling convention pass
│       └── Skeleton.cpp              ← Register allocator
│
├── docs/                             ← Complete documentation
│   ├── FINAL_ASSEMBLY_SUMMARY.md     ← Assembly guide
│   ├── ASSEMBLY_OUTPUT.md            ← Assembly analysis
│   └── STACK_OPERATIONS.md           ← Stack details
│
├── test-files/                       ← Test sources
│   └── test_boundary.c
│
├── generated-assembly/               ← Final assembly
│   └── test_push_pop_only.s
│
├── generated-mir/                    ← Intermediate files
└── scripts/                          ← Build scripts
```

## Quick Test

```bash
$ ./test.sh

Testing Custom Calling Convention (PUSH 0xBEEF / POP R15)...

✓ Test complete! Results:

Entry (PUSH):
    frame-setup PUSH16i 48879, implicit-def $sp, implicit $sp

Exit (POP):
    $r15 = frame-destroy POP16r implicit-def $sp, implicit $sp

Stack balance: PASS (1 PUSH, 1 POP per function)
```

## Generated Assembly

See `generated-assembly/test_push_pop_only.s`:

```asm
test_function:
    push  #48879      ; Custom CC: Push 0xBEEF
    sub   #4, r1
    [function body]
    add   #4, r1
    pop   r15         ; Custom CC: Pop into R15
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

✅ Custom calling convention (PUSH/POP 0xBEEF)
✅ Custom register allocator (discard attribute)
✅ Assembly generation working
✅ Stack balanced
✅ Fully documented

---

**Last Updated:** 2025-11-01
**Files:** Organized and minimal in home directory
