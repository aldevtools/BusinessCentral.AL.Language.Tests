// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-get-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained tables 73882 and 73883, codeunit 73884
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "Record.Get(RecordId)" (Tests-SCM round 2)
// Facts: Record.Get(RecordId) on an existing row, on a missing row (result used and unused), with a RecordId of another table, with an empty RecordId and with a RecordId whose key has another shape
// BC versions: 29 (27 and 28 by CI)

table 73882 "LT PnF GR One"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 73883 "LT PnF GR Two"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

codeunit 73884 "LT PnF Get RecordId"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        One: Record "LT PnF GR One";
        Two: Record "LT PnF GR Two";
    begin
        One.DeleteAll();
        Two.DeleteAll();
        One.Id := 1;
        One.Name := 'one';
        One.Insert();
        One.Id := 2;
        One.Name := 'two';
        One.Insert();
        Two.Code := 'X';
        Two.Name := 'ex';
        Two.Insert();
    end;

    [Test]
    procedure GetRecordId_Existing()
    var
        Observer: Codeunit "Probe Observer";
        One: Record "LT PnF GR One";
        Probe: Record "LT PnF GR One";
        Id: RecordId;
    begin
        Seed();
        One.Get(2);
        Id := One.RecordId();
        Observer.Observe('found', Format(Probe.Get(Id)));
        Observer.Observe('id', Format(Probe.Id));
        Observer.Observe('name', Probe.Name);
        Clear(Probe);
        Probe.Get(Id);
        Observer.Observe('statement_name', Probe.Name);
        Observer.Expect('found', 'Yes');
        Observer.Expect('id', '2');
        Observer.Expect('name', 'two');
        Observer.Expect('statement_name', 'two');
        Observer.Verify();
    end;

    [Test]
    procedure GetRecordId_Missing()
    var
        Observer: Codeunit "Probe Observer";
        One: Record "LT PnF GR One";
        Probe: Record "LT PnF GR One";
        Id: RecordId;
    begin
        Seed();
        One.Get(2);
        Id := One.RecordId();
        One.Delete();
        Observer.Observe('result_used', Format(Probe.Get(Id)));
        Observer.Observe('id_after_failed', Format(Probe.Id));
        asserterror Probe.Get(Id);
        Observer.ObserveError('result_unused');
        Observer.Expect('result_used', 'No');
        Observer.Expect('id_after_failed', '0');
        Observer.Expect('result_unused|text', 'The LT PnF GR One does not exist. Identification fields and values: Id=''2''');
        Observer.Expect('result_unused|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure GetRecordId_OtherTable()
    var
        Observer: Codeunit "Probe Observer";
        One: Record "LT PnF GR One";
        Two: Record "LT PnF GR Two";
        Id: RecordId;
    begin
        Seed();
        Two.Get('X');
        Id := Two.RecordId();
        Observer.Observe('other_table_used', Format(TryGetUsed(One, Id)));
        Observer.ObserveError('other_table_used_error');
        Observer.Expect('other_table_used', 'Yes');
        Observer.Expect('other_table_used_error|text', '');
        Observer.Expect('other_table_used_error|code', '');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryGetUsedFn(var One: Record "LT PnF GR One"; Id: RecordId)
    begin
        if One.Get(Id) then;
    end;

    local procedure TryGetUsed(var One: Record "LT PnF GR One"; Id: RecordId): Boolean
    begin
        exit(TryGetUsedFn(One, Id));
    end;

    [Test]
    procedure GetRecordId_EmptyRecordId()
    var
        Observer: Codeunit "Probe Observer";
        One: Record "LT PnF GR One";
        Id: RecordId;
    begin
        Seed();
        Observer.Observe('empty_used', Format(TryGetUsed(One, Id)));
        Observer.ObserveError('empty_used_error');
        Observer.Expect('empty_used', 'Yes');
        Observer.Expect('empty_used_error|text', '');
        Observer.Expect('empty_used_error|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure GetRecordId_KeepsFilters()
    var
        Observer: Codeunit "Probe Observer";
        One: Record "LT PnF GR One";
        Probe: Record "LT PnF GR One";
        Id: RecordId;
    begin
        Seed();
        One.Get(1);
        Id := One.RecordId();
        Probe.SetRange(Id, 2);
        Observer.Observe('found_outside_filter', Format(Probe.Get(Id)));
        Observer.Observe('filters', Probe.GetFilters());
        Observer.Observe('id', Format(Probe.Id));
        Observer.Expect('found_outside_filter', 'Yes');
        Observer.Expect('filters', 'Id: 2');
        Observer.Expect('id', '1');
        Observer.Verify();
    end;
}
