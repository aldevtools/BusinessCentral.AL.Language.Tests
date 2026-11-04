// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonarray/jsonarray-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74413
// Probe: written against BC 29 (runtime 16); P88; the values are measured later on a local BC 29 service tier.
// Facts: UNSURE the members exist: JsonArray.GetChar, JsonArray.GetTime
// BC versions: 29

codeunit 74413 "LT P88 Array GetChar Time"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure Array_GetChar_GetTime()
    var
        A: JsonArray;
        Ch: Char;
        Ti: Time;
    begin
        Ch := 65;
        Ti := 143015T;
        A.Add(Ch);
        A.Add(Ti);
        A.Add('B');
        A.Add(7);
        Observer.Observe('text', Format(A.GetChar(0)));
        Observer.Observe('char_from_text', Format(A.GetChar(2)));
        Observer.Observe('time', Format(A.GetTime(1), 0, 9));
        Observer.Observe('char_from_int', Format(A.GetChar(3)));
        Observer.Observe('char_from_int', 'no error');
        asserterror Observer.Observe('char_oob', Format(A.GetChar(4)));
        Observer.ObserveError('char_oob');
        asserterror Observer.Observe('char_neg', Format(A.GetChar(-1)));
        Observer.ObserveError('char_neg');
        asserterror Observer.Observe('time_oob', Format(A.GetTime(9)));
        Observer.ObserveError('time_oob');
        asserterror Observer.Observe('time_from_text', Format(A.GetTime(2)));
        Observer.ObserveError('time_from_text');
        Observer.Expect('text', 'A');
        Observer.Expect('char_from_text', 'B');
        Observer.Expect('time', '14:30:15');
        Observer.Expect('char_from_int', '\u0007');
        Observer.Expect('char_from_int', 'no error');
        Observer.Expect('char_oob|text', 'Index out of bounds.');
        Observer.Expect('char_oob|code', 'IndexOutOfBounds');
        Observer.Expect('char_neg|text', 'Index out of bounds.');
        Observer.Expect('char_neg|code', 'IndexOutOfBounds');
        Observer.Expect('time_oob|text', 'Index out of bounds.');
        Observer.Expect('time_oob|code', 'IndexOutOfBounds');
        Observer.Expect('time_from_text|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavTime.');
        Observer.Expect('time_from_text|code', 'Conversion');
        Observer.Verify();
    end;
}
