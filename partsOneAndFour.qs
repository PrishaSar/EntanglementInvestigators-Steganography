namespace parts1and4{

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
        Controlled SWAP([r1,[c0]], (sReg, cReg));
         X(c0);
        Controlled SWAP([r1,r2,[c0]], (cReg, OneReg));
        Controlled X([r1,r2,[c0]], key);
    }

}