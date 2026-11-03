// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-applicationpath-method
// Scope: in-scope (OnPrem app only: System.ApplicationPath)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; codeunit 61239
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: none
//
// ApplicationPath shape only (outcome, non-empty, stable, separator); the value is the machine's.
// BC versions: 29 (27 and 28 by CI)
codeunit 61239 "LT P109 ApplicationPath"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryPath(var Path: Text)
    begin
        Path := ApplicationPath();
    end;

    [Test]
    procedure P109_ApplicationPath_Shape()
    var
        Observer: Codeunit "Probe Observer";
        Path: Text;
    begin
        Observer.Observe('call_ok', Format(TryPath(Path)));
        if Path <> '' then begin
            Observer.Observe('stable', Format(Path = ApplicationPath()));
            Observer.Observe('last_char_is_separator', Format(CopyStr(Path, StrLen(Path), 1) in ['/', '\']));
            Observer.Observe('is_rooted', Format(CopyStr(Path, 1, 1) in ['/', '\']) + '|' + Format(Path.Contains(':')));
        end else begin
            Observer.Observe('blank', 'true');
            Observer.Observe('error', GetLastErrorText());
        end;
        Observer.Expect('call_ok', 'Yes');
        Observer.Expect('stable', 'Yes');
        Observer.Expect('last_char_is_separator', 'Yes');
        Observer.Expect('is_rooted', 'Yes|No');
        Observer.Verify();
    end;
}
