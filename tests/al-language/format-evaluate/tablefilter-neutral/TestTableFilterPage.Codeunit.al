// BC versions: 27.5, 28.5, 29.0.
// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-getfilter-method
// Scope: Cloud-compatible public API; expectations are verified by the real BC matrix.
// Fixtures: ALT TableFilter Holder and FMT Filter Target. BC versions: 27.5, 28.5, 29.0.
codeunit 69001 "FMT Filter Page Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        FixtureCleanup: Codeunit ALTFixtureCleanup;
    [Test]
    procedure TableFilter_PageParsing_AppliesEmployeeExclusion()
    var
        Holder: Record "ALT TableFilter Holder";
        Target: Record "FMT Filter Target";
        FilterFields: Record "Table Filter" temporary;
        FilterPage: Page "Table Filter";
        TargetRef: RecordRef;
        TargetField: FieldRef;
    begin
        Initialize();
        Evaluate(Holder."Filter Value", 'FMT Filter Target: Employee No.=<>XYZ');
        FilterPage.SetSourceTable(Format(Holder."Filter Value"), Database::"FMT Filter Target", Target.TableCaption());
        FilterPage.GetFilterFieldsList(FilterFields);
        TargetRef.Open(Database::"FMT Filter Target", true);
        if FilterFields.FindSet() then
            repeat
                TargetField := TargetRef.Field(FilterFields."Field Number");
                TargetField.SetFilter(FilterFields."Field Filter");
            until FilterFields.Next() = 0;
        TargetField := TargetRef.Field(Target.FieldNo("Employee No."));
        if TargetField.GetFilter() <> '<>XYZ' then
            Error('Expected employee exclusion <>XYZ, got %1.', TargetField.GetFilter());
        TargetRef.Close();
    end;
    local procedure Initialize()
    var
        Holder: Record "ALT TableFilter Holder";
        Target: Record "FMT Filter Target";
    begin
        FixtureCleanup.Initialize();
        Target.DeleteAll();
    end;
}
