// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: Cloud-compatible FlowField semantics.
// local object: this table declares the signed RecordId lookup under test.
table 69990 "REC Signed RecordId Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Target; RecordId) { }
        field(3; "Signed Target"; RecordId)
        {
            FieldClass = FlowField;
            CalcFormula = -lookup("REC Signed RecordId Row".Target where(Id = field(Id)));
        }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 69991 "REC Signed RecordId Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CalcFormula_SignedRecordIdLookup_ReturnsStoredTarget()
    var
        Row: Record "REC Signed RecordId Row";
        Target: Record "ALT Universal";
    begin
        Initialize();
        Target."Entry No." := 202;
        Target.Insert(false);
        Row.Id := 1;
        Row.Target := Target.RecordId();
        Row.Insert(false);
        Row.CalcFields("Signed Target");
        if Row."Signed Target" <> Target.RecordId() then
            Error('Expected the stored RecordId %1; actual %2.', Target.RecordId(), Row."Signed Target");
    end;

    local procedure Initialize()
    var
        Cleanup: Codeunit ALTFixtureCleanup;
        Row: Record "REC Signed RecordId Row";
    begin
        Cleanup.Initialize();
        Row.DeleteAll(false);
    end;
}
