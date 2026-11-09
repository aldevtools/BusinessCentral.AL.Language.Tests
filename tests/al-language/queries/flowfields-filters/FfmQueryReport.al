// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects declared in this file (FFM QR *)
// local object: the FlowFields over a joined table, the query elements over them and the report columns over them are what the tests measure.
// Area: FlowField and FlowFilter matrix, query and report. Queries: a column over a FlowField of every CalcFormula kind (sum, -sum, average,
//   min, max, count, exist, lookup), a column and a filter() element over a FlowField of a LeftOuterJoin data item below an InnerJoin
//   (the query is a global variable of the test codeunit), SetFilter and SetRange on the FlowField column, OrderBy on a FlowField column.
//   Reports: dataitem columns over every FlowField kind, and a column over a Blob field and a FlowField of a global record that the report
//   only reads with Get() and never calculates (al-runner issues 7401 and 7399).
// Nearby: queries/flowfields-filters/QueryOuterFlowFilters.al, queries/flowfields-filters/QueryOuterFlowKinds.al, reports/layouts-saveas/BcXmlBlob.al
// Probe: values recorded on BC; the corpus CI matrix checks the other versions.

table 64601 "FFM QR Detail"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Owner; Code[10]) { }
        field(3; Amt; Decimal) { }
        field(4; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 64602 "FFM QR Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Picture; Blob) { }
        field(100; SumF; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM QR Detail".Amt where(Owner = field(Code))); }
        field(101; NSumF; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM QR Detail".Amt where(Owner = field(Code))); }
        field(102; AvgF; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM QR Detail".Amt where(Owner = field(Code))); }
        field(103; MinF; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM QR Detail".Amt where(Owner = field(Code))); }
        field(104; MaxF; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM QR Detail".Amt where(Owner = field(Code))); }
        field(105; CntF; Integer) { FieldClass = FlowField; CalcFormula = count("FFM QR Detail" where(Owner = field(Code))); }
        field(106; ExF; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM QR Detail" where(Owner = field(Code))); }
        field(107; LkF; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM QR Detail".Name where(Owner = field(Code))); }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 64603 "FFM QR Top"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[10]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 64604 "FFM QR Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Top Code"; Code[10]) { }
        field(3; "Header Code"; Code[10]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

query 64605 "FFM QR Columns"
{
    QueryType = Normal;
    OrderBy = ascending(Code);

    elements
    {
        dataitem(H; "FFM QR Header")
        {
            column(Code; Code) { }
            column(SumC; SumF) { }
            column(NSumC; NSumF) { }
            column(AvgC; AvgF) { }
            column(MinC; MinF) { }
            column(MaxC; MaxF) { }
            column(CntC; CntF) { }
            column(ExC; ExF) { }
            column(LkC; LkF) { }
        }
    }
}

query 64606 "FFM QR Outer Filter"
{
    QueryType = Normal;

    elements
    {
        dataitem(Top; "FFM QR Top")
        {
            column(TopCode; Code) { }

            dataitem(Line; "FFM QR Line")
            {
                DataItemLink = "Top Code" = Top.Code;
                SqlJoinType = InnerJoin;

                column(LineNo; "Entry No.") { }

                dataitem(Hdr; "FFM QR Header")
                {
                    DataItemLink = Code = Line."Header Code";
                    SqlJoinType = LeftOuterJoin;

                    filter(Hdr_Name; LkF) { }
                    filter(Hdr_Sum; SumF) { }
                    filter(Hdr_Count; CntF) { }
                    filter(Hdr_Exist; ExF) { }
                }
            }
        }
    }
}

query 64607 "FFM QR Outer Columns"
{
    QueryType = Normal;

    elements
    {
        dataitem(Top; "FFM QR Top")
        {
            column(TopCode; Code) { }

            dataitem(Line; "FFM QR Line")
            {
                DataItemLink = "Top Code" = Top.Code;
                SqlJoinType = InnerJoin;

                column(LineNo; "Entry No.") { }

                dataitem(Hdr; "FFM QR Header")
                {
                    DataItemLink = Code = Line."Header Code";
                    SqlJoinType = LeftOuterJoin;

                    column(Hdr_Sum; SumF) { }
                    column(Hdr_NSum; NSumF) { }
                    column(Hdr_Count; CntF) { }
                    column(Hdr_Exist; ExF) { }
                    column(Hdr_Name; LkF) { }
                }
            }
        }
    }
}

query 64608 "FFM QR Order By Flow"
{
    QueryType = Normal;
    OrderBy = descending(SumC);

    elements
    {
        dataitem(H; "FFM QR Header")
        {
            column(Code; Code) { }
            column(SumC; SumF) { }
        }
    }
}

report 64609 "FFM QR Dataset"
{
    UsageCategory = None;
    ProcessingOnly = false;

    dataset
    {
        dataitem(H; "FFM QR Header")
        {
            column(Code; H.Code) { }
            column(SumCol; H.SumF) { }
            column(NSumCol; H.NSumF) { }
            column(AvgCol; H.AvgF) { }
            column(MinCol; H.MinF) { }
            column(MaxCol; H.MaxF) { }
            column(CntCol; H.CntF) { }
            column(ExCol; H.ExF) { }
            column(LkCol; H.LkF) { }
            column(PicCol; H.Picture) { }
        }
    }
}

// The shape of al-runner issue 7399: columns over a Blob field and over FlowFields of a global record that is only read with Get().
report 64610 "FFM QR Global Uncalculated"
{
    UsageCategory = None;
    ProcessingOnly = false;

    dataset
    {
        dataitem(One; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(Num; One.Number) { }
            column(InfoPicture; Info.Picture) { }
            column(InfoSum; Info.SumF) { }
            column(InfoNSum; Info.NSumF) { }
            column(InfoCount; Info.CntF) { }
            column(InfoExist; Info.ExF) { }
            column(InfoName; Info.LkF) { }
        }
    }

    trigger OnPreReport()
    begin
        Info.Get('H1');
    end;

    var
        Info: Record "FFM QR Header";
}

// The same columns, with CalcFields of every one of them after Get().
report 64611 "FFM QR Global Calculated"
{
    UsageCategory = None;
    ProcessingOnly = false;

    dataset
    {
        dataitem(One; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(Num; One.Number) { }
            column(InfoPicture; Info.Picture) { }
            column(InfoSum; Info.SumF) { }
            column(InfoNSum; Info.NSumF) { }
            column(InfoCount; Info.CntF) { }
            column(InfoExist; Info.ExF) { }
            column(InfoName; Info.LkF) { }
        }
    }

    trigger OnPreReport()
    begin
        Info.Get('H1');
        Info.CalcFields(Picture, SumF, NSumF, CntF, ExF, LkF);
    end;

    var
        Info: Record "FFM QR Header";
}

codeunit 64612 "FFM QR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        GlobalOuterFilter: Query "FFM QR Outer Filter";
        GlobalOuterColumns: Query "FFM QR Outer Columns";

    [Test]
    procedure QueryColumns_EveryFlowFieldKind_Rows()
    // CLAIM: a query column over a FlowField of every CalcFormula kind returns the calculated value per row.
    var
        Q: Query "FFM QR Columns";
        Rows: Text;
    begin
        Initialize();
        if not TryOpen(Q) then
            Observer.Observe('open', GetLastErrorText())
        else begin
            while Q.Read() do
                Rows += StrSubstNo('%1:%2|%3|%4|%5|%6|%7|%8|%9;', Q.Code, Q.SumC, Q.NSumC, Q.AvgC, Q.MinC, Q.MaxC, Q.CntC, Q.ExC, Q.LkC);
            Observer.Observe('rows', Rows);
        end;
        Observer.Finish();
    end;

    [Test]
    procedure QueryColumns_SetFilterSetRangeOnFlowFieldColumn_Rows()
    // CLAIM: SetFilter and SetRange on a query column over a FlowField of every kind keep the rows whose calculated value matches.
    var
        Q: Query "FFM QR Columns";
    begin
        Initialize();
        Observer.Observe('sum>100', ReadCodes(Q, 'SumC', '>100'));
        Observer.Observe('nsum<-100', ReadCodes(Q, 'NSumC', '<-100'));
        Observer.Observe('avg>30', ReadCodes(Q, 'AvgC', '>30'));
        Observer.Observe('min<=10.5', ReadCodes(Q, 'MinC', '<=10.5'));
        Observer.Observe('max>=80', ReadCodes(Q, 'MaxC', '>=80'));
        Observer.Observe('count>=2', ReadCodes(Q, 'CntC', '>=2'));
        Observer.Observe('count=0', ReadCodes(Q, 'CntC', '0'));
        Observer.Observe('exist=true', ReadCodes(Q, 'ExC', 'Yes'));
        Observer.Observe('exist=false', ReadCodes(Q, 'ExC', 'No'));
        Observer.Observe('lookup=a*', ReadCodes(Q, 'LkC', 'a*'));
        Observer.Observe('lookup=empty', ReadCodes(Q, 'LkC', ''''''));
        Observer.Finish();
    end;

    [Test]
    procedure QueryOrderBy_FlowFieldColumn_Rows()
    // CLAIM: a query ordered descending by a FlowField column returns the rows in that order.
    var
        Q: Query "FFM QR Order By Flow";
        Rows: Text;
    begin
        Initialize();
        if not TryOpenOrder(Q) then
            Observer.Observe('open', GetLastErrorText())
        else begin
            while Q.Read() do
                Rows += StrSubstNo('%1:%2;', Q.Code, Q.SumC);
            Observer.Observe('rows', Rows);
        end;
        Observer.Finish();
    end;

    [Test]
    procedure QueryOuterJoin_FilterElementOverFlowFields_GlobalVariable_Rows()
    // CLAIM: filter() elements over a Lookup, Sum, Count and Exist FlowField of a LeftOuterJoin data item below an InnerJoin apply to the FlowField value, in a query that is a global variable.
    begin
        Initialize();
        Observer.Observe('unfiltered', ReadOuterFilter(GlobalOuterFilter));
        GlobalOuterFilter.SetFilter(Hdr_Name, 'a*');
        Observer.Observe('name a*', ReadOuterFilter(GlobalOuterFilter));
        GlobalOuterFilter.SetFilter(Hdr_Name, '');
        Observer.Observe('name empty', ReadOuterFilter(GlobalOuterFilter));
        GlobalOuterFilter.SetFilter(Hdr_Name, '''''');
        Observer.Observe('name empty literal', ReadOuterFilter(GlobalOuterFilter));
        GlobalOuterFilter.SetFilter(Hdr_Name, '');
        GlobalOuterFilter.SetFilter(Hdr_Sum, '>100');
        Observer.Observe('sum>100', ReadOuterFilter(GlobalOuterFilter));
        GlobalOuterFilter.SetFilter(Hdr_Sum, '');
        GlobalOuterFilter.SetRange(Hdr_Count, 0);
        Observer.Observe('count=0', ReadOuterFilter(GlobalOuterFilter));
        GlobalOuterFilter.SetFilter(Hdr_Count, '');
        GlobalOuterFilter.SetRange(Hdr_Exist, true);
        Observer.Observe('exist=true', ReadOuterFilter(GlobalOuterFilter));
        GlobalOuterFilter.SetRange(Hdr_Exist, false);
        Observer.Observe('exist=false', ReadOuterFilter(GlobalOuterFilter));
        Observer.Finish();
    end;

    [Test]
    procedure QueryOuterJoin_ColumnsOverFlowFields_GlobalVariable_Rows()
    // CLAIM: columns over a Sum, -Sum, Count, Exist and Lookup FlowField of a LeftOuterJoin data item below an InnerJoin return the calculated value, and the field's default for a row without a match.
    var
        Rows: Text;
    begin
        Initialize();
        GlobalOuterColumns.Open();
        while GlobalOuterColumns.Read() do
            Rows += StrSubstNo('%1/%2:%3|%4|%5|%6|%7;', GlobalOuterColumns.TopCode, GlobalOuterColumns.LineNo, GlobalOuterColumns.Hdr_Sum, GlobalOuterColumns.Hdr_NSum, GlobalOuterColumns.Hdr_Count, GlobalOuterColumns.Hdr_Exist, GlobalOuterColumns.Hdr_Name);
        GlobalOuterColumns.Close();
        Observer.Observe('rows', Rows);
        Observer.Finish();
    end;

    [Test]
    procedure ReportDataset_DataItemFlowFieldColumns_EveryKind()
    // CLAIM: dataitem columns over a FlowField of every CalcFormula kind are calculated by the report; the Blob column of a row is written as it is stored.
    begin
        Initialize();
        Observer.Observe('dataset', Columns(Dataset(Report::"FFM QR Dataset")));
        Observer.Finish();
    end;

    [Test]
    procedure ReportDataset_GlobalRecordNeverCalculated_BlobAndFlowFieldColumns()
    // CLAIM: columns over a Blob field and over FlowFields of a global record that is only read with Get() are written with the stored Blob and the FlowField values as the record holds them.
    begin
        Initialize();
        Observer.Observe('dataset', Columns(Dataset(Report::"FFM QR Global Uncalculated")));
        Observer.Finish();
    end;

    [Test]
    procedure ReportDataset_GlobalRecordCalculated_BlobAndFlowFieldColumns()
    // CLAIM: the same columns after CalcFields of the Blob and the FlowFields are written with their values.
    begin
        Initialize();
        Observer.Observe('dataset', Columns(Dataset(Report::"FFM QR Global Calculated")));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryOpen(var Q: Query "FFM QR Columns")
    begin
        Q.Open();
    end;

    [TryFunction]
    local procedure TryOpenOrder(var Q: Query "FFM QR Order By Flow")
    begin
        Q.Open();
    end;

    local procedure ReadCodes(var Q: Query "FFM QR Columns"; ColumnName: Text; Filter: Text): Text
    var
        Result: Text;
    begin
        Q.SetFilter(Q.Code, '');
        case ColumnName of
            'SumC':
                Q.SetFilter(SumC, Filter);
            'NSumC':
                Q.SetFilter(NSumC, Filter);
            'AvgC':
                Q.SetFilter(AvgC, Filter);
            'MinC':
                Q.SetFilter(MinC, Filter);
            'MaxC':
                Q.SetFilter(MaxC, Filter);
            'CntC':
                Q.SetFilter(CntC, Filter);
            'ExC':
                Q.SetFilter(ExC, Filter);
            'LkC':
                Q.SetFilter(LkC, Filter);
        end;
        if not TryOpen(Q) then
            exit('open: ' + GetLastErrorText());
        while Q.Read() do
            Result += Q.Code + ',';
        Q.Close();
        Q.SetFilter(SumC, '');
        Q.SetFilter(NSumC, '');
        Q.SetFilter(AvgC, '');
        Q.SetFilter(MinC, '');
        Q.SetFilter(MaxC, '');
        Q.SetFilter(CntC, '');
        Q.SetFilter(ExC, '');
        Q.SetFilter(LkC, '');
        exit(Result);
    end;

    local procedure ReadOuterFilter(var Q: Query "FFM QR Outer Filter"): Text
    var
        Result: Text;
    begin
        if not TryOpenOuter(Q) then
            exit('open: ' + GetLastErrorText());
        while Q.Read() do
            Result += Q.TopCode + '/' + Format(Q.LineNo) + ',';
        Q.Close();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryOpenOuter(var Q: Query "FFM QR Outer Filter")
    begin
        Q.Open();
    end;

    local procedure Dataset(ReportId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        All: Text;
        Lf: Text[1];
    begin
        Lf[1] := 10;
        TempBlob.CreateOutStream(OutS);
        ClearLastError();
        if not Report.SaveAs(ReportId, '', ReportFormat::Xml, OutS) then
            exit('not saved: ' + GetLastErrorText());
        if not TempBlob.HasValue() then
            exit('empty');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            All += Line + Lf;
        end;
        exit(All);
    end;

    // The text of every <Column name="X">value</Column> of the dataset, as X=value; and a | between data items.
    local procedure Columns(Xml: Text): Text
    var
        Result: Text;
        At: Integer;
        NameEnd: Integer;
        ValueEnd: Integer;
        ColumnName: Text;
        Rest: Text;
    begin
        if not Xml.Contains('<Column name="') then
            exit(Xml);
        Rest := Xml;
        At := Rest.IndexOf('<Column name="');
        while At > 0 do begin
            Rest := Rest.Substring(At + StrLen('<Column name="'));
            NameEnd := Rest.IndexOf('">');
            ColumnName := Rest.Substring(1, NameEnd - 1);
            Rest := Rest.Substring(NameEnd + 2);
            ValueEnd := Rest.IndexOf('</Column>');
            Result += ColumnName + '=' + Rest.Substring(1, ValueEnd - 1) + ';';
            Rest := Rest.Substring(ValueEnd);
            At := Rest.IndexOf('<Column name="');
        end;
        exit(Result);
    end;

    local procedure Initialize()
    var
        D: Record "FFM QR Detail";
        H: Record "FFM QR Header";
        T: Record "FFM QR Top";
        L: Record "FFM QR Line";
        OutS: OutStream;
    begin
        D.DeleteAll();
        H.DeleteAll();
        T.DeleteAll();
        L.DeleteAll();
        AddDetail(1, 'H1', 10.5, 'alpha');
        AddDetail(2, 'H1', 20, 'bravo');
        AddDetail(3, 'H1', 40.25, 'charlie');
        AddDetail(4, 'H1', 80, 'delta');
        AddDetail(5, 'H2', 7, 'echo');
        AddDetail(6, 'H2', 14, 'foxtrot');
        H.Init();
        H.Code := 'H1';
        H.Picture.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('Hello H1');
        H.Insert();
        H.Init();
        H.Code := 'H2';
        H.Insert();
        H.Init();
        H.Code := 'H3';
        H.Insert();
        AddTop('T1');
        AddTop('T2');
        AddTop('T3');
        AddLine(1, 'T1', 'H1');
        AddLine(2, 'T1', 'H2');
        AddLine(3, 'T2', 'H3');
        AddLine(4, 'T2', 'NOHDR');
        AddLine(5, 'T3', 'H1');
    end;

    local procedure AddDetail(EntryNo: Integer; OwnerCode: Code[10]; Amount: Decimal; NameValue: Text[30])
    var
        D: Record "FFM QR Detail";
    begin
        D.Init();
        D."Entry No." := EntryNo;
        D.Owner := OwnerCode;
        D.Amt := Amount;
        D.Name := NameValue;
        D.Insert();
    end;

    local procedure AddTop(TopCode: Code[10])
    var
        T: Record "FFM QR Top";
    begin
        T.Init();
        T.Code := TopCode;
        T.Insert();
    end;

    local procedure AddLine(EntryNo: Integer; TopCode: Code[10]; HeaderCode: Code[10])
    var
        L: Record "FFM QR Line";
    begin
        L.Init();
        L."Entry No." := EntryNo;
        L."Top Code" := TopCode;
        L."Header Code" := HeaderCode;
        L.Insert();
    end;
}
