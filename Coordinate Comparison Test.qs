namespace Quantum {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Preparation;
    open Microsoft.Quantum.Measurement;
    
        operation TestCompareBits() : String {
        mutable result = "";
        use a = Qubit() {
            // Prepare qubit a in state |0>
            Reset(a);
            use b = Qubit() {
                // Prepare qubit b in state |0>
                Reset(b);
                if (CompareBits(a, b) == 0) {
                    set result += "Test 1 passed\n";
                } else {
                    set result += "Test 1 failed\n";
                }
                
                // Prepare qubit b in state |1>
                X(b);
                if (CompareBits(a, b) == 1) {
                    set result += "Test 2 passed\n";
                } else {
                    set result += "Test 2 failed\n";
                }
            }
        }
        return result;
    }
}