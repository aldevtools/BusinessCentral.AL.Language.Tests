// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-arrays
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73923
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "A chained index of a multi-dimensional array, and a row of one" (Page extension overload of a base page procedure ...): the chained form A[x] [y]
// Facts: A[2] [3] := 7 and a read of A[2] [3] on array[3, 4] of Integer and of Text, compared with A[2, 3]; a chained read of a cell never written
// BC versions: 29 (27 and 28 by CI)
// Note for the lead: if the chained form does not compile on BC, drop this file (that is the observation: a must-not-compile case).

codeunit 73923 "LT PnF Array Chained"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Array_ChainedIndex_Integer()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3, 4] of Integer;
    begin
        A[2] [3] := 7;
        Observer.Observe('comma_form', Format(A[2, 3]));
        Observer.Observe('chained_read', Format(A[2] [3]));
        Observer.Observe('other_cell', Format(A[3, 2]));
        A[3] [2] := 9;
        Observer.Observe('swapped_cell_comma', Format(A[3, 2]));
        Observer.Observe('first_cell', Format(A[1, 1]));
        A[2, 4] := 5;
        Observer.Observe('written_by_comma_read_chained', Format(A[2] [4]));
        Observer.Expect('comma_form', '7');
        Observer.Expect('chained_read', '7');
        Observer.Expect('other_cell', '0');
        Observer.Expect('swapped_cell_comma', '9');
        Observer.Expect('first_cell', '0');
        Observer.Expect('written_by_comma_read_chained', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Array_ChainedIndex_Text()
    var
        Observer: Codeunit "Probe Observer";
        A: array[2, 2] of Text;
    begin
        A[1] [2] := 'x';
        Observer.Observe('comma_form', A[1, 2]);
        Observer.Observe('empty_cell', A[2, 1]);
        Observer.Observe('chained_read', A[1] [2]);
        Observer.Expect('comma_form', 'x');
        Observer.Expect('empty_cell', '');
        Observer.Expect('chained_read', 'x');
        Observer.Verify();
    end;
}
