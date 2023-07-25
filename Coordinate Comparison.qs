namespace Quantum {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Preparation;
    open Microsoft.Quantum.Measurement;

    @EntryPoint()
    operation RunTests() : Unit {
        Message(TestCompareBits());
    }


    
    // Compare two bits
    operation CompareBits(a : Qubit, b : Qubit) : Int {
        let result = M(a) == M(b) ? 0 | 1;
        // It's not a good practice to reset the qubits here because they might be needed for further computations in the caller operation
        // Reset(a);
        // Reset(b);
        return result;
    }

    
    // Compare two binary coordinates
    operation TestCompareBits() : String {
        use q = Qubit();  // Allocate a qubit
        // ... some operations on 'q' ...
        Reset(q);  // Reset 'q' to the |0⟩ state before releasing it

        mutable result = "";
        use a = Qubit() {
            use b = Qubit() {
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
            Reset(a);  // Resetting a here
        }
        return result;
    }

}
