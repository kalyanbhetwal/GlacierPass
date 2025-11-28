#!/bin/bash
set -e

LLVM_BIN=/Users/kb/Documents/myllvmfor-msp430/llvm-install/bin

echo "=== Compiling with integrated calling convention ==="

# We'll manually add the PUSH/POP to a modified C file for now
cat > test_with_beef.c << 'CEOF'
int test_function(int a, int b) {
    // The LLVM pass will insert PUSH/POP via inline assembly marker
    return a + b;
}

int main() {
    int result = test_function(5, 10);
    return result;
}
CEOF

echo ""
echo "Step 1: Compile C to assembly with standard MSP430 backend"
$LLVM_BIN/clang -target msp430 -S test_with_beef.c -o test_standard.s

echo ""
echo "Generated standard assembly (without custom calling convention):"
cat test_standard.s

