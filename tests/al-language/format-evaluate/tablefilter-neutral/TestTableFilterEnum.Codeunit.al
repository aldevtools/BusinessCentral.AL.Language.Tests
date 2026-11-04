// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: standalone issue example. Real-BC observations are recorded separately.
// Fixtures: FMT Filter Holder, FMT Filter Target, FMT Cost Kind, FMT Config Kind.
// BC versions: 27.5, 28.5, 29.0. Runtime: 16.0.
codeunit 69000 "FMT Filter Enum Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        FixtureCleanup: Codeunit ALTFixtureCleanup;
    [Test]
    procedure Evaluate_TableFilter_NonDefaultEnumText_IsPreserved()
    var
        Holder: Record "FMT Filter Holder";
    begin
        Initialize();
        Evaluate(Holder."Stored Filter", 'FMT Filter Target: Cost Type=Setting');
        if StrPos(Format(Holder."Stored Filter"), 'Setting') = 0 then
            Error('Expected the non-default filter value to survive Evaluate and Format. Actual: %1', Format(Holder."Stored Filter"));
    end;
    local procedure Initialize()
    var
        Holder: Record "FMT Filter Holder";
        Target: Record "FMT Filter Target";
    begin
        FixtureCleanup.Initialize();
        Holder.DeleteAll();
        Target.DeleteAll();
    end;
}
