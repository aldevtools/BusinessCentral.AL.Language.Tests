// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier produced. Other BC versions were not measured.
//
// A query column named Open next to the method Query.Open():
// - Q.Open() opens the query and Q.Open (no parentheses) after Read() is the column value (20); the column is also read as Q.Id; SetRange(Open, 20), SetFilter(Open, '>=10')
//   and GetFilter(Open) address the column;
// A bare column name inside the query's OWN procedures: before Read() it raises "You have not yet retrieved a data row for this query. The value for column 'Id' can only be
// accessed after a row is retrieved with a call to the READ function."; after a Read() that answered true it is the current row (also as this.Id); after the Read() that answered
// false (past the last row) it raises the same text again.
// Fixtures used: self-contained tables 69541, queries 69541 and 69542, codeunit 69543
// BC versions: 27.5
// Added by writer BV (2026-10-19, Windows check 3 item AZ): a bare FILTER element name (KindF, on a Code field) read inside the query's own procedure, with no
// filter set and the query not open, raises the same QueryNoDataSet error naming 'KindF' (Windows BC 27.5 and 29.0 and the Linux tiers; table 83752, query 83753,
// test FilterElement_InQueryProcedure_NoFilter). Not asserted: after SetRange(KindF, ...) the same read raises an uncatchable 'Unexpected CLR exception thrown.:
// System.InvalidCastException: Unable to cast object of type ''Microsoft.Dynamics.Nav.Runtime.NavInteger'' to type ''Microsoft.Dynamics.Nav.Runtime.NavCode''.'
// on real BC (Windows 27.5 and 29.0) too; neither a TryFunction nor asserterror catches it, so no passing test can show it.

table 69541 "PR Query Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Open; Integer) { }
        field(3; Name; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

query 69541 "PR Query Open Column"
{
    elements
    {
        dataitem(Row; "PR Query Row")
        {
            column(Id; Id) { }
            column(Open; Open) { }
            column(Name; Name) { }
        }
    }

    procedure PeekId(): Integer
    begin
        exit(Id);
    end;

    procedure PeekName(): Text
    begin
        exit(Name);
    end;

    procedure PeekOpenColumn(): Integer
    begin
        exit(Open);
    end;
}

query 69542 "PR Query Bare Column"
{
    elements
    {
        dataitem(Row; "PR Query Row")
        {
            column(Id; Id) { }
            column(Name; Name) { }
        }
    }

    procedure PeekId(): Integer
    begin
        exit(Id);
    end;

    procedure PeekName(): Text
    begin
        exit(Name);
    end;

    procedure Both(): Text
    begin
        exit(Format(Id) + '/' + Name);
    end;

    procedure PeekThis(): Integer
    begin
        exit(this.Id);
    end;
}

table 83752 "LT BV Q Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(5; Kind; Code[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

query 83753 "LT BV Q Filter Proc"
{
    elements
    {
        dataitem(Row; "LT BV Q Row")
        {
            filter(KindF; Kind) { }
            column(Id; Id) { }
        }
    }

    procedure ReadKindF(): Text
    begin
        exit('[' + Format(KindF) + ']');
    end;
}

codeunit 69543 "PR Query Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "PR Query Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Open := 10;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Open := 20;
        Row.Name := 'two';
        Row.Insert();
    end;

    [TryFunction]
    local procedure TryPeek(var Q: Query "PR Query Bare Column"; var Result: Text)
    begin
        Result := Format(Q.PeekId()) + '/' + Q.PeekName() + '/' + Q.Both() + '/' + Format(Q.PeekThis());
    end;

    local procedure PeekOutcome(var Q: Query "PR Query Bare Column"): Text
    var
        Result: Text;
    begin
        if TryPeek(Q, Result) then
            exit('ok:' + Result);
        exit('error:' + GetLastErrorText());
    end;

    [Test]
    procedure BareColumn_InQueryProcedure_BeforeDuringAfter()
    var
        Q: Query "PR Query Bare Column";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Q.Open();
        Observer.Observe('before_read', PeekOutcome(Q));
        Observer.Observe('read_1', Format(Q.Read()));
        Observer.Observe('first_row_from_outside', Format(Q.Id) + '/' + Q.Name);
        Observer.Observe('first_row_in_procedures', PeekOutcome(Q));
        Observer.Observe('read_2', Format(Q.Read()));
        Observer.Observe('second_row_in_procedures', PeekOutcome(Q));
        Observer.Observe('read_3', Format(Q.Read()));
        Observer.Observe('after_last_row_in_procedures', PeekOutcome(Q));
        Q.Close();
        Observer.Observe('after_close_in_procedures', PeekOutcome(Q));
        Observer.Expect('before_read', 'error:You have not yet retrieved a data row for this query. The value for column ''Id'' can only be accessed after a row is retrieved with a call to the READ function.');
        Observer.Expect('read_1', 'Yes');
        Observer.Expect('first_row_from_outside', '1/one');
        Observer.Expect('first_row_in_procedures', 'ok:1/one/1/one/1');
        Observer.Expect('read_2', 'Yes');
        Observer.Expect('second_row_in_procedures', 'ok:2/two/2/two/2');
        Observer.Expect('read_3', 'No');
        Observer.Expect('after_last_row_in_procedures', 'error:You have not yet retrieved a data row for this query. The value for column ''Id'' can only be accessed after a row is retrieved with a call to the READ function.');
        Observer.Expect('after_close_in_procedures', 'error:You have not yet retrieved a data row for this query. The value for column ''Id'' can only be accessed after a row is retrieved with a call to the READ function.');
        Observer.Verify();
    end;

    [Test]
    procedure ColumnNamedOpen_MethodAndColumn()
    var
        Q: Query "PR Query Open Column";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Q.SetRange(Open, 20);
        Q.Open();
        Observer.Observe('read', Format(Q.Read()));
        Observer.Observe('id', Format(Q.Id));
        Observer.Observe('open_column_value', Format(Q.Open));
        Observer.Observe('peek_open_column', Format(Q.PeekOpenColumn()));
        Observer.Observe('peek_id', Format(Q.PeekId()));
        Observer.Observe('second_read', Format(Q.Read()));
        Q.Close();
        Observer.Expect('read', 'Yes');
        Observer.Expect('id', '2');
        Observer.Expect('open_column_value', '20');
        Observer.Expect('peek_open_column', '20');
        Observer.Expect('peek_id', '2');
        Observer.Expect('second_read', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ColumnNamedOpen_FilterAndReopen()
    var
        Q: Query "PR Query Open Column";
        Count: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Q.Open();
        while Q.Read() do
            Count += 1;
        Observer.Observe('unfiltered_rows', Format(Count));
        Q.Close();
        Q.SetRange(Open, 10);
        Q.Open();
        Count := 0;
        while Q.Read() do
            Count += 1;
        Observer.Observe('filtered_rows', Format(Count));
        Observer.Observe('getfilter_open', Q.GetFilter(Open));
        Q.Close();
        Q.SetFilter(Open, '>=10');
        Q.Open();
        Count := 0;
        while Q.Read() do
            Count += Q.Open;
        Observer.Observe('sum_of_open_column', Format(Count));
        Q.Close();
        Observer.Expect('unfiltered_rows', '2');
        Observer.Expect('filtered_rows', '1');
        Observer.Expect('getfilter_open', '10');
        Observer.Expect('sum_of_open_column', '30');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadKindF(var Q: Query "LT BV Q Filter Proc"; var R: Text)
    begin
        R := Q.ReadKindF();
    end;

    // Windows check 3 (BC 27.5 and 29.0) gave exactly these values.
    [Test]
    procedure FilterElement_InQueryProcedure_NoFilter()
    var
        Q: Query "LT BV Q Filter Proc";
        Row: Record "LT BV Q Row";
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Kind := 'K1';
        Row.Insert();
        Row.Id := 2;
        Row.Kind := 'K2';
        Row.Insert();
        R := '-';
        ClearLastError();
        Observer.Observe('ok', Format(TryReadKindF(Q, R)));
        Observer.Observe('result', R);
        Observer.ObserveError('read');
        Observer.Expect('ok', 'No');
        Observer.Expect('result', '-');
        Observer.Expect('read|text', 'You have not yet retrieved a data row for this query. The value for column ''KindF'' can only be accessed after a row is retrieved with a call to the READ function.');
        Observer.Expect('read|code', 'QueryNoDataSet');
        Observer.Verify();
    end;
}
