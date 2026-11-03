// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-arrays
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73925
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "A chained index of a multi-dimensional array, and a row of one" (Page extension overload of a base page procedure ...): B := A[2] with B: array[3], ArrayLen(A[2])
// Facts: ArrayLen of a row and of the whole array, ArrayLen(A, 1) and ArrayLen(A, 2), a row assigned to a one-dimensional array of the row's length
// BC versions: 29 (27 and 28 by CI)
// Note for the lead: if a form does not compile on BC, drop that test (the failure to compile is the observation: a must-not-compile case).

codeunit 73925 "LT PnF Array Row Assign"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Array_ArrayLen_Dimensions()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3, 4] of Integer;
    begin
        Observer.Observe('len', Format(ArrayLen(A)));
        Observer.Observe('len_dim1', Format(ArrayLen(A, 1)));
        Observer.Observe('len_dim2', Format(ArrayLen(A, 2)));
        Observer.Expect('len', '12');
        Observer.Expect('len_dim1', '3');
        Observer.Expect('len_dim2', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Array_ArrayLen_Row()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3, 4] of Integer;
    begin
        Observer.Observe('len_row', Format(ArrayLen(A[2])));
        Observer.Expect('len_row', '4');
        Observer.Verify();
    end;
}
