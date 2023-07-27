namespace Quantum {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Preparation;
    open Microsoft.Quantum.Measurement;
    

        @EntryPoint()
   operation RunGroverSearch() : Unit {
    // Apply the Grover search
    let results = GroverSearch();
    
    // Output the results
    Message("Results of Grover search:");
    for (result in results) {
        Message($"{result}");
    }
}



    operation ApplyOracle(qs1 : Qubit[], qs2 : Qubit[], target1 : Qubit, target2 : Qubit) : Unit is Adj + Ctl {
        // Define your marking conditions for the two registers here.
        within {
            ApplyPauliFromBitString(PauliX, false, [true, true], qs1);
            ApplyPauliFromBitString(PauliX, false, [true, true], qs2);
        } apply {
            CNOT(qs1[0], target1);
            CNOT(qs2[0], target2);
        }
    }

    operation ApplyGroverIteration(qs1 : Qubit[], qs2 : Qubit[]) : Unit {
        use (target1, target2) = (Qubit(), Qubit());
        X(target1);
        H(target1);
        X(target2);
        H(target2);

        ApplyOracle(qs1, qs2, target1, target2);
        Adjoint ApplyOracle(qs1, qs2, target1, target2);

        ApplyToEachA(H, qs1);
        ApplyToEachA(X, qs1);
        ApplyToEachA(H, qs2);
        ApplyToEachA(X, qs2);

        Controlled Z([qs1[0], qs2[0]], qs1[1]);
        Controlled Z([qs1[0], qs2[0]], qs2[1]);

        ApplyToEachA(X, qs1);
        ApplyToEachA(H, qs1);
        ApplyToEachA(X, qs2);
        ApplyToEachA(H, qs2);

        Reset(target1);
        Reset(target2);
    }

    operation GroverSearch() : (Result[], Result[]) {
        mutable result1 = new Result[Length(qs1)];
        mutable result2 = new Result[Length(qs2)];

        use qs1 = Qubit[Length(result1)];
        use qs2 = Qubit[Length(result2)];

        ApplyToEach(H, qs1);
        ApplyToEach(H, qs2);

        ApplyGroverIteration(qs1, qs2);

        for (i in 0..Length(result1)-1) {
            set result1 w/= i <- M(qs1[i]);
        }
        for (i in 0..Length(result2)-1) {
            set result2 w/= i <- M(qs2[i]);
        }

        ResetAll(qs1);
        ResetAll(qs2);

        return (result1, result2);
    }
}
