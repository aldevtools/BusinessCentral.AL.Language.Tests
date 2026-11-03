// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74008
// Probe: written against BC 29 (P95 draft; observation only, the lead measures the facts)
// Facts: Clear on a single array element leaves the others
// BC versions: 29
// Tag: P95

codeunit 74008 "LT P95 Clear Array Element"
{
    Subtype = Test;
    TestPermissions = Disabled;


    [Test]
    procedure ClearArrayElement()
    var
        Observer: Codeunit "Probe Observer";
        Ai: array[3] of Integer;
        At: array[2] of Text;
    begin
        Ai[1] := 1; Ai[2] := 2; Ai[3] := 3;
        Clear(Ai[2]);
        Observer.Observe('elements', Format(Ai[1]) + '|' + Format(Ai[2]) + '|' + Format(Ai[3]));
        At[1] := 'a'; At[2] := 'b';
        Clear(At[1]);
        Observer.Observe('text_elements', '[' + At[1] + '][' + At[2] + ']');
        asserterror Clear(Ai[4]);
        Observer.ObserveError('out_of_range');
        asserterror Clear(Ai[0]);
        Observer.ObserveError('zero_index');

        Observer.Expect('elements', '1|0|3');
        Observer.Expect('text_elements', '[][b]');
        Observer.Expect('out_of_range|text', 'Index out of bounds.');
        Observer.Expect('out_of_range|code', 'IndexOutOfBounds');
        Observer.Expect('zero_index|text', 'Index out of bounds.');
        Observer.Expect('zero_index|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

}
