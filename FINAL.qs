namespace Steganography {

    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Preparation;
    open Microsoft.Quantum.Measurement;

    operation ExtractSecretImage(stegoImg : Qubit[], keyImg : Qubit[], emptyImg : Qubit[]) : Qubit[] {
        // n is the number of qubits required to store each pixel
        let n = Length(stegoImg) / 4;

        // Initialize the secret image
        use secretImg = Qubit[Length(stegoImg)];

        // Loop over all pixels
        for i in 0..Length(stegoImg)-1 / 4*n {
            // Extract cs from stego image
            let cs = stegoImg[i..i+4*n-1];
            
            // Loop over the bits
            for j in 0..Length(cs)-1 {
                // Copy cs to secretImg if keyImg is Zero
                (ControlledOnInt(0, CNOT))(keyImg[i/2*n .. i/2*n+n-1], (cs[j], secretImg[i+j]));
                // Copy emptyImg to secretImg if keyImg is One
                (ControlledOnInt(1, CNOT))(keyImg[i/2*n .. i/2*n+n-1], (emptyImg[i+j], secretImg[i+j]));
            }
        }

        return secretImg;
    }

    // Compare two bits
    operation CompareBits(a : Qubit, b : Qubit) : Int {
        let result = M(a) == M(b) ? 0 | 1;
        // It's not a good practice to reset the qubits here because they might be needed for further computations in the caller operation
        // Reset(a);
        // Reset(b);
        return result;
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

    operation GroverSearch(qs1 : Qubit[], qs2 : Qubit[]) : (Result[], Result[]) {
        mutable result1 = MultiM(qs1);
        mutable result2 = MultiM(qs2);

        ApplyToEach(H, qs1);
        ApplyToEach(H, qs2);

        ApplyGroverIteration(qs1, qs2);

        for i in 0..Length(result1)-1 {
            set result1 w/= i <- M(qs1[i]);
        }
        for i in 0..Length(result2)-1 {
            set result2 w/= i <- M(qs2[i]);
        }

        ResetAll(qs1);
        ResetAll(qs2);

        return (result1, result2);
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

    operation Embedding2(
        cRegister : Qubit[], //c values -> c values
        sRegister : Qubit[], //s values -> s values
        sInvRegister : Qubit[], //same length but all 1s -> s values but flipped
        d1 : Qubit[], //same length but all 0s -> Abs(c - s)
        d2 : Qubit[] //same length but all 0s -> Abs(c - (s inverse))
    ) : Unit {
        let len = Length(cRegister); //same length for every register in the input
        CAV(cRegister, sRegister, d1);
        for i in 0..len {
            CNOT(sRegister[i], sInvRegister[i]);
        }
        CAV(cRegister, sInvRegister, d2);
    }

    operation Embedding3(
        d2 : Qubit[], //Abs(c-s)
        d1 : Qubit[], //Abs(c - (s inverse))
        c1 : Qubit, //output qubit 1
        c2 : Qubit  //output qubit 2
    ) : Unit {
        ApplyOracle(d2, d1, c1, c2);
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
    
    operation part1(cover: Qubit[], secret:Qubit[], key:Qubit[], n:Int):(Qubit[], Qubit[]){
        // let CY = cover[8..n-1];
        // let CX = cover[n..2*n-1];
        // let SY = secret[8..n-1];
        // let SX = secret[n..2*n-1];

        use r1 = Qubit[2*n];
        use r2 = Qubit[2*n];

        for i in 0..2*n{
            let r = CompareBits(cover[i + 8], secret[i + 8]);
            if(r == 1){
                X(r1[i]);
            }
        }

        for i in 0..2*n{
            let r = CompareBits(cover[i], key[i]);
            if(r == 1){
                X(r2[i]);
            }
        }

        return(r1,r2);

    }

    operation part4(key: Qubit, c0: Qubit, r2: Qubit[], r1: Qubit[], sReg:Qubit[], cReg:Qubit[], OneReg: Qubit[]) : Unit{
        X(c0);
        mutable control = r1;
        set control += [c0];
        for i in 0..Length(sReg)-1{
            Controlled SWAP(control, (sReg[i], cReg[i]));
        }
        X(c0);
        set control += r2;
        for i in 0..Length(sReg)-1{
            Controlled SWAP(control, (OneReg[i], cReg[i]));
        }
        Controlled X(control, key);
    }


    operation Steganography(coverImg: Int[][], secretImg: Int[][]): Qubit{
        let cover = NEQR(coverImg);
        let secret = NEQR(secretImg);
        let len = Length(coverImg);
        let keyImg = [[0, size=len], size=len];
        mutable key = NEQR(keyImg);
        let n = Ceiling(Lg(IntAsDouble(len)));
        let (r1, r2) = part1(cover, secret, key, n);
        use s = Qubit[8 + 2*n];
        ApplyToEach(X, s);
        use d1 = Qubit[8 + 2*n];
        use d2 = Qubit[8 + 2*n];
        Embedding2(cover, secret, s, d1, d2);
        use c = Qubit[2];
        Embedding3(d2, d1, c[0], c[1]);
        use keyi = Qubit();
        part4(keyi, c[0], r2, r1, secret, cover, s);

        return (keyi);
    }
}