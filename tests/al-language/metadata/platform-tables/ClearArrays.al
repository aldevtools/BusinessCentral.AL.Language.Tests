// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74007
// Probe: written against BC 29 (P95 draft; observation only, the lead measures the facts)
// Facts: Clear on arrays (System.Clear overload for arrays): all elements reset, 2-D arrays, array of text, of boolean, of code
// BC versions: 29
// Tag: P95

codeunit 74007 "LT P95 Clear Arrays"
{
    Subtype = Test;
    TestPermissions = Disabled;


    [Test]
    procedure ClearArrays()
    var
        Observer: Codeunit "Probe Observer";
        Ai: array[3] of Integer;
        At: array[3] of Text;
        Ab: array[3] of Boolean;
        Ac: array[3] of Code[10];
        Ad: array[3] of Date;
        A2: array[2, 3] of Integer;
        i: Integer;
    begin
        for i := 1 to 3 do begin
            Ai[i] := i * 10;
            At[i] := 'v' + Format(i);
            Ab[i] := true;
            Ac[i] := 'C';
            Ad[i] := DMY2Date(1, 1, 2020);
        end;
        A2[1, 1] := 1;
        A2[2, 3] := 6;
        Clear(Ai);
        Clear(At);
        Clear(Ab);
        Clear(Ac);
        Clear(Ad);
        Clear(A2);
        Observer.Observe('int', Format(Ai[1]) + Format(Ai[2]) + Format(Ai[3]));
        Observer.Observe('text', '[' + At[1] + At[2] + At[3] + ']');
        Observer.Observe('bool', Format(Ab[1]) + Format(Ab[2]) + Format(Ab[3]));
        Observer.Observe('code', '[' + Ac[1] + Ac[3] + ']');
        Observer.Observe('date', Format(Ad[1]) + '|' + Format(Ad[3]));
        Observer.Observe('two_dim', Format(A2[1, 1]) + Format(A2[2, 3]));
        Observer.Observe('dims', Format(ArrayLen(Ai)) + '|' + Format(ArrayLen(A2)) + '|' + Format(ArrayLen(A2, 2)));
        Clear(Ai[2]);

        Observer.Expect('int', '000');
        Observer.Expect('text', '[]');
        Observer.Expect('bool', 'NoNoNo');
        Observer.Expect('code', '[]');
        Observer.Expect('date', '|');
        Observer.Expect('two_dim', '00');
        Observer.Expect('dims', '3|6|3');
        Observer.Verify();
    end;

}
