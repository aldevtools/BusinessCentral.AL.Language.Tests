// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-open-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); shared table 50015 "ALT Shape 15"; queries 71968, 71969, 71970; test codeunit 71971
// Probe: DRAFT, observe form, not yet run on BC (al-runner issue 7827). Every value is observed; the pipeline turns them into Expect lines.
// Facts: a second Open on a query that was read from while rows were left, with no SetFilter or SetRange between (al-runner issue 7827).
//   What Read, a column read, Open, Close and SetFilter do right after that second Open; whether the second Open's return value
//   is true; whether OnBeforeOpen runs again; the same on a query with a Sum column and a filter set before the first Open
//   (the issue's own shape); and after two Reads instead of one.
//   Already pinned elsewhere: the second Open as a statement followed by SetRange and Open (QueryClosedAfterLastRow.al:162).
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
        Observer.Finish();
    end;

    [Test]
    procedure RowsLeft_OpenResultUsed_ThenReadAll()
    begin
        Seed();
        OpenAndReadOne();
        Observer.Observe('second open', Format(Q.Open()));
        ObserveReadAll('read after second open');
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure RowsLeft_OpenTwice_ThenReadAll()
    begin
        Seed();
        OpenAndReadOne();
        Q.Open();
        Q.Open();
        ObserveReadAll('read after third open');
        Observer.Finish();
    end;

    [Test]
    procedure RowsLeft_Open_ThenClose_ThenReadAll()
    begin
        Seed();
        OpenAndReadOne();
        Q.Open();
        Q.Close();
        ObserveReadAll('read after close');
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure TwoRowsRead_OpenStatement_ThenReadAll()
    begin
        Seed();
        OpenAndReadOne();
        Q.Read();
        Q.Open();
        ObserveReadAll('read after second open');
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
