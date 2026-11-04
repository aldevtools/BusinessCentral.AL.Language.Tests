// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 71939, queries 71940 and 71942
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: what an open grouped (aggregated) query hands out when the table it reads is inserted into, modified or deleted from between two Read calls; the same with a plain query for contrast.
// BC versions: 29 (27 and 28 by CI)

table 71939 "LT P160 QLive"
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

query 71940 "LT P160 QLiveAgg"
{
    QueryType = Normal;
    OrderBy = ascending(Grp);

    elements
    {
        dataitem(S; "LT P160 QLive")
        {
            column(Grp; Grp) { }
            column(Cnt) { Method = Count; }
            column(SumVal; Val) { Method = Sum; }
        }
    }
}

query 71942 "LT P160 QLivePlain"
{
    QueryType = Normal;
    OrderBy = ascending(Id);

    elements
    {
        dataitem(S; "LT P160 QLive")
        {
            column(Id; Id) { }
            column(Grp; Grp) { }
            column(Val; Val) { }
        }
    }
}

codeunit 71941 "LT P160 Query Live Write"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Ins(IdNo: Integer; G: Code[10]; V: Integer)
    var
        Row: Record "LT P160 QLive";
    begin
        Row.Init();
        Row.Id := IdNo;
        Row.Grp := G;
        Row.Val := V;
        Row.Insert();
    end;

    local procedure Seed()
    var
        Row: Record "LT P160 QLive";
    begin
        Row.DeleteAll();
        Ins(1, 'A', 1);
        Ins(2, 'A', 2);
        Ins(3, 'B', 10);
        Ins(4, 'C', 100);
    end;

    local procedure ReadRest(var Q: Query "LT P160 QLiveAgg"): Text
    var
        Result: Text;
    begin
        while Q.Read() do
            Result += Q.Grp + '=' + Format(Q.Cnt) + '/' + Format(Q.SumVal) + ' ';
        exit(Result);
    end;

    [Test]
    procedure Aggregated_InsertIntoReadGroupAndNewGroups()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P160 QLiveAgg";
    begin
        Seed();
        Q.Open();
        Observer.Observe('first read', Format(Q.Read()));
        Observer.Observe('first group', Q.Grp + '=' + Format(Q.Cnt) + '/' + Format(Q.SumVal));
        Ins(5, 'A', 1000);
        Ins(6, 'B', 2000);
        Ins(7, 'D', 3000);
        Observer.Observe('rest after inserts', ReadRest(Q));
        Q.Close();
        Q.Open();
        Observer.Observe('reopened', ReadRest(Q));
        Q.Close();
        Observer.Expect('first read', 'Yes');
        Observer.Expect('first group', 'A=2/3');
        Observer.Expect('rest after inserts', 'B=2/2010 C=1/100 D=1/3000 ');
        Observer.Expect('reopened', 'A=3/1003 B=2/2010 C=1/100 D=1/3000 ');
        Observer.Verify();
    end;

    [Test]
    procedure Aggregated_DeleteAndModifyBetweenReads()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P160 QLive";
        Q: Query "LT P160 QLiveAgg";
    begin
        Seed();
        Q.Open();
        Observer.Observe('first read', Format(Q.Read()));
        Observer.Observe('first group', Q.Grp + '=' + Format(Q.Cnt) + '/' + Format(Q.SumVal));
        Row.Get(3);
        Row.Val := 11;
        Row.Modify();
        Row.Get(4);
        Row.Delete();
        Observer.Observe('rest after modify and delete', ReadRest(Q));
        Q.Close();
        Q.Open();
        Observer.Observe('reopened', ReadRest(Q));
        Q.Close();
        Observer.Expect('first read', 'Yes');
        Observer.Expect('first group', 'A=2/3');
        Observer.Expect('rest after modify and delete', 'B=1/11 ');
        Observer.Expect('reopened', 'A=2/3 B=1/11 ');
        Observer.Verify();
    end;

    [Test]
    procedure Aggregated_DeleteAllBetweenReads()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P160 QLive";
        Q: Query "LT P160 QLiveAgg";
    begin
        Seed();
        Q.Open();
        Observer.Observe('first read', Format(Q.Read()));
        Row.DeleteAll();
        Observer.Observe('rest after DeleteAll', ReadRest(Q));
        Observer.Observe('read at end', Format(Q.Read()));
        Q.Close();
        Observer.Expect('first read', 'Yes');
        Observer.Expect('rest after DeleteAll', '');
        Observer.Expect('read at end', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Plain_InsertDeleteBetweenReads()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P160 QLive";
        Q: Query "LT P160 QLivePlain";
        Result: Text;
    begin
        Seed();
        Q.Open();
        Observer.Observe('first read', Format(Q.Read()) + ' ' + Format(Q.Id));
        Ins(5, 'A', 1000);
        Row.Get(3);
        Row.Delete();
        while Q.Read() do
            Result += Format(Q.Id) + ':' + Q.Grp + ':' + Format(Q.Val) + ' ';
        Q.Close();
        Observer.Observe('rest', Result);
        Observer.Expect('first read', 'Yes 1');
        Observer.Expect('rest', '2:A:2 4:C:100 5:A:1000 ');
        Observer.Verify();
    end;
}
