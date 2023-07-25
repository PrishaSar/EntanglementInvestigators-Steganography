namespace Quantum {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Preparation;
    open Microsoft.Quantum.Measurement;



    operation TestGroverSearch() : String {
        mutable result = "";
        use (a1, a2) = (Qubit(), Qubit()) {
            use (b1, b2) = (Qubit(), Qubit()) {
                // Prepare qubits a1, a2, b1, b2 in state |00>
                Reset(a1);
                Reset(a2);
                Reset(b1);
                Reset(b2);

                if (GroverSearch(a1, a2, b1, b2) == 0) {
                    set result += "Test 1 passed\n";
                } else {
                    set result += "Test 1 failed\n";
                }

                // Prepare qubits b1, b2 in state |11>
                X(b1);
                X(b2);
                if (GroverSearch(a1, a2, b1, b2) == 1) {
                    set result += "Test 2 passed\n";
                } else {
                    set result += "Test 2 failed\n";
                }
            }
        }
        return result;
    }
}