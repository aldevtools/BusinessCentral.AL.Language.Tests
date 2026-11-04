// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73915, queries 73916 and 73917, codeunit 73918
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "A query method call with a column of the same name" (Must-not-compile checks)
// Facts: a query with filter(Open; Open): Q.Open() as the method, Q.SetRange(Open, true), Q.Read(), Q.Close(); a second query with column(Open; Open) read after Read as Q.Open
// BC versions: 29 (27 and 28 by CI)

table 73915 "LT PnF QM Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Open; Boolean) { }
        field(3; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

query 73916 "LT PnF QM Filter Open"
{
    QueryType = Normal;

    elements
    {
        dataitem(Rows; "LT PnF QM Row")
        {
            column(Id; Id) { }
            column(Name; Name) { }
            filter(Open; Open) { }
        }
    }
}

query 73917 "LT PnF QM Column Open"
{
    QueryType = Normal;

    elements
    {
        dataitem(Rows; "LT PnF QM Row")
        {
            column(Id; Id) { }
            column(Open; Open) { }
        }
    }
}

codeunit 73918 "LT PnF Query Name Method"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT PnF QM Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Open := true;
        Row.Name := 'a';
        Row.Insert();
        Row.Id := 2;
        Row.Open := false;
        Row.Name := 'b';
        Row.Insert();
        Row.Id := 3;
        Row.Open := true;
        Row.Name := 'c';
        Row.Insert();
    end;

    [Test]
    procedure Query_FilterNamedOpen()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT PnF QM Filter Open";
        Names: Text;
    begin
        Seed();
        Q.SetRange(Open, true);
        Observer.Observe('opened', Format(Q.Open()));
        while Q.Read() do
            Names += Q.Name;
        Observer.Observe('names_open_true', Names);
        Q.Close();
        Names := '';
        Q.SetRange(Open, false);
        Q.Open();
        while Q.Read() do
            Names += Q.Name;
        Observer.Observe('names_open_false', Names);
        Q.Close();
        Observer.Expect('opened', 'Yes');
        Observer.Expect('names_open_true', 'ac');
        Observer.Expect('names_open_false', 'b');
        Observer.Verify();
    end;

    [Test]
    procedure Query_FilterNamedOpen_NoFilter()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT PnF QM Filter Open";
        Names: Text;
    begin
        Seed();
        Q.Open();
        while Q.Read() do
            Names += Q.Name;
        Observer.Observe('names_all', Names);
        Q.Close();
        Observer.Expect('names_all', 'abc');
        Observer.Verify();
    end;

    [Test]
    procedure Query_ColumnNamedOpen()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT PnF QM Column Open";
        Seen: Text;
    begin
        Seed();
        Q.Open();
        while Q.Read() do
            Seen += Format(Q.Id) + '=' + Format(Q.Open) + ' ';
        Observer.Observe('rows', Seen);
        Q.Close();
        Observer.Expect('rows', '1=Yes 2=No 3=Yes ');
        Observer.Verify();
    end;
}
