namespace NEQR{
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Preparation;

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

   
}
   
    