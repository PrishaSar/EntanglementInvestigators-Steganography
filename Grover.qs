namespace Quantum {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Preparation;
    open Microsoft.Quantum.Measurement;
    
        @EntryPoint()
    operation RunGroverSearch() : Result[] {
        return GroverSearch();
    }


    operation ApplyOracle(qs : Qubit[], target : Qubit) : Unit is Adj + Ctl {
        within {
            ApplyPauliFromBitString(PauliX, false, [true, true], qs);
        } apply {
            X(target);
        }
    }

    operation ApplyGroverIteration(qs : Qubit[]) : Unit {
        use target = Qubit();
        X(target);
        H(target);
        ApplyOracle(qs, target);
        Adjoint ApplyOracle(qs, target);
        ApplyToEachA(H, qs);
        ApplyToEachA(X, qs);
        Controlled Z([qs[0]], qs[1]);
        ApplyToEachA(X, qs);
        ApplyToEachA(H, qs);
        Reset(target);
    }


    operation GroverSearch() : Result[] {
        mutable result = [Zero, Zero];
        use qs = Qubit[2] {
            ApplyToEach(H, qs);
            ApplyGroverIteration(qs);
            set result w/= 0 <- M(qs[0]);
            set result w/= 1 <- M(qs[1]);
            ResetAll(qs);
        }
        return result;
    }
}
