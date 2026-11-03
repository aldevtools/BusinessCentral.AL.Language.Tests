// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 71924, queries 71925 and 71929
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the order in which a grouped query hands out groups whose OrderBy aggregate is equal (ascending and descending), with the groups inserted in a different order than their names sort.
// BC versions: 29 (27 and 28 by CI)

table 71924 "LT P160 QGrp"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Code[10]) { }
        field(3; Val; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

query 71925 "LT P160 QTiesDesc"
{
    QueryType = Normal;
    OrderBy = descending(SumVal);

    elements
    {
        dataitem(S; "LT P160 QGrp")
        {
            column(Grp; Grp) { }
            column(SumVal; Val) { Method = Sum; }
        }
    }
}

query 71929 "LT P160 QTiesAsc"
{
    QueryType = Normal;
    OrderBy = ascending(SumVal);

    elements
    {
        dataitem(S; "LT P160 QGrp")
        {
            column(Grp; Grp) { }
            column(SumVal; Val) { Method = Sum; }
        }
    }
}

codeunit 71926 "LT P160 Query Ties"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Ins(IdNo: Integer; G: Code[10]; V: Integer)
    var
        Row: Record "LT P160 QGrp";
    begin
        Row.Init();
        Row.Id := IdNo;
        Row.Grp := G;
        Row.Val := V;
        Row.Insert();
    end;

    local procedure SeedTies()
    var
        Row: Record "LT P160 QGrp";
    begin
        Row.DeleteAll();
        Ins(1, 'D', 10);
        Ins(2, 'B', 10);
        Ins(3, 'A', 5);
        Ins(4, 'A', 5);
        Ins(5, 'C', 10);
        Ins(6, 'E', 20);
        Ins(7, 'F', 1);
    end;

    [Test]
    procedure Descending_EqualSums()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P160 QTiesDesc";
        Order: Text;
        N: Integer;
    begin
        SeedTies();
        Q.Open();
        while Q.Read() do begin
            N += 1;
            Order += Q.Grp + '=' + Format(Q.SumVal) + ' ';
        end;
        Q.Close();
        Observer.Observe('rows', Format(N));
        Observer.Observe('order', Order);
        Observer.Expect('rows', '6');
        Observer.Expect('order', 'E=20 A=10 B=10 C=10 D=10 F=1 ');
        Observer.Verify();
    end;

    [Test]
    procedure Ascending_EqualSums()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P160 QTiesAsc";
        Order: Text;
        N: Integer;
    begin
        SeedTies();
        Q.Open();
        while Q.Read() do begin
            N += 1;
            Order += Q.Grp + '=' + Format(Q.SumVal) + ' ';
        end;
        Q.Close();
        Observer.Observe('rows', Format(N));
        Observer.Observe('order', Order);
        Observer.Expect('rows', '6');
        Observer.Expect('order', 'F=1 A=10 B=10 C=10 D=10 E=20 ');
        Observer.Verify();
    end;

    [Test]
    procedure Descending_EqualSums_InsertedInOtherOrder()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P160 QGrp";
        Q: Query "LT P160 QTiesDesc";
        Order: Text;
    begin
        Row.DeleteAll();
        Ins(1, 'C', 4);
        Ins(2, 'A', 4);
        Ins(3, 'B', 4);
        Ins(4, 'D', 4);
        Q.Open();
        while Q.Read() do
            Order += Q.Grp + '=' + Format(Q.SumVal) + ' ';
        Q.Close();
        Observer.Observe('order all equal', Order);
        Q.SetFilter(Grp, 'B|C|D');
        Q.Open();
        Order := '';
        while Q.Read() do
            Order += Q.Grp + '=' + Format(Q.SumVal) + ' ';
        Q.Close();
        Observer.Observe('order with a filter on Grp', Order);
        Observer.Expect('order all equal', 'A=4 B=4 C=4 D=4 ');
        Observer.Expect('order with a filter on Grp', 'B=4 C=4 D=4 ');
        Observer.Verify();
    end;
}
