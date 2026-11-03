// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-copyarray-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// CopyArray, ArrayLen, CompressArray, arrays and multi-dimensional arrays, Clear and bounds errors.
// BC versions: 29 (27 and 28 by CI)

codeunit 72514 "LT SyT Arrays"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CopyArray_Forms()
    var
        Observer: Codeunit "Probe Observer";
        Src: array[5] of Integer;
        Dst: array[5] of Integer;
        Small: array[2] of Integer;
        i: Integer;
        Joined: Text;
    begin
        for i := 1 to 5 do
            Src[i] := i * 10;
        CopyArray(Dst, Src, 1);
        for i := 1 to 5 do
            Joined += Format(Dst[i]) + ',';
        Observer.Observe('full', Joined);
        Clear(Dst);
        asserterror CopyArray(Dst, Src, 3);
        Observer.ObserveError('af30');
        Joined := '';
        for i := 1 to 5 do
            Joined += Format(Dst[i]) + ',';
        Observer.Observe('from 3', Joined);
        Clear(Dst);
        asserterror CopyArray(Dst, Src, 2, 2);
        Observer.ObserveError('af37');
        Joined := '';
        for i := 1 to 5 do
            Joined += Format(Dst[i]) + ',';
        Observer.Observe('from 2 count 2', Joined);
        Clear(Dst);
        asserterror CopyArray(Dst, Src, 1, 0);
        Observer.ObserveError('af44');
        Joined := '';
        for i := 1 to 5 do
            Joined += Format(Dst[i]) + ',';
        Observer.Observe('count 0', Joined);
        CopyArray(Small, Src, 1, 2);
        Observer.Observe('small', Format(Small[1]) + ',' + Format(Small[2]));
        asserterror CopyArray(Small, Src, 1);
        Observer.ObserveError('into smaller');
        asserterror CopyArray(Dst, Src, 6);
        Observer.ObserveError('from 6');
        asserterror CopyArray(Dst, Src, 0);
        Observer.ObserveError('from 0');
        asserterror CopyArray(Dst, Src, 1, 6);
        Observer.ObserveError('count 6');
        asserterror CopyArray(Dst, Src, 1, -1);
        Observer.ObserveError('count -1');
        asserterror CopyArray(Dst, Src, 5, 2);
        Observer.ObserveError('from 5 count 2');
        Observer.Expect('full', '10,20,30,40,50,');
        Observer.Expect('af30|text', 'CopyArray: The length parameter 3 does not match the length of the destination array 5.');
        Observer.Expect('af30|code', 'ArrayLengthMismatch');
        Observer.Expect('from 3', '0,0,0,0,0,');
        Observer.Expect('af37|text', 'CopyArray: The length parameter 2 does not match the length of the destination array 5.');
        Observer.Expect('af37|code', 'ArrayLengthMismatch');
        Observer.Expect('from 2 count 2', '0,0,0,0,0,');
        Observer.Expect('af44|text', 'CopyArray: The length parameter 0 does not match the length of the destination array 5.');
        Observer.Expect('af44|code', 'ArrayLengthMismatch');
        Observer.Expect('count 0', '0,0,0,0,0,');
        Observer.Expect('small', '10,20');
        Observer.Expect('into smaller|text', 'CopyArray: The length parameter 5 does not match the length of the destination array 2.');
        Observer.Expect('into smaller|code', 'ArrayLengthMismatch');
        Observer.Expect('from 6|text', 'CopyArray: The length parameter 0 does not match the length of the destination array 5.');
        Observer.Expect('from 6|code', 'ArrayLengthMismatch');
        Observer.Expect('from 0|text', 'CopyArray: The length parameter 6 does not match the length of the destination array 5.');
        Observer.Expect('from 0|code', 'ArrayLengthMismatch');
        Observer.Expect('count 6|text', 'CopyArray: The length parameter 6 does not match the length of the destination array 5.');
        Observer.Expect('count 6|code', 'ArrayLengthMismatch');
        Observer.Expect('count -1|text', 'CopyArray: The length parameter -1 does not match the length of the destination array 5.');
        Observer.Expect('count -1|code', 'ArrayLengthMismatch');
        Observer.Expect('from 5 count 2|text', 'CopyArray: The length parameter 2 does not match the length of the destination array 5.');
        Observer.Expect('from 5 count 2|code', 'ArrayLengthMismatch');
        Observer.Verify();
    end;

    [Test]
    procedure CopyArray_Texts()
    var
        Observer: Codeunit "Probe Observer";
        Src: array[3] of Text;
        Dst: array[3] of Text;
        Code3: array[3] of Code[3];
    begin
        Src[1] := 'a';
        Src[2] := 'b';
        Src[3] := 'c';
        asserterror CopyArray(Dst, Src, 2);
        Observer.ObserveError('af76');
        Observer.Observe('dst1', Dst[1]);
        Observer.Observe('dst2', Dst[2]);
        Observer.Observe('dst3', Dst[3]);
        Code3[1] := 'xyz';
        Observer.Observe('code', Code3[1]);
        asserterror Code3[1] := 'toolong';
        Observer.ObserveError('code overflow');
        Observer.Expect('af76|text', 'CopyArray: The length parameter 2 does not match the length of the destination array 3.');
        Observer.Expect('af76|code', 'ArrayLengthMismatch');
        Observer.Expect('dst1', '');
        Observer.Expect('dst2', '');
        Observer.Expect('dst3', '');
        Observer.Expect('code', 'XYZ');
        Observer.Expect('code overflow|text', 'The length of the string is 7, but it must be less than or equal to 3 characters. Value: toolong');
        Observer.Expect('code overflow|code', 'StringLengthExceeded');
        Observer.Verify();
    end;

    [Test]
    procedure ArrayLen_Values()
    var
        Observer: Codeunit "Probe Observer";
        A: array[7] of Integer;
        M: array[3, 4] of Integer;
        T: array[2, 3, 5] of Text;
        Single: array[1] of Boolean;
    begin
        Observer.Observe('1d', Format(ArrayLen(A)));
        Observer.Observe('2d total', Format(ArrayLen(M)));
        Observer.Observe('2d dim 1', Format(ArrayLen(M, 1)));
        Observer.Observe('2d dim 2', Format(ArrayLen(M, 2)));
        Observer.Observe('3d total', Format(ArrayLen(T)));
        Observer.Observe('3d dim 1', Format(ArrayLen(T, 1)));
        Observer.Observe('3d dim 2', Format(ArrayLen(T, 2)));
        Observer.Observe('3d dim 3', Format(ArrayLen(T, 3)));
        Observer.Observe('1d dim 1', Format(ArrayLen(A, 1)));
        Observer.Observe('single', Format(ArrayLen(Single)));
        asserterror Observer.Observe('dim 3 of 2d', Format(ArrayLen(M, 3)));
        Observer.ObserveError('dim 3 of 2d');
        asserterror Observer.Observe('dim 0', Format(ArrayLen(M, 0)));
        Observer.ObserveError('dim 0');
        Observer.Expect('1d', '7');
        Observer.Expect('2d total', '12');
        Observer.Expect('2d dim 1', '3');
        Observer.Expect('2d dim 2', '4');
        Observer.Expect('3d total', '30');
        Observer.Expect('3d dim 1', '2');
        Observer.Expect('3d dim 2', '3');
        Observer.Expect('3d dim 3', '5');
        Observer.Expect('1d dim 1', '7');
        Observer.Expect('single', '1');
        Observer.Expect('dim 3 of 2d|text', 'The value of ARRAYLEN parameter 2 is outside of the permitted range. The current value is: 3. The permitted range is: from 1 to 2.');
        Observer.Expect('dim 3 of 2d|code', 'OutsidePermittedRange');
        Observer.Expect('dim 0|text', 'The value of ARRAYLEN parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2.');
        Observer.Expect('dim 0|code', 'OutsidePermittedRange');
        Observer.Verify();
    end;

    [Test]
    procedure Array_Bounds()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3] of Integer;
        M: array[2, 2] of Integer;
        i: Integer;
    begin
        A[1] := 1;
        A[3] := 3;
        Observer.Observe('A[1]', Format(A[1]));
        Observer.Observe('A[2] default', Format(A[2]));
        Observer.Observe('A[3]', Format(A[3]));
        i := 4;
        asserterror A[i] := 1;
        Observer.ObserveError('write index 4');
        i := 0;
        asserterror A[i] := 1;
        Observer.ObserveError('write index 0');
        i := -1;
        asserterror A[i] := 1;
        Observer.ObserveError('write index -1');
        i := 4;
        asserterror Observer.Observe('x', Format(A[i]));
        Observer.ObserveError('read index 4');
        i := 0;
        asserterror Observer.Observe('x', Format(A[i]));
        Observer.ObserveError('read index 0');
        i := 3;
        asserterror M[i, 1] := 1;
        Observer.ObserveError('M[3,1]');
        asserterror M[1, i] := 1;
        Observer.ObserveError('M[1,3]');
        i := 0;
        asserterror M[1, i] := 1;
        Observer.ObserveError('M[1,0]');
        i := 2147483647;
        asserterror A[i] := 1;
        Observer.ObserveError('index maxint');
        Observer.Expect('A[1]', '1');
        Observer.Expect('A[2] default', '0');
        Observer.Expect('A[3]', '3');
        Observer.Expect('write index 4|text', 'Index out of bounds.');
        Observer.Expect('write index 4|code', 'IndexOutOfBounds');
        Observer.Expect('write index 0|text', 'Index out of bounds.');
        Observer.Expect('write index 0|code', 'IndexOutOfBounds');
        Observer.Expect('write index -1|text', 'Index out of bounds.');
        Observer.Expect('write index -1|code', 'IndexOutOfBounds');
        Observer.Expect('read index 4|text', 'Index out of bounds.');
        Observer.Expect('read index 4|code', 'IndexOutOfBounds');
        Observer.Expect('read index 0|text', 'Index out of bounds.');
        Observer.Expect('read index 0|code', 'IndexOutOfBounds');
        Observer.Expect('M[3,1]|text', 'Index out of bounds.');
        Observer.Expect('M[3,1]|code', 'IndexOutOfBounds');
        Observer.Expect('M[1,3]|text', 'Index out of bounds.');
        Observer.Expect('M[1,3]|code', 'IndexOutOfBounds');
        Observer.Expect('M[1,0]|text', 'Index out of bounds.');
        Observer.Expect('M[1,0]|code', 'IndexOutOfBounds');
        Observer.Expect('index maxint|text', 'Index out of bounds.');
        Observer.Expect('index maxint|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure Array_MultiDimensional_ClearAndCopy()
    var
        Observer: Codeunit "Probe Observer";
        M: array[2, 3] of Integer;
        N: array[2, 3] of Integer;
        T: array[2] of Text;
        B: array[2] of Boolean;
        D: array[2] of Date;
        r: Integer;
        c: Integer;
        Joined: Text;
    begin
        for r := 1 to 2 do
            for c := 1 to 3 do
                M[r, c] := r * 10 + c;
        asserterror CopyArray(N, M, 1);
        Observer.ObserveError('af172');
        N[1, 1] := 99;
        Observer.Observe('copy by assignment', Format(M[1, 1]) + '|' + Format(N[1, 1]) + '|' + Format(N[2, 3]));
        Clear(M);
        for r := 1 to 2 do
            for c := 1 to 3 do
                Joined += Format(M[r, c]) + ',';
        Observer.Observe('after Clear', Joined);
        Observer.Observe('N unchanged', Format(N[2, 2]));
        T[1] := 'x';
        B[1] := true;
        D[1] := DMY2Date(1, 1, 2000);
        Clear(T);
        Clear(B);
        Clear(D);
        Observer.Observe('T cleared', '[' + T[1] + ']');
        Observer.Observe('B cleared', Format(B[1]));
        Observer.Observe('D cleared', Format(D[1], 0, 9));
        Observer.Observe('len after clear', Format(ArrayLen(M)));
        Observer.Expect('af172|text', 'CopyArray: The source array must be one dimensional.');
        Observer.Expect('af172|code', 'ArrayDimension');
        Observer.Expect('copy by assignment', '11|99|0');
        Observer.Expect('after Clear', '0,0,0,0,0,0,');
        Observer.Expect('N unchanged', '0');
        Observer.Expect('T cleared', '[]');
        Observer.Expect('B cleared', 'No');
        Observer.Expect('D cleared', '');
        Observer.Expect('len after clear', '6');
        Observer.Verify();
    end;

    [Test]
    procedure Array_DifferentSizeAssignment()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3] of Integer;
        B: array[3] of Integer;
    begin
        A[1] := 1;
        A[2] := 2;
        A[3] := 3;
        CopyArray(B, A, 1);
        A[1] := 100;
        Observer.Observe('B[1]', Format(B[1]));
        Observer.Observe('B[3]', Format(B[3]));
        Observer.Observe('A[1]', Format(A[1]));
        Observer.Expect('B[1]', '1');
        Observer.Expect('B[3]', '3');
        Observer.Expect('A[1]', '100');
        Observer.Verify();
    end;

    [Test]
    procedure CompressArray_Texts()
    var
        Observer: Codeunit "Probe Observer";
        T: array[6] of Text;
        i: Integer;
        Joined: Text;
    begin
        T[1] := 'a';
        T[2] := '';
        T[3] := 'b';
        T[4] := '';
        T[5] := '';
        T[6] := 'c';
        CompressArray(T);
        for i := 1 to 6 do
            Joined += '[' + T[i] + ']';
        Observer.Observe('compressed', Joined);
        Observer.Observe('len', Format(ArrayLen(T)));
        Clear(T);
        CompressArray(T);
        Joined := '';
        for i := 1 to 6 do
            Joined += '[' + T[i] + ']';
        Observer.Observe('all empty', Joined);
        T[6] := 'z';
        CompressArray(T);
        Observer.Observe('last moved first', T[1] + '|' + T[6]);
        T[1] := 'p';
        T[2] := 'q';
        T[3] := 'r';
        T[4] := 's';
        T[5] := 't';
        T[6] := 'u';
        CompressArray(T);
        Joined := '';
        for i := 1 to 6 do
            Joined += '[' + T[i] + ']';
        Observer.Observe('full unchanged', Joined);
        Observer.Expect('compressed', '[a][b][c][][][]');
        Observer.Expect('len', '6');
        Observer.Expect('all empty', '[][][][][][]');
        Observer.Expect('last moved first', 'z|');
        Observer.Expect('full unchanged', '[p][q][r][s][t][u]');
        Observer.Verify();
    end;

    [Test]
    procedure Array_OfRecordsAndPassing()
    var
        Observer: Codeunit "Probe Observer";
        Tx: array[3] of Text;
    begin
        Tx[2] := 'mid';
        Observer.Observe('modified in proc', Modify(Tx));
        Observer.Observe('after proc', Tx[1] + '|' + Tx[2] + '|' + Tx[3]);
        Observer.Observe('modified var proc', ModifyVar(Tx));
        Observer.Observe('after var proc', Tx[1] + '|' + Tx[2] + '|' + Tx[3]);
        Observer.Expect('modified in proc', 'changed/mid');
        Observer.Expect('after proc', '|mid|');
        Observer.Expect('modified var proc', 'changed/mid');
        Observer.Expect('after var proc', 'changed|mid|');
        Observer.Verify();
    end;

    local procedure Modify(Values: array[3] of Text): Text
    begin
        Values[1] := 'changed';
        exit(Values[1] + '/' + Values[2]);
    end;

    local procedure ModifyVar(var Values: array[3] of Text): Text
    begin
        Values[1] := 'changed';
        exit(Values[1] + '/' + Values[2]);
    end;
}
