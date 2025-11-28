// Function WITH discard attribute - uses R12-R15 only
int __attribute__((annotate("discard"))) discard_func(int a, int b) {
    int x = a + b;
    int y = x * 2;
    return y - a;
}

// Function WITHOUT discard - uses R4-R11
int normal_func(int a, int b) {
    int x = a + b;
    int y = x * 2;
    return y - b;
}

int main() {
    int r1 = discard_func(5, 10);
    int r2 = normal_func(3, 7);
    return r1 + r2;
}
