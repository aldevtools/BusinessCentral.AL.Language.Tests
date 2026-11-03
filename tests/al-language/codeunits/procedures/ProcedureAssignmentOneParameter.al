// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-methods
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunits 70365 and 70366
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: `SetFlag := true` where SetFlag is a procedure with ONE value parameter: does it compile, and is it the same as SetFlag(true) (a log inside the procedure shows the call and the value).
// Risky: probably does not compile (then the lead turns the file into a must-not-compile case); own file.
// BC versions: 29 (27 and 28 by CI)

codeunit 70365 "LT Assign Target One"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure SetFlag(NewValue: Boolean)
    begin
        Log += 'SetFlag(' + Format(NewValue) + ');';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;

    procedure Reset()
    begin
        Log := '';
    end;
}

codeunit 70366 "LT Assign One"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SetFlagCalled: Text;

    procedure SetHideWarning(NewValue: Boolean)
    begin
        SetFlagCalled += 'SetHideWarning(' + Format(NewValue) + ');';
    end;

    [Test]
    procedure AssignToProcedure_OneParameter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetFlagCalled := '';
        SetHideWarning := true;
        Observer.Observe('log after assignment', SetFlagCalled);
        SetHideWarning(true);
        Observer.Observe('log after call', SetFlagCalled);
        SetHideWarning := false;
        Observer.Observe('log after second assignment', SetFlagCalled);
        Observer.Expect('log after assignment', 'SetHideWarning(Yes);');
        Observer.Expect('log after call', 'SetHideWarning(Yes);SetHideWarning(Yes);');
        Observer.Expect('log after second assignment', 'SetHideWarning(Yes);SetHideWarning(Yes);SetHideWarning(No);');
        Observer.Verify();
    end;
}
