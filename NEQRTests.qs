namespace NEQR {

    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Intrinsic;


    @Test("QuantumSimulator")
    operation NEQRTest () : Unit {
        let img = [[4,3,5],[223, 40, 1],[100, 200, 10]];

        let final = NEQR(img);

        
        
    }

}
