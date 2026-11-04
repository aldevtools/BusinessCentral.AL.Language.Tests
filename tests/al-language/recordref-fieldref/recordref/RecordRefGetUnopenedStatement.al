// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-get-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: RecordRef.Get(RecordId) on a RecordRef that was never opened with the result NOT used (a statement call), for an existing and a missing row, and the state afterwards (assumption recordref-get-unopened widened); recordref/W4RecordRefGetUnopened.al:59-90 pins the call with the result used.
// BC versions: 29 (27 and 28 by CI)

table 70664 "LT RRGet Row"
{
    fields
    {
        field(1; "No."; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 70665 "LT RRGet Unopened Stmt"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT RRGet Row";
    begin
        Row.DeleteAll();
        Row."No." := 1;
        Row.Name := 'one';
        Row.Insert();
    end;

    local procedure IdOf(No: Integer): RecordId
    var
        Row: Record "LT RRGet Row";
    begin
        Row."No." := No;
        exit(Row.RecordId());
    end;

    [Test]
    procedure Get_StatementExistingRow_Result()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        Seed();
        RR.Get(IdOf(1));
        Observer.Observe('number', Format(RR.Number()));
        Observer.Observe('name_field', Format(RR.Field(2).Value()));
        Observer.Observe('count', Format(RR.Count()));
        Observer.Expect('number', '70664');
        Observer.Expect('name_field', 'one');
        Observer.Expect('count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Get_StatementMissingRow_Result()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        Seed();
        asserterror RR.Get(IdOf(99));
        Observer.ObserveError('get_missing');
        Observer.Observe('number_after', Format(RR.Number()));
        Observer.Expect('get_missing|text', 'The LT RRGet Row does not exist. Identification fields and values: No.=''99''');
        Observer.Expect('get_missing|code', 'DB:RecordNotFound');
        Observer.Expect('number_after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Get_ResultUsedThenOpen_Result()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Id: RecordId;
    begin
        Seed();
        Id := IdOf(1);
        Observer.Observe('get_result', Format(RR.Get(Id)));
        Observer.Observe('number', Format(RR.Number()));
        Observer.Observe('is_temporary', Format(RR.IsTemporary()));
        Observer.Observe('second_get_result', Format(RR.Get(IdOf(99))));
        Observer.Observe('number_after_missing', Format(RR.Number()));
        Observer.Expect('get_result', 'Yes');
        Observer.Expect('number', '70664');
        Observer.Expect('is_temporary', 'No');
        Observer.Expect('second_get_result', 'No');
        Observer.Expect('number_after_missing', '70664');
        Observer.Verify();
    end;
}
