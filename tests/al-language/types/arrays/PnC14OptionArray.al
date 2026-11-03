// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-arrays
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: Option arrays "Kinds::Purchase with Kinds: array[5] of Option ... declare one, read an untouched element with Format, assign members, compare" (probe batch 4)
// BC versions: 29 (27 and 28 by CI)

codeunit 71121 "LT PnC Option Array"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure OptionArray_Indexed()
    var
        Observer: Codeunit "Probe Observer";
        Kinds: array[5] of Option "None",Released,FirmPlanned,Purchase;
        i: Integer;
    begin
        for i := 1 to 5 do begin
            Observer.Observe('untouched' + Format(i), Format(Kinds[i]) + '|' + Format(Kinds[i], 0, 2));
        end;
        Kinds[2] := Kinds[2]::Purchase;
        Kinds[3] := 2;
        Observer.Observe('assignedMember', Format(Kinds[2]));
        Observer.Observe('assignedInteger', Format(Kinds[3]));
        Observer.Observe('equalsMember', Format(Kinds[2] = Kinds[2]::Purchase));
        Observer.Observe('equalsOther', Format(Kinds[2] = Kinds[3]));
        Observer.Observe('compareGreater', Format(Kinds[2] > Kinds[3]));
        Observer.Observe('asInteger', Format(Kinds[2], 0, 2));
        Kinds[4] := Kinds[2];
        Observer.Observe('copied', Format(Kinds[4]));
        Clear(Kinds);
        Observer.Observe('afterClear', Format(Kinds[2]));
        Observer.Expect('untouched1', 'None|0');
        Observer.Expect('untouched2', 'None|0');
        Observer.Expect('untouched3', 'None|0');
        Observer.Expect('untouched4', 'None|0');
        Observer.Expect('untouched5', 'None|0');
        Observer.Expect('assignedMember', 'Purchase');
        Observer.Expect('assignedInteger', 'FirmPlanned');
        Observer.Expect('equalsMember', 'Yes');
        Observer.Expect('equalsOther', 'No');
        Observer.Expect('compareGreater', 'Yes');
        Observer.Expect('asInteger', '3');
        Observer.Expect('copied', 'Purchase');
        Observer.Expect('afterClear', 'None');
        Observer.Verify();
    end;

    [Test]
    procedure OptionArray_Evaluate_And_Out_Of_Range()
    var
        Observer: Codeunit "Probe Observer";
        Kinds: array[3] of Option "None",Released,FirmPlanned,Purchase;
        ok: Boolean;
    begin
        ok := Evaluate(Kinds[1], 'FirmPlanned');
        Observer.Observe('evaluateName', Format(ok) + '|' + Format(Kinds[1]));
        ok := Evaluate(Kinds[1], 'nothing');
        Observer.Observe('evaluateUnknown', Format(ok) + '|' + Format(Kinds[1]));
        Kinds[2] := 9;
        Observer.Observe('assignOutOfRange', 'no error');
        Observer.Observe('elementAfterError', Format(Kinds[2]));
        asserterror Kinds[4] := 1;
        Observer.ObserveError('indexOutOfRange');
        asserterror Kinds[0] := 1;
        Observer.ObserveError('indexZero');
        Observer.Expect('evaluateName', 'Yes|FirmPlanned');
        Observer.Expect('evaluateUnknown', 'No|FirmPlanned');
        Observer.Expect('assignOutOfRange', 'no error');
        Observer.Expect('elementAfterError', '9');
        Observer.Expect('indexOutOfRange|text', 'Index out of bounds.');
        Observer.Expect('indexOutOfRange|code', 'IndexOutOfBounds');
        Observer.Expect('indexZero|text', 'Index out of bounds.');
        Observer.Expect('indexZero|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;
}

codeunit 71124 "LT PnC Option Array Name"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure OptionArray_MemberOnArrayName()
    var
        Observer: Codeunit "Probe Observer";
        Kinds: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        Kinds[1] := Kinds::Purchase;
        Observer.Observe('assigned', Format(Kinds[1]));
        Observer.Observe('compare', Format(Kinds[1] = Kinds::Purchase));
        Observer.Observe('member', Format(Kinds::Released));
        Observer.Expect('assigned', 'Purchase');
        Observer.Expect('compare', 'Yes');
        Observer.Expect('member', '1');
        Observer.Verify();
    end;
}
