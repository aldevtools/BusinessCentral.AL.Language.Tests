// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), none
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: GetLastError ClearLastError
// BC versions: 29 (27 and 28 by CI)

codeunit 70070 "LT ErT LastError"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Raise(Txt: Text)
    begin
        Error(Txt);
    end;

    [Test]
    procedure LastErrorStartsEmptyAfterClear()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('text', GetLastErrorText());
        Observer.Observe('code', GetLastErrorCode());
        Observer.Expect('text', '');
        Observer.Expect('code', '');
        Observer.Verify();
    end;

    [Test]
    procedure LastErrorAfterAsserterror()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Raise('first');
        Observer.Observe('text', GetLastErrorText());
        Observer.Observe('code', GetLastErrorCode());
        asserterror Raise('second');
        Observer.Observe('text2', GetLastErrorText());
        ClearLastError();
        Observer.Observe('cleared', GetLastErrorText());
        Observer.Observe('clearedCode', GetLastErrorCode());
        Observer.Expect('text', 'first');
        Observer.Expect('code', 'Dialog');
        Observer.Expect('text2', 'second');
        Observer.Expect('cleared', '');
        Observer.Expect('clearedCode', '');
        Observer.Verify();
    end;

    [Test]
    procedure LastErrorReadTwice()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Raise('twice');
        Observer.Observe('a', GetLastErrorText());
        Observer.Observe('b', GetLastErrorText());
        Observer.Observe('codeA', GetLastErrorCode());
        Observer.Observe('codeB', GetLastErrorCode());
        Observer.Expect('a', 'twice');
        Observer.Expect('b', 'twice');
        Observer.Expect('codeA', 'Dialog');
        Observer.Expect('codeB', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure LastErrorKeptAcrossSuccessfulCall()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        asserterror Raise('kept');
        i := 1 + 1;
        Observer.Observe('text', GetLastErrorText());
        Observer.Observe('i', Format(i));
        Observer.Expect('text', 'kept');
        Observer.Expect('i', '2');
        Observer.Verify();
    end;

    [Test]
    procedure LastErrorCallStackNotEmpty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Raise('stack');
        Observer.Observe('stackNotEmpty', Format(StrLen(GetLastErrorCallStack()) > 0));
        ClearLastError();
        Observer.Observe('stackLenAfterClear', Format(StrLen(GetLastErrorCallStack())));
        Observer.Expect('stackNotEmpty', 'Yes');
        Observer.Expect('stackLenAfterClear', '0');
        Observer.Verify();
    end;

    [Test]
    procedure LastErrorObjectIsNotSet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Raise('no object');
        Observer.Observe('text', GetLastErrorText());
        Observer.Expect('text', 'no object');
        Observer.Verify();
    end;
}
