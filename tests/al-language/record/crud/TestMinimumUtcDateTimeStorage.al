// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonvalue/jsonvalue-asdatetime-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: behavior-defining local objects
// BC versions: 27.5+

// local object: this fixture defines the table or report shape under test.
table 52036 "Runtime Repro Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Stamp; DateTime) { }
        field(3; Status; Code[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonvalue/jsonvalue-asdatetime-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: Runtime Repro Row
// BC versions: 27.5+
codeunit 52037 "Minimum UTC Repro Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Record_Insert_JsonMinimumUtcDateTime_ReadsBackBlank()
    var
        Buffer: Record "Runtime Repro Row" temporary;
        Row: Record "Runtime Repro Row";
        Payload: JsonObject;
        Token: JsonToken;
    begin
        Initialize();

        Payload.ReadFrom('{"stamp":"0001-01-01T00:00:00Z"}');
        Payload.Get('stamp', Token);
        Buffer.Id := 7;
        Buffer.Stamp := Token.AsValue().AsDateTime();
        Buffer.Insert();

        Row.TransferFields(Buffer);
        Row.Insert();
        Clear(Row);
        Row.Get(7);
        if StrSubstNo('%1|%2', Row.Id, Format(Row.Stamp, 0, 9)) <> '7|' then
            Error('Expected row 7 with a blank DateTime. Got row %1 with DateTime %2.',
                Row.Id, Format(Row.Stamp, 0, 9));
    end;

    local procedure Initialize()
    var
        Row: Record "Runtime Repro Row";
    begin
        Row.DeleteAll();
    end;
}
