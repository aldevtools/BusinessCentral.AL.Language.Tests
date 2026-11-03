// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-arrays
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (may not compile): A[x][y] on a multi-dimensional array.
// Facts: A[x][y] read and write on a two- and a three-dimensional array against A[x, y]; Text array; out of range index (error text start and code).
// BC versions: 29 (27 and 28 by CI)

codeunit 74836 "LT P168 Chained Array Index"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P168_Chained_TwoDimensions_ReadWrite()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3, 4] of Integer;
        i: Integer;
        j: Integer;
    begin
        A[2][3] := 23;
        Observer.Observe('chained-read', Format(A[2][3]));
        Observer.Observe('comma-read', Format(A[2, 3]));
        A[1, 4] := 14;
        Observer.Observe('chained-read-of-comma', Format(A[1][4]));
        i := 3;
        j := 1;
        A[i][j] := 31;
        Observer.Observe('var-chained', Format(A[3, 1]));
        Observer.Observe('others-zero', Format(A[1][1]) + Format(A[3][4]));
        A[2][3] += 5;
        Observer.Observe('compound', Format(A[2, 3]));
        Observer.Expect('chained-read', '23');
        Observer.Expect('comma-read', '23');
        Observer.Expect('chained-read-of-comma', '14');
        Observer.Expect('var-chained', '31');
        Observer.Expect('others-zero', '00');
        Observer.Expect('compound', '28');
        Observer.Verify();
    end;

    [Test]
    procedure P168_Chained_ThreeDimensionsAndText()
    var
        Observer: Codeunit "Probe Observer";
        B: array[2, 3, 4] of Integer;
        T: array[2, 2] of Text[10];
    begin
        B[2][3][4] := 234;
        Observer.Observe('three-chained', Format(B[2][3][4]));
        Observer.Observe('three-comma', Format(B[2, 3, 4]));
        T[2][1] := 'abc';
        Observer.Observe('text-chained', T[2][1]);
        Observer.Observe('text-comma', T[2, 1]);
        Observer.Expect('three-chained', '234');
        Observer.Expect('three-comma', '234');
        Observer.Expect('text-chained', 'abc');
        Observer.Expect('text-comma', 'abc');
        Observer.Verify();
    end;

    [Test]
    procedure P168_Chained_OutOfRange()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3, 4] of Integer;
        i: Integer;
        j: Integer;
        V: Integer;
    begin
        i := 4;
        j := 1;
        asserterror V := A[i][j];
        Observer.ObserveError('first-index');
        i := 1;
        j := 5;
        asserterror V := A[i][j];
        Observer.ObserveError('second-index');
        i := 0;
        asserterror V := A[i][1];
        Observer.ObserveError('zero-index');
        Observer.Expect('first-index|text', 'Index out of bounds.');
        Observer.Expect('first-index|code', 'IndexOutOfBounds');
        Observer.Expect('second-index|text', 'Index out of bounds.');
        Observer.Expect('second-index|code', 'IndexOutOfBounds');
        Observer.Expect('zero-index|text', 'Index out of bounds.');
        Observer.Expect('zero-index|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;
}
