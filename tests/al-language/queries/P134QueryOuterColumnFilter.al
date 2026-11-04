// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-columnfilter-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 74125 74126, queries 74127 74128 74129 74130, test codeunit 74131 (P134)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a static ColumnFilter (and a DataItemTableFilter plus ColumnFilter) on a column of a LeftOuterJoin data item: whether the unmatched parent rows survive (filter in the join condition) or vanish (filter in the WHERE clause), compared with the same filter on an InnerJoin
// BC versions: 29 (27 and 28 by CI)

table 74125 "LT P134 Par"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[20]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 74126 "LT P134 Chi"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Entry; Integer) { }
        field(2; ParCode; Code[10]) { }
        field(3; Kind; Integer) { }
        field(4; Qty; Decimal) { }
    }

    keys
    {
        key(PK; Entry) { Clustered = true; }
    }
}

query 74127 "LT P134 Q Left ColKind"
{
    QueryType = Normal;
    OrderBy = ascending(PCode), ascending(Entry);

    elements
    {
        dataitem(P; "LT P134 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT P134 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = LeftOuterJoin;
                column(Entry; Entry) { }
                column(Kind; Kind)
                {
                    ColumnFilter = Kind = const(1);
                }
                column(Qty; Qty) { }
            }
        }
    }
}

query 74128 "LT P134 Q Left ColQty"
{
    QueryType = Normal;
    OrderBy = ascending(PCode), ascending(Entry);

    elements
    {
        dataitem(P; "LT P134 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT P134 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = LeftOuterJoin;
                column(Entry; Entry) { }
                column(Kind; Kind) { }
                column(Qty; Qty)
                {
                    ColumnFilter = Qty = filter(> 15);
                }
            }
        }
    }
}

query 74129 "LT P134 Q Left TblAndCol"
{
    QueryType = Normal;
    OrderBy = ascending(PCode), ascending(Entry);

    elements
    {
        dataitem(P; "LT P134 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT P134 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = LeftOuterJoin;
                DataItemTableFilter = Kind = const(2);
                column(Entry; Entry) { }
                column(Kind; Kind) { }
                column(Qty; Qty)
                {
                    ColumnFilter = Qty = filter(> 25);
                }
            }
        }
    }
}

query 74130 "LT P134 Q Inner ColKind"
{
    QueryType = Normal;
    OrderBy = ascending(PCode), ascending(Entry);

    elements
    {
        dataitem(P; "LT P134 Par")
        {
            column(PCode; "Code") { }

            dataitem(C; "LT P134 Chi")
            {
                DataItemLink = ParCode = P.Code;
                SqlJoinType = InnerJoin;
                column(Entry; Entry) { }
                column(Kind; Kind)
                {
                    ColumnFilter = Kind = const(1);
                }
                column(Qty; Qty) { }
            }
        }
    }
}

codeunit 74131 "LT P134 Query Col Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Par: Record "LT P134 Par";
        Chi: Record "LT P134 Chi";
    begin
        Par.DeleteAll();
        Chi.DeleteAll();
        AddPar('P1', 'First');
        AddPar('P2', 'Second');
        AddPar('P3', 'Third');
        AddPar('P4', 'Fourth');
        AddChi(1, 'P1', 1, 10);
        AddChi(2, 'P1', 2, 20);
        AddChi(3, 'P2', 2, 30);
        AddChi(4, 'P3', 1, 40);
    end;

    local procedure AddPar(NewCode: Code[10]; NewName: Text[20])
    var
        Par: Record "LT P134 Par";
    begin
        Par."Code" := NewCode;
        Par.Name := NewName;
        Par.Insert();
    end;

    local procedure AddChi(NewEntry: Integer; NewPar: Code[10]; NewKind: Integer; NewQty: Decimal)
    var
        Chi: Record "LT P134 Chi";
    begin
        Chi.Entry := NewEntry;
        Chi.ParCode := NewPar;
        Chi.Kind := NewKind;
        Chi.Qty := NewQty;
        Chi.Insert();
    end;

    [Test]
    procedure P134_Left_ColumnFilter_OnProjectedKind()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P134 Q Left ColKind";
        i: Integer;
    begin
        Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Q.PCode + '|' + Format(Q.Entry) + '|' + Format(Q.Kind) + '|' + Format(Q.Qty));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'P1|1|1|10');
        Observer.Expect('r2', 'P3|4|1|40');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure P134_Left_ColumnFilter_OnQty()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P134 Q Left ColQty";
        i: Integer;
    begin
        Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Q.PCode + '|' + Format(Q.Entry) + '|' + Format(Q.Kind) + '|' + Format(Q.Qty));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'P1|2|2|20');
        Observer.Expect('r2', 'P2|3|2|30');
        Observer.Expect('r3', 'P3|4|1|40');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    procedure P134_Left_TableFilterAndColumnFilter()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P134 Q Left TblAndCol";
        i: Integer;
    begin
        Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Q.PCode + '|' + Format(Q.Entry) + '|' + Format(Q.Kind) + '|' + Format(Q.Qty));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'P2|3|2|30');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P134_Inner_ColumnFilter_ForComparison()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P134 Q Inner ColKind";
        i: Integer;
    begin
        Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Q.PCode + '|' + Format(Q.Entry) + '|' + Format(Q.Kind) + '|' + Format(Q.Qty));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'P1|1|1|10');
        Observer.Expect('r2', 'P3|4|1|40');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure P134_Left_ColumnFilter_ReplacedByRuntimeSetRange()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P134 Q Left ColKind";
        i: Integer;
    begin
        Seed();
        Q.SetRange(Kind, 2);
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Q.PCode + '|' + Format(Q.Entry) + '|' + Format(Q.Kind) + '|' + Format(Q.Qty));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'P1|2|2|20');
        Observer.Expect('r2', 'P2|3|2|30');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;
}
