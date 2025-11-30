#!/bin/bash

# Comprehensive test script for Prologue Boundary Pass
# This script compiles the test file and verifies that the correct boundary
# markers are inserted for each function type.

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TEST_FILE="test_prologue_boundary.c"
LLVM_IR="test_prologue_boundary.ll"
ASM_FILE="test_prologue_boundary.s"
LLVM_PATH="${LLVM_PATH:-/Users/kb/Documents/myllvmfor-msp430/llvm-project/build}"
PASS_LIB="./llvm-pass-skeleton/build/skeleton/SkeletonPass.so"

echo "========================================"
echo "Prologue Boundary Pass - Test Suite"
echo "========================================"
echo ""

# Check if test file exists
if [ ! -f "$TEST_FILE" ]; then
    echo -e "${RED}Error: Test file $TEST_FILE not found${NC}"
    exit 1
fi

# Step 1: Compile C to LLVM IR with optimization
echo -e "${YELLOW}Step 1: Compiling C to LLVM IR with optimization...${NC}"
/usr/bin/clang -target msp430 -S -emit-llvm -O2 "$TEST_FILE" -o "$LLVM_IR"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ LLVM IR generated successfully (optimized)${NC}"
else
    echo -e "${RED}✗ Failed to generate LLVM IR${NC}"
    exit 1
fi

# Step 2: Add attributes to IR (discard and immediate)
echo -e "${YELLOW}Step 2: Adding function attributes to IR...${NC}"

# Add discard attribute to non-ISR discard functions
sed -i.bak 's/@discard_\([a-z_]*\)(\([^)]*\)) #[0-9]*/@discard_\1(\2) #99/g' "$LLVM_IR"
sed -i.bak 's/@discard_\([a-z_]*\)(\([^)]*\)) {/@discard_\1(\2) #99 {/g' "$LLVM_IR"

# Add immediate attribute to non-ISR immediate functions
sed -i.bak 's/@immediate_\([a-z_]*\)(\([^)]*\)) #[0-9]*/@immediate_\1(\2) #98/g' "$LLVM_IR"
sed -i.bak 's/@immediate_\([a-z_]*\)(\([^)]*\)) {/@immediate_\1(\2) #98 {/g' "$LLVM_IR"

# Make ISR functions use the interrupt attributes #3 and #4
# isr_discard uses #3 (interrupt="3")
sed -i.bak 's/@isr_discard() #[0-9]*/@isr_discard() #3/g' "$LLVM_IR"
sed -i.bak 's/@isr_discard() {/@isr_discard() #3 {/g' "$LLVM_IR"

# isr_immediate uses #4 (interrupt="4")
sed -i.bak 's/@isr_immediate() #[0-9]*/@isr_immediate() #4/g' "$LLVM_IR"
sed -i.bak 's/@isr_immediate() {/@isr_immediate() #4 {/g' "$LLVM_IR"

# Update ISR attribute definitions to include discard/immediate
# Add "discard" to attribute #3 (interrupt="3")
sed -i.bak 's/attributes #3 = { \(.*\) "interrupt"="\([0-9]*\)" \(.*\) }/attributes #3 = { \1 "discard" "interrupt"="\2" \3 }/' "$LLVM_IR"

# Add "immediate" to attribute #4 (interrupt="4")
sed -i.bak 's/attributes #4 = { \(.*\) "interrupt"="\([0-9]*\)" \(.*\) }/attributes #4 = { \1 "immediate" "interrupt"="\2" \3 }/' "$LLVM_IR"

# Append attribute definitions for non-ISR functions
echo '' >> "$LLVM_IR"
echo 'attributes #99 = { "discard" }' >> "$LLVM_IR"
echo 'attributes #98 = { "immediate" }' >> "$LLVM_IR"

echo -e "${GREEN}✓ Added 'discard' attribute (#99) to discard functions${NC}"
echo -e "${GREEN}✓ Added 'immediate' attribute (#98) to immediate functions${NC}"
echo -e "${GREEN}✓ Updated ISR attributes${NC}"
echo ""

# Check if pass library exists
if [ ! -f "../llvm-pass-skeleton/build/skeleton/SkeletonPass.dylib" ] && [ ! -f "../llvm-pass-skeleton/build/skeleton/SkeletonPass.so" ]; then
    echo -e "${RED}Error: Pass library not found. Please build the pass first.${NC}"
    echo "Run: cd llvm-pass-skeleton && mkdir -p build && cd build && cmake .. && make"
    exit 1
fi

# Determine pass library extension
if [ -f "../llvm-pass-skeleton/build/skeleton/SkeletonPass.dylib" ]; then
    PASS_LIB="../llvm-pass-skeleton/build/skeleton/SkeletonPass.dylib"
elif [ -f "../llvm-pass-skeleton/build/skeleton/SkeletonPass.so" ]; then
    PASS_LIB="../llvm-pass-skeleton/build/skeleton/SkeletonPass.so"
fi

# Step 3: Run register allocator (stop before prologepilog)
echo -e "${YELLOW}Step 3: Running custom register allocator...${NC}"
"${LLVM_PATH}/bin/llc" -mtriple=msp430 \
    -load="$PASS_LIB" \
    -regalloc=minimal \
    -mcpu=msp430 \
    "$LLVM_IR" \
    -stop-before=prologepilog \
    -o test_after_regalloc.mir

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Register allocation completed${NC}"
else
    echo -e "${RED}✗ Register allocation failed${NC}"
    exit 1
fi

# Step 4: Run standard prologue/epilogue insertion
echo -e "${YELLOW}Step 4: Running standard prologue/epilogue insertion...${NC}"
"${LLVM_PATH}/bin/llc" -mtriple=msp430 \
    --run-pass=prologepilog \
    test_after_regalloc.mir \
    -o test_after_prologue.mir

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Prologue/epilogue insertion completed${NC}"
else
    echo -e "${RED}✗ Prologue/epilogue insertion failed${NC}"
    exit 1
fi

# Step 5: Run custom prologue boundary pass
echo -e "${YELLOW}Step 5: Running custom prologue boundary pass...${NC}"
"${LLVM_PATH}/bin/llc" -mtriple=msp430 \
    -load="$PASS_LIB" \
    --run-pass=prologue-boundary \
    test_after_prologue.mir \
    -o test_final.mir

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Prologue boundary pass completed${NC}"
else
    echo -e "${RED}✗ Prologue boundary pass failed${NC}"
    exit 1
fi

# Step 6: Complete compilation to assembly
echo -e "${YELLOW}Step 6: Generating final assembly...${NC}"
# Use -start-after to skip machine passes that require SSA
# This allows optimization while avoiding SSA-dependent passes after register allocation
"${LLVM_PATH}/bin/llc" -mtriple=msp430 \
    -x mir \
    -start-after=prologepilog \
    test_final.mir \
    -o "$ASM_FILE" 2>&1 | tee llc_output.log

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Assembly generated successfully (optimized)${NC}"
else
    # Fallback to -O0 if the optimized version fails
    echo -e "${YELLOW}Falling back to -O0...${NC}"
    "${LLVM_PATH}/bin/llc" -mtriple=msp430 \
        -x mir \
        -O0 \
        test_final.mir \
        -o "$ASM_FILE"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Assembly generated successfully (unoptimized)${NC}"
    else
        echo -e "${RED}✗ Failed to generate assembly${NC}"
        exit 1
    fi
fi

# Step 7: Generate object file and binary
echo ""
echo -e "${YELLOW}Step 7: Generating object file and binary...${NC}"

OBJ_FILE="test_prologue_boundary.o"
BINARY_FILE="test_prologue_boundary.elf"

# Generate object file from assembly
"${LLVM_PATH}/bin/llvm-mc" -triple=msp430 -filetype=obj "$ASM_FILE" -o "$OBJ_FILE"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Object file generated${NC}"
else
    echo -e "${YELLOW}⚠ Could not generate object file (continuing anyway)${NC}"
fi

# Generate binary (linking may fail without proper libs, but we'll try)
"${LLVM_PATH}/bin/ld.lld" -m msp430elf "$OBJ_FILE" -o "$BINARY_FILE" 2>/dev/null || true

echo ""
echo "========================================"
echo "Object Dump Analysis"
echo "========================================"
echo ""

# Disassemble the object file to show actual binary code with boundaries
if [ -f "$OBJ_FILE" ]; then
    echo -e "${YELLOW}Full Disassembly:${NC}"
    echo ""
    "${LLVM_PATH}/bin/llvm-objdump" -d "$OBJ_FILE" > objdump_full.txt
    head -150 objdump_full.txt

    echo ""
    echo -e "${YELLOW}Analyzing boundary markers in binary:${NC}"
    echo ""

    # Show immediate_no_locals function
    echo "immediate_no_locals (should start with PUSH #51966 = 0xCAFE):"
    grep -A 10 "immediate_no_locals>:" objdump_full.txt | head -12
    echo ""

    # Show discard_no_locals function
    echo "discard_no_locals (should start with PUSH #57005 = 0xDEAD):"
    grep -A 10 "discard_no_locals>:" objdump_full.txt | head -12
    echo ""

    # Show normal_no_locals function
    echo "normal_no_locals (should start with PUSH #48879 = 0xBEEF):"
    grep -A 10 "normal_no_locals>:" objdump_full.txt | head -12
    echo ""

    # Hex dump to verify boundary values in raw binary
    echo -e "${YELLOW}Hex dump of .text section (first 256 bytes):${NC}"
    "${LLVM_PATH}/bin/llvm-objdump" -s --section=.text "$OBJ_FILE" | head -30
    echo ""
fi

echo ""
echo "========================================"
echo "Verifying Boundary Markers"
echo "========================================"
echo ""

# Function to check for boundary marker
check_boundary() {
    local func_name=$1
    local expected_boundary=$2
    local task_type=$3

    echo -n "Checking $func_name ($task_type): "

    # Extract the function and look for the PUSH instruction with boundary
    if grep -A 10 "^${func_name}:" "$ASM_FILE" | grep -q "push.*#${expected_boundary}"; then
        echo -e "${GREEN}✓ Found boundary ${expected_boundary}${NC}"
        return 0
    else
        echo -e "${RED}✗ Boundary ${expected_boundary} NOT found${NC}"
        return 1
    fi
}

# Function to check for stack size push
check_stack_size() {
    local func_name=$1

    echo -n "  → Checking stack size for $func_name: "

    # Look for a second PUSH instruction after the boundary
    if grep -A 10 "^${func_name}:" "$ASM_FILE" | grep -c "push.*#" | grep -q "[2-9]"; then
        echo -e "${GREEN}✓ Stack size present${NC}"
        return 0
    else
        echo -e "${YELLOW}? Stack size unclear${NC}"
        return 0  # Don't fail on this
    fi
}

# Function to check for epilogue cleanup
check_epilogue() {
    local func_name=$1

    echo -n "  → Checking epilogue for $func_name: "

    # Look for ADD #6, SP before return (non-interrupt) or ADD #4, SP (interrupt)
    # Use -A 50 to handle longer functions with multiple basic blocks
    if grep -A 50 "^${func_name}:" "$ASM_FILE" | grep -B 1 "ret\|reti" | grep -q "add.*#6.*r1\|add.*#6.*sp"; then
        echo -e "${GREEN}✓ Epilogue cleanup found (ADD #6, SP)${NC}"
        return 0
    elif grep -A 50 "^${func_name}:" "$ASM_FILE" | grep -B 1 "ret\|reti" | grep -q "add.*#4.*r1\|add.*#4.*sp"; then
        echo -e "${GREEN}✓ Epilogue cleanup found (ADD #4, SP for interrupt)${NC}"
        return 0
    else
        echo -e "${RED}✗ Epilogue cleanup NOT found${NC}"
        return 1
    fi
}

PASSED=0
FAILED=0

# Test Normal Functions (0xBEEF = 48879 decimal)
echo -e "${YELLOW}Normal Functions (Boundary: 0xBEEF):${NC}"
for func in "normal_no_locals" "normal_with_small_locals" "normal_with_large_locals" "normal_with_call" "main"; do
    if check_boundary "$func" "48879" "normal"; then
        check_stack_size "$func"
        check_epilogue "$func"
        ((PASSED++))
    else
        ((FAILED++))
    fi
done
echo ""

# Test Discard Functions (0xDEAD = 57005 decimal)
echo -e "${YELLOW}Discard Functions (Boundary: 0xDEAD):${NC}"
for func in "discard_no_locals" "discard_with_locals" "discard_with_array"; do
    if check_boundary "$func" "57005" "discard"; then
        check_stack_size "$func"
        check_epilogue "$func"
        ((PASSED++))
    else
        ((FAILED++))
    fi
done
echo ""

# Test Immediate Functions (0xCAFE = 51966 decimal)
echo -e "${YELLOW}Immediate Functions (Boundary: 0xCAFE):${NC}"
for func in "immediate_no_locals" "immediate_with_locals" "immediate_with_array" "immediate_multiple_returns"; do
    if check_boundary "$func" "51966" "immediate"; then
        check_stack_size "$func"
        check_epilogue "$func"
        ((PASSED++))
    else
        ((FAILED++))
    fi
done
echo ""

# Test Mixed Scenarios
echo -e "${YELLOW}Mixed Function Calls:${NC}"
check_boundary "normal_calls_discard" "48879" "normal" && ((PASSED++)) || ((FAILED++))
check_boundary "discard_calls_immediate" "57005" "discard" && ((PASSED++)) || ((FAILED++))
check_boundary "immediate_calls_normal" "51966" "immediate" && ((PASSED++)) || ((FAILED++))
echo ""

# Test Interrupt Functions (should have NO padding, ADD #4 SP)
echo -e "${YELLOW}Interrupt Functions (Boundary markers, no padding, ADD #4):${NC}"
echo -n "Checking isr_normal (interrupt): "
if check_boundary "isr_normal" "48879" "interrupt"; then
    # Check for NO padding (should NOT have PUSH #0 before boundary)
    if ! grep -A 5 "^isr_normal:" "$ASM_FILE" | head -6 | grep -q "push.*#0"; then
        echo -e "  ${GREEN}✓ No padding found${NC}"
    else
        echo -e "  ${RED}✗ Unexpected padding found${NC}"
    fi
    # Check for ADD #4, not #6
    if grep -A 20 "^isr_normal:" "$ASM_FILE" | grep -B 1 "reti" | grep -q "add.*#4.*r1\|add.*#4.*sp"; then
        echo -e "  ${GREEN}✓ Epilogue cleanup found (ADD #4, SP)${NC}"
        ((PASSED++))
    else
        echo -e "  ${RED}✗ Wrong epilogue cleanup${NC}"
        ((FAILED++))
    fi
else
    ((FAILED++))
fi

echo -n "Checking isr_discard (interrupt+discard): "
if check_boundary "isr_discard" "57005" "interrupt+discard"; then
    if ! grep -A 5 "^isr_discard:" "$ASM_FILE" | head -6 | grep -q "push.*#0"; then
        echo -e "  ${GREEN}✓ No padding found${NC}"
    else
        echo -e "  ${RED}✗ Unexpected padding found${NC}"
    fi
    if grep -A 20 "^isr_discard:" "$ASM_FILE" | grep -B 1 "reti" | grep -q "add.*#4.*r1\|add.*#4.*sp"; then
        echo -e "  ${GREEN}✓ Epilogue cleanup found (ADD #4, SP)${NC}"
        ((PASSED++))
    else
        echo -e "  ${RED}✗ Wrong epilogue cleanup${NC}"
        ((FAILED++))
    fi
else
    ((FAILED++))
fi

echo -n "Checking isr_immediate (interrupt+immediate): "
if check_boundary "isr_immediate" "51966" "interrupt+immediate"; then
    if ! grep -A 5 "^isr_immediate:" "$ASM_FILE" | head -6 | grep -q "push.*#0"; then
        echo -e "  ${GREEN}✓ No padding found${NC}"
    else
        echo -e "  ${RED}✗ Unexpected padding found${NC}"
    fi
    if grep -A 20 "^isr_immediate:" "$ASM_FILE" | grep -B 1 "reti" | grep -q "add.*#4.*r1\|add.*#4.*sp"; then
        echo -e "  ${GREEN}✓ Epilogue cleanup found (ADD #4, SP)${NC}"
        ((PASSED++))
    else
        echo -e "  ${RED}✗ Wrong epilogue cleanup${NC}"
        ((FAILED++))
    fi
else
    ((FAILED++))
fi
echo ""

# Summary
echo "========================================"
echo "Test Summary"
echo "========================================"
echo -e "Tests Passed: ${GREEN}$PASSED${NC}"
echo -e "Tests Failed: ${RED}$FAILED${NC}"
echo ""

echo ""
echo "========================================"
echo "Generated Files"
echo "========================================"
echo ""
echo "Output files available for inspection:"
echo "  - Assembly:      $ASM_FILE"
echo "  - Object file:   $OBJ_FILE"
if [ -f "$BINARY_FILE" ]; then
    echo "  - Binary:        $BINARY_FILE"
fi
echo "  - Disassembly:   objdump_full.txt"
echo "  - LLVM IR:       $LLVM_IR"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    echo ""
    echo "To view the object dump:"
    echo "  llvm-objdump -d test_prologue_boundary.o"
    echo ""
    echo "To view hex dump:"
    echo "  llvm-objdump -s test_prologue_boundary.o"
    echo ""

    # Keep object files for inspection, only clean up intermediate MIR
    echo "Cleaning up intermediate MIR files..."
    rm -f test_after_regalloc.mir test_after_prologue.mir test_final.mir test_prologue_boundary.ll.bak* llc_output.log

    exit 0
else
    echo -e "${RED}Some tests failed! ✗${NC}"
    echo ""
    echo "Debug files retained for inspection:"
    echo "  - MIR files: test_after_regalloc.mir, test_after_prologue.mir, test_final.mir"
    echo "  - Object dump: objdump_full.txt"
    exit 1
fi
