// Test file to demonstrate prologue boundary insertion

int test_function(int a, int b) {
    return a + b;
}

int main() {
    int result = test_function(5, 10);
    return result;
}
