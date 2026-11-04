// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-temporarypath-method
// Scope: in-scope (OnPrem app only: System.TemporaryPath)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; codeunit 61238
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: none
//
// TemporaryPath shape only (non-empty, ends with a separator, stable between calls, no write).
// BC versions: 29 (27 and 28 by CI)
codeunit 61238 "LT P109 TemporaryPath"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P109_TemporaryPath_Shape()
    var
        Observer: Codeunit "Probe Observer";
        Path: Text;
    begin
        Path := TemporaryPath();
        Observer.Observe('not_blank', Format(Path <> ''));
        Observer.Observe('stable', Format(Path = TemporaryPath()));
        Observer.Observe('last_char_is_separator', Format(CopyStr(Path, StrLen(Path), 1) in ['/', '\']));
        Observer.Observe('length_gt_1', Format(StrLen(Path) > 1));
        Observer.Observe('is_rooted', Format(CopyStr(Path, 1, 1) in ['/', '\']) + '|' + Format(Path.Contains(':')));
        Observer.Expect('not_blank', 'Yes');
        Observer.Expect('stable', 'Yes');
        Observer.Expect('last_char_is_separator', 'Yes');
        Observer.Expect('length_gt_1', 'Yes');
        Observer.Expect('is_rooted', 'Yes|No');
        Observer.Verify();
    end;
}
