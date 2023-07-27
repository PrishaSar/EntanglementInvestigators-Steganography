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

    
        operation IntToQubit(num:Int, n:Int, register: Qubit[]): Unit{
        let boAr = IntAsBoolArray(num, n);
        for i in 0..Length(boAr)-1{
            if(not boAr[i]){
                X(register[i]);
            }
        }
    }

    operation changeGrayscale(register: Qubit[], pixAr: Bool[]):Unit is Adj + Ctl{
        for q in 0..7{

        //convert grayscale bit to Qubit
        use bit = Qubit();
        if(pixAr[q]){
            X(bit);
            //convert corresponding bit to correct bit
            CNOT(bit, register[q]);
            //reset bit
            X(bit);
        }
        }
    }

    operation NEQR(binaryIm: Int[][]): Qubit[]{
        //create appropriate sized qubit register
        let len = Length(binaryIm);
        let n = Ceiling(Lg(IntAsDouble(len)));
        use img = Qubit[8 + 2*n];

        //Step 1 - input location
        // ApplyToEach(PauliI, img[0..7]);
        ApplyToEach(H, img[8..2*n-1]);

        //Step 2 - set entanglement state so that 
        //for each combination of 8..2n-1 qubits representing (X,Y)
        // the correct grayscale value is set
        for i in (0..len-1){
            for j in (0..len-1){
                //get binary grayscale value
                let pix = binaryIm[i][j];
                let pixAr = IntAsBoolArray(pix, 7);


                //if qubit is in state we want, change grayscale according to that
                IntToQubit(i, n, img[8..n-1]);
                IntToQubit(j, n, img[n..2*n-1]);

                Controlled changeGrayscale(img[8..2*n-1], (img[0..7], pixAr));

                IntToQubit(i, n, img[8..n-1]);
                IntToQubit(j, n, img[n..2*n-1]);

                
            }
        }

        return img;

    }

     //custom implementation of the V gate
    operation V(input: Qubit) : Unit {
        Rx(PI()/2.0, input);
    }



    //Reversible Half Subtractor
    //input: B qubit, A qubit
    //output: register for [B, A, S, carry]
    operation RHS(aQubit: Qubit, bQubit: Qubit, outputRegister: Qubit[]) : Unit { 
        use carry = Qubit(); //will be the binary value carried
        use newAQubit = Qubit(); //output for same A value
        //outputRegister = 4

        Controlled Adjoint Rx([aQubit], (PI()/2.0, carry));
        CNOT(aQubit, newAQubit);
        CNOT(bQubit, aQubit);
        Controlled Rx([bQubit], (PI()/2.0, carry));
        Controlled Rx([aQubit], (PI()/2.0, carry));

        //create the output register
        CNOT(bQubit, outputRegister[0]); //B
        CNOT(newAQubit, outputRegister[1]); //A
        CNOT(aQubit, outputRegister[2]); //S
        CNOT(carry, outputRegister[3]); //carry

        Reset(carry);
        Reset(newAQubit);
    }



    //Reversible Full Subtractor
    //input: carry qubit, B qubit, A qubit
    //output: register for [C, B, A, S, carry]
    operation RFS(aQubit: Qubit, bQubit: Qubit, cQubit: Qubit, outputRegister: Qubit[]) : Unit {
        use carry = Qubit(); //new carry value
        use newAQubit = Qubit();
        //outputRegister = 5

        Controlled Adjoint Rx([aQubit], (PI()/2.0, carry));
        CNOT(aQubit, newAQubit);
        CNOT(bQubit, aQubit);
        Controlled Rx([bQubit], (PI()/2.0, carry));
        CNOT(cQubit, aQubit);
        Controlled Rx([cQubit], (PI()/2.0, carry));
        Controlled Rx([aQubit], (PI()/2.0, carry));

        //create output register
        CNOT(cQubit, outputRegister[0]); //C
        CNOT(bQubit, outputRegister[1]); //B
        CNOT(newAQubit, outputRegister[2]); //A
        CNOT(aQubit, outputRegister[3]); //S
        CNOT(carry, outputRegister[4]); //carry

        Reset(carry);
        Reset(newAQubit);
    }



    //Complementary Operation
    //input: all S values in a register
    //output: same S values but may be flipped depending on the dropped sign qubit
    operation CO(sRegister: Qubit[], outputRegister: Qubit[]) : Unit {
        let len = Length(sRegister);
        //outputRegister = len-1 for the dropped qubit

        //part 1
        for i in 0..len-2 {
            CNOT(sRegister[0], sRegister[1+i]); //indexing this way cuz the paper's
                                                //way of indexing was backwards
        }
        //part 2
        for i in 0..len-2 {
            //Controlled X([sRegister[len-1], sRegister[len-3-i..0]], sRegister[len-1-i]);
            use controlRegister = Qubit[len-1-i]; //idk how to properly syntax the controlled
                                                  //x line with multiple control inputs
            CNOT(sRegister[0], controlRegister[0]);

            for j in 2+i..len-2 {
                CNOT(sRegister[j], controlRegister[j-1-i]);
            }

            Controlled X(controlRegister, sRegister[1+i]);
            ResetAll(controlRegister);
        }

        for i in 0..len-2 {
            CNOT(sRegister[i+1], outputRegister[i]);
        }
    }



    //Calculate Absolute Value
    //input: A register, B register
    //output: truncated S register
    operation CAV(aRegister: Qubit[], bRegister: Qubit[], outputRegister: Qubit[]): Unit {
        let len = Length(aRegister);
        use halfOutput = Qubit[4];
        use fullOutput = Qubit[5];
        use sRegister = Qubit[len+1];
        RHS(aRegister[len-1], bRegister[len-1], halfOutput);
        CNOT(halfOutput[2], sRegister[len]);
        
        RFS(aRegister[len-2], bRegister[len-2], halfOutput[3], fullOutput);
        CNOT(fullOutput[3], sRegister[len-1]);

        for i in len-3..-1..1 {
            use intermediaryRegister = Qubit[5];
            RFS(aRegister[i], bRegister[i], fullOutput[4], intermediaryRegister);
            CNOT(fullOutput[3], sRegister[i+1]);
            ResetAll(fullOutput);

            for j in 0..4 {CNOT(intermediaryRegister[j], fullOutput[j]);}
            ResetAll(intermediaryRegister);
        }

        use intermediaryRegister = Qubit[5];
        RFS(aRegister[0], bRegister[0], fullOutput[4], intermediaryRegister);
        CNOT(fullOutput[3], sRegister[1]);
        CNOT(intermediaryRegister[4], sRegister[0]);

        CO(sRegister, outputRegister);
        ResetAll(halfOutput);
        ResetAll(fullOutput);
        ResetAll(sRegister);
        ResetAll(intermediaryRegister);
    }

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

    operation QuantumBlur(qubits: Qubit[]) : Unit {
        ApplyToEach(H, qubits);
    }

    @EntryPoint
    operation glue (binaryIm Int[][]) : Result[]{
        let sercetImg = NEQR(binaryIm);
        let Img = NEQR(binaryIm);

        use aRegister = Qubit[Length(img)];
        use bRegister = Qubit[Length(img)];

        use outputRegister = Qubit[Length(img)- 1];

        CAV(aRegister, bRegister, outputRegister);

        QuantumBlur(img);

        //add opperatiions to process quantum image

        let result = GroverSearch();

        //measure quantum system and convert back to a classical image

        return results;
    }
    
    operation ExtractSecretImage(stegoImg : Qubit[], keyImg : Qubit[], emptyImg : Qubit[]) : Qubit[] {
        // n is the number of qubits required to store each pixel
        let n = Length(stegoImg) / 2;

        // Initialize the secret image
        use secretImg = Qubit[Length(stegoImg)];

        // Loop over all pixels
        for i in 0..Length(stegoImg)-1 by 2*n {
            // Extract cs from stego image
            let cs = stegoImg[i..i+2*n-1];

            // Compare the key and cs
            if (M(keyImg[i/2*n]) == Zero) {
                // If key is |0⟩, cs is the grayscale value of the i-th pixel in the secret image
                secretImg[i..i+2*n-1] <= cs;
            } else {
                // Else, cs is not the grayscale value of the i-th pixel in the secret image
                secretImg[i..i+2*n-1] <= emptyImg[i..i+2*n-1];
            }
        }

        return secretImg;
    }
}


