// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-code-coverage
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74571 "LT P167 Method Id A"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure RecordedProc()
    begin
        if StrLen('x') = 0 then
            Error('unreachable');
    end;

    [Test]
    procedure OtherRecordedProc()
    begin
        if StrLen('x') = 0 then
            Error('unreachable');
    end;
}
