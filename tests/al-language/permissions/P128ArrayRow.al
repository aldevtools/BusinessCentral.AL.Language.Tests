// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-arrays
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73188
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: a row of a multi-dimensional array (A[2] of array[3, 4]) passed as an array argument; if it does not compile, drop the file (a must-not-compile fact).
// Facts: a row passed by value and by var to a procedure whose parameter is a one-dimensional array of the row length, what the callee sees, whether a write through var reaches the row, the other
// rows after the call; an array of Text rows. Rows assigned and cleared are in misc/lt-probes-needed-6/PnF25 and PnF26.
// BC versions: 29 (27 and 28 by CI)

codeunit 73188 "LT P128 Array Row"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SumRow(Row: array[4] of Integer): Integer
    var
        i: Integer;
        Total: Integer;
    begin
        for i := 1 to 4 do
            Total += Row[i];
        exit(Total);
    end;

    local procedure FillRow(var Row: array[4] of Integer; Value: Integer)
    var
        i: Integer;
    begin
        for i := 1 to 4 do
            Row[i] := Value + i;
    end;

    local procedure TextRow(var Row: array[4] of Text)
    var
        i: Integer;
    begin
        for i := 1 to 4 do
            Row[i] := 'r' + Format(i);
    end;

    local procedure Dump(var A: array[3, 4] of Integer): Text
    var
        i: Integer;
        j: Integer;
        Result: Text;
    begin
        for i := 1 to 3 do begin
            for j := 1 to 4 do
                Result += Format(A[i, j]) + ',';
            Result += '/';
        end;
        exit(Result);
    end;

    [Test]
    procedure P128_ArrayRow_ByValue()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3, 4] of Integer;
        i: Integer;
        j: Integer;
    begin
        for i := 1 to 3 do
            for j := 1 to 4 do
                A[i, j] := i * 10 + j;
        Observer.Observe('sum row 1', Format(SumRow(A[1])));
        Observer.Observe('sum row 2', Format(SumRow(A[2])));
        Observer.Observe('sum row 3', Format(SumRow(A[3])));
        Observer.Expect('sum row 1', '50');
        Observer.Expect('sum row 2', '90');
        Observer.Expect('sum row 3', '130');
        Observer.Verify();
    end;

    [Test]
    procedure P128_ArrayRow_ByVar()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3, 4] of Integer;
    begin
        FillRow(A[2], 100);
        Observer.Observe('after FillRow(A[2], 100)', Dump(A));
        FillRow(A[3], 200);
        Observer.Observe('after FillRow(A[3], 200)', Dump(A));
        Observer.Expect('after FillRow(A[2], 100)', '0,0,0,0,/101,102,103,104,/0,0,0,0,/');
        Observer.Expect('after FillRow(A[3], 200)', '0,0,0,0,/101,102,103,104,/201,202,203,204,/');
        Observer.Verify();
    end;

    [Test]
    procedure P128_ArrayRow_TextRowByVar()
    var
        Observer: Codeunit "Probe Observer";
        B: array[2, 4] of Text;
    begin
        TextRow(B[2]);
        Observer.Observe('row 2 cell 1', B[2, 1]);
        Observer.Observe('row 2 cell 4', B[2, 4]);
        Observer.Observe('row 1 cell 1', '[' + B[1, 1] + ']');
        Observer.Expect('row 2 cell 1', 'r1');
        Observer.Expect('row 2 cell 4', 'r4');
        Observer.Expect('row 1 cell 1', '[]');
        Observer.Verify();
    end;
}
