// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-arrays
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73924
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "A chained index of a multi-dimensional array, and a row of one" (Page extension overload of a base page procedure ...): Clear(A[2]) and which cells it clears
// Facts: Clear(A[2]) on array[3, 4] of Integer and of Text: which cells are cleared; Clear(A) for comparison
// BC versions: 29 (27 and 28 by CI)
// Note for the lead: if Clear of a row does not compile on BC, drop this file (that is the observation: a must-not-compile case).

codeunit 73924 "LT PnF Array Row Clear"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Fill(var A: array[3, 4] of Integer)
    var
        i: Integer;
        j: Integer;
    begin
        for i := 1 to 3 do begin
            for j := 1 to 4 do begin
                A[i, j] := i * 10 + j;
            end;
        end;
    end;

    local procedure Dump(var A: array[3, 4] of Integer): Text
    var
        i: Integer;
        j: Integer;
        R: Text;
    begin
        for i := 1 to 3 do begin
            for j := 1 to 4 do begin
                R += Format(A[i, j]) + ',';
            end;
            R += '|';
        end;
        exit(R);
    end;

    [Test]
    procedure Array_ClearRow()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3, 4] of Integer;
    begin
        Fill(A);
        Observer.Observe('before', Dump(A));
        Clear(A[2]);
        Observer.Observe('after_clear_row2', Dump(A));
        Observer.Expect('before', '11,12,13,14,|21,22,23,24,|31,32,33,34,|');
        Observer.Expect('after_clear_row2', '11,12,13,14,|0,0,0,0,|31,32,33,34,|');
        Observer.Verify();
    end;

    [Test]
    procedure Array_ClearWhole()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3, 4] of Integer;
    begin
        Fill(A);
        Clear(A);
        Observer.Observe('after_clear', Dump(A));
        Observer.Expect('after_clear', '0,0,0,0,|0,0,0,0,|0,0,0,0,|');
        Observer.Verify();
    end;

    [Test]
    procedure Array_ClearCell()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3, 4] of Integer;
    begin
        Fill(A);
        Clear(A[2, 3]);
        Observer.Observe('after_clear_cell', Dump(A));
        Observer.Expect('after_clear_cell', '11,12,13,14,|21,22,0,24,|31,32,33,34,|');
        Observer.Verify();
    end;
}
