// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-open-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); shared table 50015 "ALT Shape 15"; queries 71968, 71969, 71970; test codeunit 71971
// Probe: al-runner issue 7827. Observed in the corpus CI (BC on Linux, 27.5, 28.5 and 29.0, run of 2026-11-14); the values were the same on all
//   three versions and were turned into the Expect lines by script.
// Facts: a second Open on a query that was read from while rows were left, with no SetFilter or SetRange between (al-runner issue 7827).
//   What Read, a column read, Open, Close and SetFilter do right after that second Open; whether the second Open's return value
//   is true; whether OnBeforeOpen runs again; the same on a query with a Sum column and a filter set before the first Open
//   (the issue's own shape); and after two Reads instead of one.
//   Already pinned elsewhere: the second Open as a statement followed by SetRange and Open (QueryClosedAfterLastRow.al:162).
// Result: the second Open starts the query over: Read then returns every row from the first (1,2,3), also after two Reads, after a
//   third Open, and with rows written before the second Open (1,2,3,4). Open returns true. A column read right after the second Open
//   fails with QueryNoDataSet. Close after the second Open leaves nothing to read. SetFilter then Open reads only the filtered row.
//   OnBeforeOpen runs again on the second Open. The Sum query with a filter set before the first Open reads from its first row
//   again (A=1), and a next row follows.
// BC versions: 27, 28, 29 by CI

// local object: the query shape (plain columns) is part of the cell under test
query 71968 "QRY Reopen Rows"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "ALT Shape 15")
        {
            column(Id; Id) { }
            column(Grp; Grp) { }
        }
    }
}

// local object: the query shape (a Sum column and a filter element, the issue shape) is under test
query 71969 "QRY Reopen Sum"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "ALT Shape 15")
        {
            filter(IdFilter; Id) { }
            column(Grp; Grp) { }
            column(Total; Id) { Method = Sum; }
        }
    }
}

// local object: its OnBeforeOpen trigger is under test
query 71970 "QRY Reopen Before Open"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "ALT Shape 15")
        {
            column(Id; Id) { }
        }
    }

    trigger OnBeforeOpen()
    begin
        BeforeOpenCount += 1;
    end;

    var
        BeforeOpenCount: Integer;

    procedure Opens(): Integer
    begin
        exit(BeforeOpenCount);
    end;
}

codeunit 71971 "QRY Reopen Rows Left Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Q: Query "QRY Reopen Rows";

    local procedure Seed()
    var
        R: Record "ALT Shape 15";
    begin
        R.DeleteAll();
        R.Id := 1; R.Grp := 'A'; R.Insert();
        R.Id := 2; R.Grp := 'A'; R.Insert();
        R.Id := 3; R.Grp := 'B'; R.Insert();
        Clear(Q);
    end;

    local procedure OpenAndReadOne()
    begin
        Q.Open();
        Q.Read();
        Observer.Observe('first row', Format(Q.Id));
    end;

    [TryFunction]
    local procedure TryReadAll(var Rows: Text)
    begin
        Rows := '';
        while Q.Read() do
            Rows += Format(Q.Id) + ',';
    end;

    [TryFunction]
    local procedure TryColumn(var Value: Text)
    begin
        Value := Format(Q.Id);
    end;

    local procedure ObserveReadAll(Name: Text)
    var
        Rows: Text;
    begin
        if TryReadAll(Rows) then
            Observer.Observe(Name, Rows)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure RowsLeft_OpenStatement_ThenReadAll()
    begin
        Seed();
        OpenAndReadOne();
        Q.Open();
        ObserveReadAll('read after second open');
        Observer.Expect('first row', '1');
        Observer.Expect('read after second open', '1,2,3,');
        Observer.Verify();
    end;

    [Test]
    procedure RowsLeft_OpenResultUsed_ThenReadAll()
    begin
        Seed();
        OpenAndReadOne();
        Observer.Observe('second open', Format(Q.Open()));
        ObserveReadAll('read after second open');
        Observer.Expect('first row', '1');
        Observer.Expect('second open', 'Yes');
        Observer.Expect('read after second open', '1,2,3,');
        Observer.Verify();
    end;

    [Test]
    procedure RowsLeft_Open_ThenColumnRead()
    var
        Value: Text;
    begin
        Seed();
        OpenAndReadOne();
        Q.Open();
        if TryColumn(Value) then
            Observer.Observe('column', Value)
        else
            Observer.ObserveError('column');
        Observer.Expect('first row', '1');
        Observer.Expect('column|text', 'You have not yet retrieved a data row for this query. The value for column ''Id'' can only be accessed after a row is retrieved with a call to the READ function.');
        Observer.Expect('column|code', 'QueryNoDataSet');
        Observer.Verify();
    end;

    [Test]
    procedure RowsLeft_OpenTwice_ThenReadAll()
    begin
        Seed();
        OpenAndReadOne();
        Q.Open();
        Q.Open();
        ObserveReadAll('read after third open');
        Observer.Expect('first row', '1');
        Observer.Expect('read after third open', '1,2,3,');
        Observer.Verify();
    end;

    [Test]
    procedure RowsLeft_Open_ThenClose_ThenReadAll()
    begin
        Seed();
        OpenAndReadOne();
        Q.Open();
        Q.Close();
        ObserveReadAll('read after close');
        Observer.Expect('first row', '1');
        Observer.Expect('read after close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RowsLeft_Open_ThenSetFilter_ThenOpenAndReadAll()
    begin
        Seed();
        OpenAndReadOne();
        Q.Open();
        Q.SetFilter(Grp, 'B');
        Q.Open();
        ObserveReadAll('read after filter and open');
        Observer.Expect('first row', '1');
        Observer.Expect('read after filter and open', '3,');
        Observer.Verify();
    end;

    [Test]
    procedure TwoRowsRead_OpenStatement_ThenReadAll()
    begin
        Seed();
        OpenAndReadOne();
        Q.Read();
        Q.Open();
        ObserveReadAll('read after second open');
        Observer.Expect('first row', '1');
        Observer.Expect('read after second open', '1,2,3,');
        Observer.Verify();
    end;

    [Test]
    procedure RowsLeft_WriteThenOpen_ThenReadAll()
    var
        R: Record "ALT Shape 15";
    begin
        Seed();
        OpenAndReadOne();
        R.Id := 4; R.Grp := 'B'; R.Insert();
        Q.Open();
        ObserveReadAll('read after write and second open');
        Observer.Expect('first row', '1');
        Observer.Expect('read after write and second open', '1,2,3,4,');
        Observer.Verify();
    end;

    [Test]
    procedure SumQuery_FilterBeforeOpen_ReopenAndRead()
    var
        S: Query "QRY Reopen Sum";
    begin
        Seed();
        S.SetFilter(IdFilter, '1|3');
        S.Open();
        S.Read();
        Observer.Observe('first', S.Grp + '=' + Format(S.Total));
        Observer.Observe('second open', Format(S.Open()));
        Observer.Observe('read', Format(S.Read()));
        Observer.Observe('row', S.Grp + '=' + Format(S.Total));
        Observer.Observe('next read', Format(S.Read()));
        Observer.Expect('first', 'A=1');
        Observer.Expect('second open', 'Yes');
        Observer.Expect('read', 'Yes');
        Observer.Expect('row', 'A=1');
        Observer.Expect('next read', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure OnBeforeOpen_RowsLeft_Reopen()
    var
        B: Query "QRY Reopen Before Open";
        Rows: Text;
    begin
        Seed();
        B.Open();
        B.Read();
        Observer.Observe('opens after first', Format(B.Opens()));
        B.Open();
        Observer.Observe('opens after second', Format(B.Opens()));
        while B.Read() do
            Rows += Format(B.Id) + ',';
        Observer.Observe('rows', Rows);
        Observer.Expect('opens after first', '1');
        Observer.Expect('opens after second', '2');
        Observer.Expect('rows', '1,2,3,');
        Observer.Verify();
    end;
}
