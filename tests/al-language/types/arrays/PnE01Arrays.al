// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-arrays
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 72521
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "An array argument smaller than its parameter (issue 18)" - `var Rows: array[9] of ...` called with an `array[2]` variable
// Facts: ArrayLen, read, write of an element beyond the argument, by value call
// BC versions: 29 (27 and 28 by CI)

codeunit 72521 "LT PnE Array Arg"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Len(var A: array[3] of Integer): Integer
    begin
        exit(ArrayLen(A));
    end;

    local procedure ReadThird(var A: array[3] of Integer): Integer
    begin
        exit(A[3]);
    end;

    local procedure WriteThird(var A: array[3] of Integer)
    begin
        A[3] := 99;
    end;

    local procedure WriteSecond(var A: array[3] of Integer)
    begin
        A[2] := 77;
    end;

    local procedure LenByValue(A: array[3] of Integer): Integer
    begin
        exit(ArrayLen(A));
    end;

    local procedure ReadThirdByValue(A: array[3] of Integer): Integer
    begin
        exit(A[3]);
    end;

    local procedure WriteThirdByValue(A: array[3] of Integer): Integer
    begin
        A[3] := 55;
        exit(A[3]);
    end;

    [Test]
    procedure SmallerArray_VarParameter()
    var
        Observer: Codeunit "Probe Observer";
        Small: array[2] of Integer;
        R: Integer;
    begin
        Small[1] := 1;
        Small[2] := 2;
        Observer.Observe('len', Format(Len(Small)));
        asserterror R := ReadThird(Small);
        Observer.ObserveError('readThird');
        asserterror WriteThird(Small);
        Observer.ObserveError('writeThird');
        WriteSecond(Small);
        Observer.Observe('small2AfterWriteSecond', Format(Small[2]));
        Observer.Observe('small1', Format(Small[1]));
        Observer.Expect('len', '2');
        Observer.Expect('readThird|text', 'Index out of bounds.');
        Observer.Expect('readThird|code', 'IndexOutOfBounds');
        Observer.Expect('writeThird|text', 'Index out of bounds.');
        Observer.Expect('writeThird|code', 'IndexOutOfBounds');
        Observer.Expect('small2AfterWriteSecond', '77');
        Observer.Expect('small1', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SmallerArray_ByValue()
    var
        Observer: Codeunit "Probe Observer";
        Small: array[2] of Integer;
        R: Integer;
    begin
        Small[1] := 1;
        Small[2] := 2;
        Observer.Observe('lenByValue', Format(LenByValue(Small)));
        asserterror R := ReadThirdByValue(Small);
        Observer.ObserveError('readThirdByValue');
        asserterror R := WriteThirdByValue(Small);
        Observer.ObserveError('writeThirdByValue');
        Observer.Observe('small2', Format(Small[2]));
        Observer.Expect('lenByValue', '2');
        Observer.Expect('readThirdByValue|text', 'Index out of bounds.');
        Observer.Expect('readThirdByValue|code', 'IndexOutOfBounds');
        Observer.Expect('writeThirdByValue|text', 'Index out of bounds.');
        Observer.Expect('writeThirdByValue|code', 'IndexOutOfBounds');
        Observer.Expect('small2', '2');
        Observer.Verify();
    end;

    [Test]
    procedure LargerAndEqualArray_VarParameter()
    var
        Observer: Codeunit "Probe Observer";
        Equal: array[3] of Integer;
        R: Integer;
    begin
        Equal[3] := 5;
        Observer.Observe('lenEqual', Format(Len(Equal)));
        Observer.Observe('readEqual', Format(ReadThird(Equal)));
        WriteThird(Equal);
        Observer.Observe('afterWrite', Format(Equal[3]));
        R := LenByValue(Equal);
        Observer.Observe('lenByValueEqual', Format(R));
        Observer.Expect('lenEqual', '3');
        Observer.Expect('readEqual', '5');
        Observer.Expect('afterWrite', '99');
        Observer.Expect('lenByValueEqual', '3');
        Observer.Verify();
    end;
}
