// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), tables 70064/70065 (this file)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: error fixture tables
// BC versions: 29 (27 and 28 by CI)

table 70064 "LT ErT Rec"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
        field(3; Amount; Decimal)
        {
            trigger OnValidate()
            begin
                if Amount = -1 then
                    Error('Amount %1 is not allowed', Amount);
                if Amount < -1 then
                    FieldError(Amount, 'must not be below -1');
            end;
        }
        field(4; Code; Code[10]) { }
        field(5; Small; Integer)
        {
            MinValue = 1;
            MaxValue = 10;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    begin
        if Name = 'FailInsert' then
            Error('Insert refused for %1', Id);
    end;

    trigger OnModify()
    begin
        if Name = 'FailModify' then
            Error('Modify refused for %1', Id);
    end;

    trigger OnDelete()
    begin
        if Name = 'FailDelete' then
            Error('Delete refused for %1', Id);
    end;
}

table 70065 "LT ErT Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Note; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 70066 "LT ErT Fixture Check"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TablesAreEmptyAfterDeleteAll()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT ErT Rec";
        Log: Record "LT ErT Log";
    begin
        Rec.DeleteAll();
        Log.DeleteAll();
        Observer.Observe('recCount', Format(Rec.Count()));
        Observer.Observe('logCount', Format(Log.Count()));
        Observer.Expect('recCount', '0');
        Observer.Expect('logCount', '0');
        Observer.Verify();
    end;
}
