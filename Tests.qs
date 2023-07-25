namespace files {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Preparation;
    open Microsoft.Quantum.Diagnostics;

    @Test("QuantumSimulator")
    operation RHStest1() : Unit { //00 -> 0000
        use a = Qubit();
        use b = Qubit();
        use output = Qubit[4];

        RHS(a, b, output);

        AssertAllZero(output);

        Reset(a);
        Reset(b);
        ResetAll(output);
    }

    @Test("QuantumSimulator")
    operation RHStest2() : Unit { //01 -> 1011
        use a = Qubit();
        use b = Qubit();
        use output = Qubit[4];

        X(b);
        RHS(a, b, output);

        //AssertQubit(One, output[0]);
        //AssertQubit(Zero, output[1]);
        //AssertQubit(One, output[2]);
        AssertQubit(One, output[3]);

        Reset(a);
        Reset(b);
        ResetAll(output);
    }

    @Test("QuantumSimulator")
    operation RHStest3() : Unit { //10 -> 0110
        use a = Qubit();
        use b = Qubit();
        use output = Qubit[4];

        X(a);
        RHS(a, b, output);

        //AssertQubit(Zero, output[0]);
        //AssertQubit(One, output[1]);
        //AssertQubit(One, output[2]);
        AssertQubit(Zero, output[3]);

        Reset(a);
        Reset(b);
        ResetAll(output);
    }

    @Test("QuantumSimulator")
    operation RFStest1() : Unit { //110 -> 01100
        use a = Qubit();
        use b = Qubit();
        use c = Qubit();
        use output = Qubit[5];

        X(a);
        X(b);

        RFS(a, b, c, output);

        //AssertQubit(Zero, output[0]);
        //AssertQubit(One, output[1]);
        //AssertQubit(One, output[2]);
        //AssertQubit(Zero, output[3]);
        AssertQubit(Zero, output[4]);

        Reset(a);
        Reset(b);
        Reset(c);
        ResetAll(output);
    }

    @Test("QuantumSimulator")
    operation RFStest2() : Unit { //111 -> 11111
        use a = Qubit();
        use b = Qubit();
        use c = Qubit();
        use output = Qubit[5];

        X(a);
        X(b);
        X(c);

        RFS(a, b, c, output);

        ApplyToEach(X, output);
        AssertAllZero(output);

        Reset(a);
        Reset(b);
        Reset(c);
        ResetAll(output);
    }

    @Test("QuantumSimulator")
    operation RFStest3() : Unit { //101 -> 10100
        use a = Qubit();
        use b = Qubit();
        use c = Qubit();
        use output = Qubit[5];

        X(a);
        X(c);

        RFS(a, b, c, output);

        //AssertQubit(One, output[0]);
        //AssertQubit(Zero, output[1]);
        //AssertQubit(One, output[2]);
        //AssertQubit(Zero, output[3]);
        AssertQubit(Zero, output[4]);

        Reset(a);
        Reset(b);
        Reset(c);
        ResetAll(output);
    }

    @Test("QuantumSimulator")
    operation COtest1() : Unit { //111100 -> 00010
        use input = Qubit[6];
        use output = Qubit[5];

        ApplyToEach(X, input[0..3]);

        CO(input, output);

        //AssertQubit(Zero, output[0]);
        //AssertQubit(Zero, output[1]);
        //AssertQubit(Zero, output[2]);
        //AssertQubit(One, output[3]);
        AssertQubit(Zero, output[4]);

        ResetAll(input);
        ResetAll(output);
    }

    @Test("QuantumSimulator")
    operation COtest2() : Unit { //010101 -> 10101
        use input = Qubit[6];
        use output = Qubit[5];
        
        X(input[1]);
        X(input[3]);
        X(input[5]);

        CO(input, output);

        //AssertQubit(One, output[0]);
        //AssertQubit(Zero, output[1]);
        //AssertQubit(One, output[2]);
        //AssertQubit(Zero, output[3]);
        AssertQubit(One, output[4]);

        ResetAll(input);
        ResetAll(output);
    }

    @Test("QuantumSimulator")
    operation COtest3() : Unit { //1011101 -> 0
        use input = Qubit[6];
        use output = Qubit[5];
        
        X(input[1]);
        X(input[3]);
        X(input[5]);

        CO(input, output);

        //AssertQubit(One, output[0]);
        //AssertQubit(Zero, output[1]);
        //AssertQubit(One, output[2]);
        //AssertQubit(Zero, output[3]);
        AssertQubit(One, output[4]);

        ResetAll(input);
        ResetAll(output);
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

    operation COpart1(sRegister: Qubit[], outputRegister: Qubit[]) : Unit {
        let len = Length(sRegister);
        //outputRegister = len-1 for the dropped qubit

        //part 1
        for i in 0..len-2 {
            CNOT(sRegister[0], sRegister[1+i]); //indexing this way cuz the paper's
                                                          //way of indexing was backwards
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
        
        RFS(aRegister[len-2], bRegister[len-2], halfOutput[3], fullOutput);
        CNOT(fullOutput[4], sRegister[Length(sRegister)-1]);

        for i in len-3..-1..1 {
            use intermediaryRegister = Qubit[5];
            ResetAll(intermediaryRegister);
            RFS(aRegister[i], bRegister[i], fullOutput[4], intermediaryRegister);
            CNOT(fullOutput[4], sRegister[i+1]);
            ResetAll(fullOutput);

            for j in 0..4 {CNOT(intermediaryRegister[j], fullOutput[j]);}
        }

        use intermediaryRegister = Qubit[5];
        ResetAll(intermediaryRegister);
        RFS(aRegister[0], bRegister[0], fullOutput[4], intermediaryRegister);
        CNOT(fullOutput[4], sRegister[1]);
        CNOT(intermediaryRegister[4], sRegister[0]);
        ResetAll(fullOutput);
        ResetAll(intermediaryRegister);

        CO(sRegister, outputRegister);
    }
}
