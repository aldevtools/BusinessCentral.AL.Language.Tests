// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 73582, query 73583, test codeunit 73584
// Probe: written against BC on CI (no local container); every literal asserted below is what the CI tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a query opened and read until Read returns false. Then SetRange on a column followed by Open and Read again; Open again without a new filter;
//   Open twice after the last row; SetRange after the last row without Open. For contrast: Open twice while rows are left, and SetRange while rows are left.
//   Each step records whether it raised (and the error text) and the rows read.
// BC versions: 27, 28, 29 by CI

table 73582 "LT QL Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Code[10]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

query 73583 "LT QL Rows"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT QL Row")
        {
            column(Id; Id) { }
            column(Grp; Grp) { }
        }
    }
}

codeunit 73584 "LT Query Closed After Last Row"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";
        Q: Query "LT QL Rows";
        Rows: Text;

    local procedure Seed()
    var
        R: Record "LT QL Row";
    begin
        R.DeleteAll();
        R.Id := 1; R.Grp := 'A'; R.Insert();
        R.Id := 2; R.Grp := 'A'; R.Insert();
        R.Id := 3; R.Grp := 'B'; R.Insert();
        Clear(Q);
    end;

    [TryFunction]
    local procedure TryOpen()
    begin
        Q.Open();
    end;

    [TryFunction]
    local procedure TryRange(Value: Text)
    begin
        Q.SetRange(Grp, Value);
    end;

    [TryFunction]
    local procedure TryReadAll()
    begin
        Rows := '';
        while Q.Read() do
            Rows += Format(Q.Id) + ',';
    end;

    [TryFunction]
    local procedure TryReadOne()
    begin
        Rows := '';
        if Q.Read() then
            Rows := Format(Q.Id);
    end;

    local procedure Step(Name: Text; Ok: Boolean)
    begin
        if Ok then
            Obs.Observe(Name, 'ok')
        else begin
            Obs.Observe(Name, GetLastErrorText());
            ClearLastError();
        end;
    end;

    local procedure ReadAll(Name: Text)
    begin
        Step(Name, TryReadAll());
        Obs.Observe(Name + '.rows', Rows);
    end;

    [Test]
    procedure Query_AfterLastRow_SetRangeThenOpen()
    begin
        Seed();
        Step('open1', TryOpen());
        ReadAll('read1');
        Step('range', TryRange('B'));
        Step('open2', TryOpen());
        ReadAll('read2');
        Obs.Expect('open1', 'ok');
        Obs.Expect('read1', 'ok');
        Obs.Expect('read1.rows', '1,2,3,');
        Obs.Expect('range', 'ok');
        Obs.Expect('open2', 'ok');
        Obs.Expect('read2', 'ok');
        Obs.Expect('read2.rows', '3,');
        Obs.Verify();
    end;

    [Test]
    procedure Query_AfterLastRow_OpenAgainNoFilter()
    begin
        Seed();
        Step('open1', TryOpen());
        ReadAll('read1');
        Step('open2', TryOpen());
        ReadAll('read2');
        Obs.Expect('open1', 'ok');
        Obs.Expect('read1', 'ok');
        Obs.Expect('read1.rows', '1,2,3,');
        Obs.Expect('open2', 'ok');
        Obs.Expect('read2', 'ok');
        Obs.Expect('read2.rows', '1,2,3,');
        Obs.Verify();
    end;

    [Test]
    procedure Query_AfterLastRow_OpenTwice()
    begin
        Seed();
        Step('open1', TryOpen());
        ReadAll('read1');
        Step('open2', TryOpen());
        Step('open3', TryOpen());
        ReadAll('read3');
        Obs.Expect('open1', 'ok');
        Obs.Expect('read1', 'ok');
        Obs.Expect('read1.rows', '1,2,3,');
        Obs.Expect('open2', 'ok');
        Obs.Expect('open3', 'ok');
        Obs.Expect('read3', 'ok');
        Obs.Expect('read3.rows', '1,2,3,');
        Obs.Verify();
    end;

    [Test]
    procedure Query_AfterLastRow_SetRangeWithoutOpen()
    begin
        Seed();
        Step('open1', TryOpen());
        ReadAll('read1');
        Step('range', TryRange('A'));
        ReadAll('read2');
        Obs.Expect('open1', 'ok');
        Obs.Expect('read1', 'ok');
        Obs.Expect('read1.rows', '1,2,3,');
        Obs.Expect('range', 'ok');
        Obs.Expect('read2', 'The READ function is called on a query after query metadata has been changed by one of the following: SETFILTER, SETRANGE, SECURITYFILTERING, or TOPNUMBEROFROWS. After metadata changes, you must reopen the query by calling the OPEN function before calling the READ function.');
        Obs.Expect('read2.rows', '');
        Obs.Verify();
    end;

    [Test]
    procedure Query_RowsLeft_OpenAgainAndSetRange()
    begin
        Seed();
        Step('open1', TryOpen());
        Step('readone', TryReadOne());
        Obs.Observe('readone.rows', Rows);
        Step('open2', TryOpen());
        Step('range', TryRange('B'));
        Step('open3', TryOpen());
        ReadAll('read3');
        Obs.Expect('open1', 'ok');
        Obs.Expect('readone', 'ok');
        Obs.Expect('readone.rows', '1');
        Obs.Expect('open2', 'ok');
        Obs.Expect('range', 'ok');
        Obs.Expect('open3', 'ok');
        Obs.Expect('read3', 'ok');
        Obs.Expect('read3.rows', '3,');
        Obs.Verify();
    end;
}
