#!/bin/bash
# Quick test wrapper for GlacierPass - Prologue Boundary Pass

set -e

echo "========================================="
echo "GlacierPass - Prologue Boundary Pass"
echo "========================================="
echo ""
echo "Running comprehensive test suite..."
echo ""

# Change to test directory and run the full test suite
cd test-files
./test_prologue_boundary.sh

echo ""
echo "========================================="
echo "Test Results Summary"
echo "========================================="
echo ""
echo "✓ All boundary markers verified"
echo "✓ Assembly and binary generated"
echo ""
echo "View generated files:"
echo "  - Assembly:      test-files/test_prologue_boundary.s"
echo "  - Object file:   test-files/test_prologue_boundary.o"
echo "  - Disassembly:   test-files/objdump_full.txt"
echo ""
echo "For detailed documentation, see:"
echo "  - README.md"
echo "  - test-files/README_PROLOGUE_BOUNDARY_TEST.md"
echo ""
