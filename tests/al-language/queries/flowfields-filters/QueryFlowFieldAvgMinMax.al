// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 71314 71315, queries 71316 71317 71318, codeunit 71319
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: Query column with Method = Average / Min / Max over a FlowField column of the dataitem table, grouped by another column, with and without a flow filter filter-element. RISKY: own file; one query per method so a compile failure is visible per query.

table 71314 "LT QFlowB Line"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Header No."; Code[20]) { }
        field(3; Amount; Decimal) { }
        field(4; "Posting Date"; Date) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 71315 "LT QFlowB Header"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Group Code"; Code[10]) { }
        field(3; "Date Filter"; Date) { FieldClass = FlowFilter; }
        field(4; Total; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT QFlowB Line".Amount where("Header No." = field("No."), "Posting Date" = field("Date Filter")));
        }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

query 71316 "LT QFlowB Average"
{
    QueryType = Normal;
    elements
    {
        dataitem(Hdr; "LT QFlowB Header")
        {
            column(Grp; "Group Code") { }
            filter(DateFlt; "Date Filter") { }
            column(Agg; Total) { Method = Average; }
        }
    }
}

query 71317 "LT QFlowB Min"
{
    QueryType = Normal;
    elements
    {
        dataitem(Hdr; "LT QFlowB Header")
        {
            column(Grp; "Group Code") { }
            filter(DateFlt; "Date Filter") { }
            column(Agg; Total) { Method = Min; }
        }
    }
}

query 71318 "LT QFlowB Max"
{
    QueryType = Normal;
    elements
    {
        dataitem(Hdr; "LT QFlowB Header")
        {
            column(Grp; "Group Code") { }
            filter(DateFlt; "Date Filter") { }
            column(Agg; Total) { Method = Max; }
        }
    }
}

codeunit 71319 "LT QFlowB AvgMinMax Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        H: Record "LT QFlowB Header";
        L: Record "LT QFlowB Line";
    begin
        H.DeleteAll();
        L.DeleteAll();
        AddHeader('H1', 'A');
        AddHeader('H2', 'A');
        AddHeader('H3', 'B');
        AddHeader('H4', 'B');
        AddLine(1, 'H1', 10, DMY2Date(1, 1, 2030));
        AddLine(2, 'H1', 20, DMY2Date(1, 2, 2030));
        AddLine(3, 'H2', 5, DMY2Date(1, 1, 2030));
        AddLine(4, 'H3', 7, DMY2Date(1, 2, 2030));
        AddLine(5, 'H3', 3, DMY2Date(1, 2, 2030));
    end;

    local procedure AddHeader(No: Code[20]; Grp: Code[10])
    var
        H: Record "LT QFlowB Header";
    begin
        H."No." := No;
        H."Group Code" := Grp;
        H.Insert();
    end;

    local procedure AddLine(EntryNo: Integer; HeaderNo: Code[20]; Amt: Decimal; PostingDate: Date)
    var
        L: Record "LT QFlowB Line";
    begin
        L."Entry No." := EntryNo;
        L."Header No." := HeaderNo;
        L.Amount := Amt;
        L."Posting Date" := PostingDate;
        L.Insert();
    end;

    [Test]
    procedure Average_NoFlowFilter_GroupedByGroupCode()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QFlowB Average";
        N: Integer;
    begin
        Seed();
        Q.Open();
        while Q.Read() do begin
            N += 1;
            Observer.Observe('row' + Format(N), Q.Grp + '|' + Format(Q.Agg));
        end;
        Observer.Observe('rows', Format(N));
        Observer.Expect('row1', 'A|17.5');
        Observer.Expect('row2', 'B|10');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Average_FlowFilterRange_GroupedByGroupCode()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QFlowB Average";
        N: Integer;
    begin
        Seed();
        Q.SetRange(DateFlt, DMY2Date(1, 1, 2030), DMY2Date(31, 1, 2030));
        Q.Open();
        while Q.Read() do begin
            N += 1;
            Observer.Observe('row' + Format(N), Q.Grp + '|' + Format(Q.Agg));
        end;
        Observer.Observe('rows', Format(N));
        Observer.Expect('row1', 'A|7.5');
        Observer.Expect('row2', 'B|0');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Min_NoFlowFilter_GroupedByGroupCode()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QFlowB Min";
        N: Integer;
    begin
        Seed();
        Q.Open();
        while Q.Read() do begin
            N += 1;
            Observer.Observe('row' + Format(N), Q.Grp + '|' + Format(Q.Agg));
        end;
        Observer.Observe('rows', Format(N));
        Observer.Expect('row1', 'A|5');
        Observer.Expect('row2', 'B|10');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Min_FlowFilterRange_GroupedByGroupCode()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QFlowB Min";
        N: Integer;
    begin
        Seed();
        Q.SetRange(DateFlt, DMY2Date(1, 2, 2030), DMY2Date(28, 2, 2030));
        Q.Open();
        while Q.Read() do begin
            N += 1;
            Observer.Observe('row' + Format(N), Q.Grp + '|' + Format(Q.Agg));
        end;
        Observer.Observe('rows', Format(N));
        Observer.Expect('row1', 'A|20');
        Observer.Expect('row2', 'B|10');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Max_NoFlowFilter_GroupedByGroupCode()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QFlowB Max";
        N: Integer;
    begin
        Seed();
        Q.Open();
        while Q.Read() do begin
            N += 1;
            Observer.Observe('row' + Format(N), Q.Grp + '|' + Format(Q.Agg));
        end;
        Observer.Observe('rows', Format(N));
        Observer.Expect('row1', 'A|30');
        Observer.Expect('row2', 'B|10');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Max_FlowFilterRange_GroupedByGroupCode()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QFlowB Max";
        N: Integer;
    begin
        Seed();
        Q.SetRange(DateFlt, DMY2Date(1, 2, 2030), DMY2Date(28, 2, 2030));
        Q.Open();
        while Q.Read() do begin
            N += 1;
            Observer.Observe('row' + Format(N), Q.Grp + '|' + Format(Q.Agg));
        end;
        Observer.Observe('rows', Format(N));
        Observer.Expect('row1', 'A|20');
        Observer.Expect('row2', 'B|10');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;
}
