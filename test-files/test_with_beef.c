int test_function(int a, int b) {
    // The LLVM pass will insert PUSH/POP via inline assembly marker
    return a + b;
}

int main() {
    int result = test_function(5, 10);
    return result;
}
