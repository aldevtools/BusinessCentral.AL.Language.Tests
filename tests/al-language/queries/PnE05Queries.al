// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 72540, tables 72541-72546, queries 72547-72549
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed rows: "Queries: AboutTitle, AboutText, a DataItemLink to an outer data item" (the AboutTitle/AboutText part and the
// parent plus grandparent link part) and "A query column with `Method` over a FlowField" (NP Retail blockers)
// Facts: query with AboutTitle/AboutText, DataItemLink naming parent and grandparent, Sum/Count column over a FlowField
// BC versions: 29 (27 and 28 by CI)

table 72541 "LT PnE Q Grand"
{
    fields
    {
        field(1; Id; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 72542 "LT PnE Q Parent"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; GId; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 72543 "LT PnE Q Child"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; PId; Integer) { }
        field(3; GId; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 72544 "LT PnE Q Owner"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Total; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT PnE Q Line".Amount where(OwnerId = field(Id)));
        }
        field(3; LineCount; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT PnE Q Line" where(OwnerId = field(Id)));
        }
        field(4; Grp; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 72545 "LT PnE Q Line"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; OwnerId; Integer) { }
        field(3; Amount; Decimal) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

query 72547 "LT PnE Q Rows"
{
    QueryType = Normal;
    AboutTitle = 'About the query title';
    AboutText = 'About the query text';

    elements
    {
        dataitem(Owner; "LT PnE Q Owner")
        {
            column(Id; Id) { }
            column(Grp; Grp) { }
        }
    }
}

query 72548 "LT PnE Q Link Both"
{
    QueryType = Normal;

    elements
    {
        dataitem(Grand; "LT PnE Q Grand")
        {
            column(GrandId; Id) { }
            dataitem(Parent; "LT PnE Q Parent")
            {
                DataItemLink = GId = Grand.Id;
                column(ParentId; Id) { }
                dataitem(Child; "LT PnE Q Child")
                {
                    DataItemLink = PId = Parent.Id, GId = Grand.Id;
                    column(ChildId; Id) { }
                }
            }
        }
    }
}

query 72549 "LT PnE Q Flow Sum"
{
    QueryType = Normal;

    elements
    {
        dataitem(Owner; "LT PnE Q Owner")
        {
            column(Grp; Grp) { }
            column(SumTotal; Total)
            {
                Method = Sum;
            }
            column(SumCount; LineCount)
            {
                Method = Sum;
            }
        }
    }
}

codeunit 72540 "LT PnE Query Probes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Clean()
    var
        G: Record "LT PnE Q Grand";
        P: Record "LT PnE Q Parent";
        C: Record "LT PnE Q Child";
        O: Record "LT PnE Q Owner";
        L: Record "LT PnE Q Line";
    begin
        G.DeleteAll();
        P.DeleteAll();
        C.DeleteAll();
        O.DeleteAll();
        L.DeleteAll();
    end;

    local procedure AddOwner(Id: Integer; Grp: Integer)
    var
        O: Record "LT PnE Q Owner";
    begin
        O.Init();
        O.Id := Id;
        O.Grp := Grp;
        O.Insert();
    end;

    local procedure AddLine(Id: Integer; OwnerId: Integer; Amount: Decimal)
    var
        L: Record "LT PnE Q Line";
    begin
        L.Init();
        L.Id := Id;
        L.OwnerId := OwnerId;
        L.Amount := Amount;
        L.Insert();
    end;

    [Test]
    procedure QueryWithAboutProperties_ReadsRows()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT PnE Q Rows";
        N: Integer;
        S: Text;
    begin
        Clean();
        AddOwner(1, 5);
        AddOwner(2, 6);
        Q.Open();
        while Q.Read() do begin
            N += 1;
            S += Format(Q.Id) + ':' + Format(Q.Grp) + ';';
        end;
        Q.Close();
        Observer.Observe('count', Format(N));
        Observer.Observe('rows', S);
        Clean();
        Observer.Expect('count', '2');
        Observer.Expect('rows', '1:5;2:6;');
        Observer.Verify();
    end;

    [Test]
    procedure DataItemLink_ParentAndGrandparent()
    var
        Observer: Codeunit "Probe Observer";
        G: Record "LT PnE Q Grand";
        P: Record "LT PnE Q Parent";
        C: Record "LT PnE Q Child";
        Q: Query "LT PnE Q Link Both";
        S: Text;
        N: Integer;
    begin
        Clean();
        G.Id := 1;
        G.Insert();
        G.Id := 2;
        G.Insert();
        P.Id := 10;
        P.GId := 1;
        P.Insert();
        P.Id := 20;
        P.GId := 2;
        P.Insert();
        C.Id := 100;
        C.PId := 10;
        C.GId := 1;
        C.Insert();
        C.Id := 101;
        C.PId := 10;
        C.GId := 2;
        C.Insert();
        C.Id := 102;
        C.PId := 20;
        C.GId := 1;
        C.Insert();
        C.Id := 103;
        C.PId := 20;
        C.GId := 2;
        C.Insert();
        Q.Open();
        while Q.Read() do begin
            N += 1;
            S += Format(Q.GrandId) + '/' + Format(Q.ParentId) + '/' + Format(Q.ChildId) + ';';
        end;
        Q.Close();
        Observer.Observe('count', Format(N));
        Observer.Observe('rows', S);
        Clean();
        Observer.Expect('count', '2');
        Observer.Expect('rows', '1/10/100;2/20/103;');
        Observer.Verify();
    end;

    [Test]
    procedure MethodSum_OverFlowFields_Read()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT PnE Q Flow Sum";
        N: Integer;
        S: Text;
    begin
        Clean();
        AddOwner(1, 1);
        AddOwner(2, 1);
        AddOwner(3, 2);
        AddOwner(4, 3);
        AddLine(1, 1, 10);
        AddLine(2, 1, 20);
        AddLine(3, 2, 5);
        AddLine(4, 3, 7);
        Q.Open();
        while Q.Read() do begin
            N += 1;
            S += Format(Q.Grp) + ':' + Format(Q.SumTotal) + ':' + Format(Q.SumCount) + ';';
        end;
        Q.Close();
        Observer.Observe('count', Format(N));
        Observer.Observe('rows', S);
        N := 0;
        S := '';
        Q.SetRange(Grp, 1);
        Q.Open();
        while Q.Read() do begin
            N += 1;
            S += Format(Q.Grp) + ':' + Format(Q.SumTotal) + ':' + Format(Q.SumCount) + ';';
        end;
        Q.Close();
        Observer.Observe('countGrp1', Format(N));
        Observer.Observe('rowsGrp1', S);
        Clean();
        Observer.Expect('count', '3');
        Observer.Expect('rows', '1:35:3;2:7:1;3:0:0;');
        Observer.Expect('countGrp1', '1');
        Observer.Expect('rowsGrp1', '1:35:3;');
        Observer.Verify();
    end;
}
