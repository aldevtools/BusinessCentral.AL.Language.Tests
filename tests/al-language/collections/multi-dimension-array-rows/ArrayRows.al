// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-arrays
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); codeunit 74888
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: rows (sub-arrays) of multi-dimensional arrays. Assigning a whole row (A[2] := Row) does not compile (AL0145), so rows are filled by element, by CopyArray and
//   by a callee. Clear(A[2]) clears one row; Clear of a row of a three-dimensional array; passing a row by value and by var to a parameter of the same length;
//   a callee parameter of another length than the row (shorter and longer): ArrayLen seen by the callee and which elements it reads and writes;
//   a 2-D sub-array B[1] of a 3-D array passed to a parameter array[3, 4].
// BC versions: all (CI)

codeunit 74888 "LT ARR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Dump2(A: array[3, 4] of Integer): Text
    var
        i: Integer;
        j: Integer;
        Result: Text;
    begin
        for i := 1 to 3 do begin
            for j := 1 to 4 do
                Result += Format(A[i, j]) + ',';
            Result += '|';
        end;
        exit(Result);
    end;

    local procedure Fill2(var A: array[3, 4] of Integer)
    var
        i: Integer;
        j: Integer;
    begin
        for i := 1 to 3 do
            for j := 1 to 4 do
                A[i, j] := i * 10 + j;
    end;

    local procedure RowByValue(R: array[4] of Integer): Text
    begin
        R[1] := 999;
        exit(Format(R[1]) + ',' + Format(R[2]) + ',' + Format(R[3]) + ',' + Format(R[4]));
    end;

    local procedure RowByVar(var R: array[4] of Integer)
    begin
        R[1] := 999;
    end;

    local procedure ShorterParam(var R: array[3] of Integer): Text
    begin
        R[1] := 777;
        exit('len=' + Format(ArrayLen(R)) + ' r1=' + Format(R[1]) + ' r2=' + Format(R[2]) + ' r3=' + Format(R[3]));
    end;

    local procedure ShorterParamByValue(R: array[3] of Integer): Text
    begin
        R[1] := 777;
        exit('len=' + Format(ArrayLen(R)) + ' r1=' + Format(R[1]) + ' r3=' + Format(R[3]));
    end;

    local procedure LongerParam(var R: array[6] of Integer): Text
    begin
        exit('len=' + Format(ArrayLen(R)) + ' r1=' + Format(R[1]) + ' r4=' + Format(R[4]));
    end;

    [TryFunction]
    local procedure TryReadLonger(var R: array[6] of Integer; Idx: Integer; var Value: Integer)
    begin
        Value := R[Idx];
    end;

    [TryFunction]
    local procedure TryWriteLonger(var R: array[6] of Integer; Idx: Integer)
    begin
        R[Idx] := 555;
    end;

    local procedure TwoDimByValue(A: array[3, 4] of Integer): Text
    begin
        A[1, 1] := 4242;
        exit(Dump2(A));
    end;

    local procedure TwoDimByVar(var A: array[3, 4] of Integer)
    begin
        A[1, 1] := 4242;
    end;

    [Test]
    procedure TwoDim_ClearRow()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3, 4] of Integer;
    begin
        Fill2(A);
        Clear(A[2]);
        Observer.Observe('afterClearRow2', Dump2(A));
        Clear(A[1, 3]);
        Observer.Observe('afterClearElement', Dump2(A));
        Observer.Expect('afterClearRow2', '11,12,13,14,|0,0,0,0,|31,32,33,34,|');
        Observer.Expect('afterClearElement', '11,12,0,14,|0,0,0,0,|31,32,33,34,|');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_RowByValue_AndVar()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3, 4] of Integer;
    begin
        Fill2(A);
        Observer.Observe('byValueResult', RowByValue(A[2]));
        Observer.Observe('afterByValue', Dump2(A));
        RowByVar(A[2]);
        Observer.Observe('afterByVar', Dump2(A));
        Observer.Expect('byValueResult', '999,22,23,24');
        Observer.Expect('afterByValue', '11,12,13,14,|21,22,23,24,|31,32,33,34,|');
        Observer.Expect('afterByVar', '11,12,13,14,|999,22,23,24,|31,32,33,34,|');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_CopyArrayRow()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3, 4] of Integer;
    begin
        Fill2(A);
        CopyArray(A[3], A[1], 1);
        Observer.Observe('copyRow3IntoRow1', Dump2(A));
        Observer.Expect('copyRow3IntoRow1', '11,12,13,14,|21,22,23,24,|11,12,13,14,|');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_RowToShorterParameter()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3, 4] of Integer;
    begin
        Fill2(A);
        Observer.Observe('byValue', ShorterParamByValue(A[2]));
        Observer.Observe('afterByValue', Dump2(A));
        Observer.Observe('byVar', ShorterParam(A[2]));
        Observer.Observe('afterByVar', Dump2(A));
        Observer.Expect('byValue', 'len=4 r1=777 r3=23');
        Observer.Expect('afterByValue', '11,12,13,14,|21,22,23,24,|31,32,33,34,|');
        Observer.Expect('byVar', 'len=4 r1=777 r2=22 r3=23');
        Observer.Expect('afterByVar', '11,12,13,14,|777,22,23,24,|31,32,33,34,|');
        Observer.Verify();
    end;

    [Test]
    procedure TwoDim_RowToLongerParameter()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3, 4] of Integer;
        Value: Integer;
        Ok: Boolean;
    begin
        Fill2(A);
        Observer.Observe('read', LongerParam(A[2]));
        Ok := TryReadLonger(A[2], 5, Value);
        Observer.Observe('read5', Format(Ok) + ' ' + Format(Value));
        if not Ok then
            Observer.ObserveError('read5Err');
        Ok := TryReadLonger(A[2], 6, Value);
        Observer.Observe('read6', Format(Ok) + ' ' + Format(Value));
        if not Ok then
            Observer.ObserveError('read6Err');
        Ok := TryWriteLonger(A[2], 5);
        Observer.Observe('write5', Format(Ok));
        if not Ok then
            Observer.ObserveError('write5Err');
        Observer.Observe('afterWrite5', Dump2(A));
        Ok := TryWriteLonger(A[2], 7);
        Observer.Observe('write7', Format(Ok));
        if not Ok then
            Observer.ObserveError('write7Err');
        Observer.Observe('afterWrite7', Dump2(A));
        Observer.Expect('read', 'len=4 r1=21 r4=24');
        Observer.Expect('read5', 'No 0');
        Observer.Expect('read5Err|text', 'Index out of bounds.');
        Observer.Expect('read5Err|code', 'IndexOutOfBounds');
        Observer.Expect('read6', 'No 0');
        Observer.Expect('read6Err|text', 'Index out of bounds.');
        Observer.Expect('read6Err|code', 'IndexOutOfBounds');
        Observer.Expect('write5', 'No');
        Observer.Expect('write5Err|text', 'Index out of bounds.');
        Observer.Expect('write5Err|code', 'IndexOutOfBounds');
        Observer.Expect('afterWrite5', '11,12,13,14,|21,22,23,24,|31,32,33,34,|');
        Observer.Expect('write7', 'No');
        Observer.Expect('write7Err|text', 'Index out of bounds.');
        Observer.Expect('write7Err|code', 'IndexOutOfBounds');
        Observer.Expect('afterWrite7', '11,12,13,14,|21,22,23,24,|31,32,33,34,|');
        Observer.Verify();
    end;

    [Test]
    procedure ThreeDim_Rows()
    var
        Observer: Codeunit "Probe Observer";
        B: array[2, 3, 4] of Integer;
        i: Integer;
        j: Integer;
        k: Integer;
        Result: Text;
    begin
        for i := 1 to 2 do
            for j := 1 to 3 do
                for k := 1 to 4 do
                    B[i, j, k] := i * 100 + j * 10 + k;
        Observer.Observe('subArrayByValue', TwoDimByValue(B[1]));
        Observer.Observe('subArrayAfterByValue', Format(B[1, 1, 1]));
        TwoDimByVar(B[2]);
        Observer.Observe('subArrayAfterByVar', Format(B[2, 1, 1]) + ' ' + Format(B[1, 1, 1]));
        Observer.Observe('rowByValue', RowByValue(B[1, 2]));
        RowByVar(B[2, 3]);
        Observer.Observe('rowAfterByVar', Format(B[2, 3, 1]) + ' ' + Format(B[2, 2, 1]));
        Clear(B[1, 2]);
        Observer.Observe('afterClearRow', Format(B[1, 2, 1]) + ',' + Format(B[1, 2, 4]) + ' neighbours ' + Format(B[1, 1, 1]) + ',' + Format(B[1, 3, 1]));
        Clear(B[2]);
        Result := '';
        for j := 1 to 3 do
            for k := 1 to 4 do
                Result += Format(B[2, j, k]) + ',';
        Observer.Observe('afterClearSubArray', Result + ' other ' + Format(B[1, 1, 1]));
        Observer.Observe('lens', Format(ArrayLen(B)) + ' ' + Format(ArrayLen(B, 2)) + ' ' + Format(ArrayLen(B, 3)));
        Observer.Expect('subArrayByValue', '4242,112,113,114,|121,122,123,124,|131,132,133,134,|');
        Observer.Expect('subArrayAfterByValue', '111');
        Observer.Expect('subArrayAfterByVar', '4242 111');
        Observer.Expect('rowByValue', '999,122,123,124');
        Observer.Expect('rowAfterByVar', '999 221');
        Observer.Expect('afterClearRow', '0,0 neighbours 111,131');
        Observer.Expect('afterClearSubArray', '0,0,0,0,0,0,0,0,0,0,0,0, other 111');
        Observer.Expect('lens', '24 3 4');
        Observer.Verify();
    end;

    [Test]
    procedure ThreeDim_RowToShorterParameter()
    var
        Observer: Codeunit "Probe Observer";
        B: array[2, 3, 4] of Integer;
    begin
        B[1, 2, 1] := 1;
        B[1, 2, 2] := 2;
        B[1, 2, 3] := 3;
        B[1, 2, 4] := 4;
        Observer.Observe('shorter', ShorterParam(B[1, 2]));
        Observer.Observe('after', Format(B[1, 2, 1]) + ',' + Format(B[1, 2, 2]) + ',' + Format(B[1, 2, 3]) + ',' + Format(B[1, 2, 4]));
        Observer.Expect('shorter', 'len=4 r1=777 r2=2 r3=3');
        Observer.Expect('after', '777,2,3,4');
        Observer.Verify();
    end;
}
