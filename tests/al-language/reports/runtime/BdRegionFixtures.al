// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/reportinstance-formatregion-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects: log 81050, table 81051, helper 81071, reports 81068, 81069, 81072, 81073, 81076
// Probe: corpus issue 657. The log codeunit, a SaveAs Xml reader, the CurrReport.Language / CurrReport.FormatRegion setter reports, the
// decimalformatter report and the SummaryML report.
// BC versions: 27-29

codeunit 81050 "BD Region Log"
{
    SingleInstance = true;

    var
        Lines: Text;
        RegionValue: Text;
        LanguageValue: Integer;
        RegionSet: Boolean;

    procedure Add(Tag: Text; Value: Text)
    begin
        Lines += Tag + '=' + Value + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Lines;
        Lines := '';
        exit(Result);
    end;

    procedure SetCulture(NewRegion: Text; NewRegionSet: Boolean; NewLanguage: Integer)
    begin
        RegionValue := NewRegion;
        RegionSet := NewRegionSet;
        LanguageValue := NewLanguage;
        Lines := '';
    end;

    procedure GetRegion(): Text
    begin
        exit(RegionValue);
    end;

    procedure HasRegion(): Boolean
    begin
        exit(RegionSet);
    end;

    procedure GetLanguage(): Integer
    begin
        exit(LanguageValue);
    end;
}

table 81051 "BD Amount Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Plain; Decimal) { }
        field(3; Places25; Decimal) { DecimalPlaces = 2 : 5; }
        field(4; Places00; Decimal) { DecimalPlaces = 0 : 0; }
        field(5; Auto1; Decimal) { AutoFormatType = 1; }
        field(6; Auto2; Decimal) { AutoFormatType = 2; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 81071 "BD Region Helper"
{
    // The SaveAs Xml text read as UTF-8, lines joined with |.
    procedure SaveAsXml(ReportId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(ReportId, '', ReportFormat::Xml, OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line.Trim() + '|';
        end;
        exit(Result);
    end;

    // The columns of the dataset as name[attributes]=value; (the text between <Column name=" and </Column>).
    procedure Columns(Xml: Text): Text
    var
        At: Integer;
        Piece: Text;
        Result: Text;
        Close: Integer;
    begin
        At := StrPos(Xml, '<Column name="');
        while At > 0 do begin
            Xml := CopyStr(Xml, At + StrLen('<Column name="'));
            Close := StrPos(Xml, '</Column>');
            if Close = 0 then
                exit(Result + '<unclosed>');
            Piece := CopyStr(Xml, 1, Close - 1);
            Result += Piece.Replace('">', '=').Replace('" ', '[').Replace('="', ':') + ';';
            Xml := CopyStr(Xml, Close);
            At := StrPos(Xml, '<Column name="');
        end;
        exit(Result);
    end;

    // The lines of the header (before <DataItems>) that name a region, a language or a culture, and the ReportDataSet start tag.
    procedure HeaderFacts(Xml: Text): Text
    var
        Parts: List of [Text];
        Part: Text;
        Result: Text;
        At: Integer;
    begin
        At := StrPos(Xml, '<DataItems>');
        if At > 0 then
            Xml := CopyStr(Xml, 1, At - 1);
        Parts := Xml.Split('|');
        foreach Part in Parts do
            if Part.StartsWith('<ReportDataSet') or Part.Contains('egion') or Part.Contains('anguage') or Part.Contains('ulture') then
                Result += Part.Replace(' id="', ' id:').Replace('" ', ' ') + '|';
        exit(Result);
    end;
}

// CurrReport.Language and CurrReport.FormatRegion set in OnPreReport from the log; a report without the FormatRegion property.
report 81068 "BD Region Setter"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(AmtCol; Amt) { }
            column(NegCol; Neg) { }
            column(D1Col; D1) { }
            column(D2Col; D2) { }
            column(DT1Col; DT1) { }
            column(DT2Col; DT2) { }
            column(T1Col; T1) { }
            column(T2Col; T2) { }
            column(TextsCol; Texts) { }

            trigger OnAfterGetRecord()
            begin
                Texts := Fmt();
                Log.Add('get', Fmt());
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        Neg := -1234.5;
        D1 := DMY2Date(31, 1, 2025);
        D2 := DMY2Date(5, 3, 2024);
        T1 := 143015T;
        T2 := 090507T;
        DT1 := CreateDateTime(D1, T1);
        DT2 := CreateDateTime(D2, T2);
    end;

    trigger OnPreReport()
    begin
        Log.Add('before', Fmt() + ' language=' + Format(CurrReport.Language()) + ' region=[' + CurrReport.FormatRegion() + ']');
        if Log.GetLanguage() <> 0 then
            CurrReport.Language := Log.GetLanguage();
        if Log.HasRegion() then
            CurrReport.FormatRegion := Log.GetRegion();
        Log.Add('after', Fmt() + ' language=' + Format(CurrReport.Language()) + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post', Fmt());
    end;

    local procedure Fmt(): Text
    begin
        exit(Format(Amt) + '#' + Format(Neg) + '#' + Format(D1) + '#' + Format(D2) + '#' + Format(D2, 0, 4) + '#' + Format(DT1) + '#' + Format(DT2) + '#' + Format(T1) + '#' + Format(T2));
    end;

    var
        Log: Codeunit "BD Region Log";
        Amt: Decimal;
        Neg: Decimal;
        D1: Date;
        D2: Date;
        DT1: DateTime;
        DT2: DateTime;
        T1: Time;
        T2: Time;
        Texts: Text;
}

// The same setter as a processing-only report (started with Report.Run).
report 81069 "BD Region Setter Proc"
{
    UsageCategory = None;
    UseRequestPage = false;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));

            trigger OnAfterGetRecord()
            begin
                Log.Add('get', Fmt());
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        Neg := -1234.5;
        D1 := DMY2Date(31, 1, 2025);
        D2 := DMY2Date(5, 3, 2024);
        T1 := 143015T;
        T2 := 090507T;
        DT1 := CreateDateTime(D1, T1);
        DT2 := CreateDateTime(D2, T2);
    end;

    trigger OnPreReport()
    begin
        Log.Add('before', Fmt() + ' language=' + Format(CurrReport.Language()) + ' region=[' + CurrReport.FormatRegion() + ']');
        if Log.GetLanguage() <> 0 then
            CurrReport.Language := Log.GetLanguage();
        if Log.HasRegion() then
            CurrReport.FormatRegion := Log.GetRegion();
        Log.Add('after', Fmt() + ' language=' + Format(CurrReport.Language()) + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post', Fmt());
    end;

    local procedure Fmt(): Text
    begin
        exit(Format(Amt) + '#' + Format(Neg) + '#' + Format(D1) + '#' + Format(D2) + '#' + Format(D2, 0, 4) + '#' + Format(DT1) + '#' + Format(DT2) + '#' + Format(T1) + '#' + Format(T2));
    end;

    var
        Log: Codeunit "BD Region Log";
        Amt: Decimal;
        Neg: Decimal;
        D1: Date;
        D2: Date;
        DT1: DateTime;
        DT2: DateTime;
        T1: Time;
        T2: Time;
}

// CurrReport.FormatRegion set in OnPreReport of a report that has the FormatRegion property (de-DE).
report 81076 "BD Region Setter De"
{
    UsageCategory = None;
    UseRequestPage = false;
    FormatRegion = 'de-DE';

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(AmtCol; Amt) { }
            column(D2Col; D2) { }
            column(DT2Col; DT2) { }
            column(TextsCol; Texts) { }

            trigger OnAfterGetRecord()
            begin
                Texts := Fmt();
                Log.Add('get', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        D2 := DMY2Date(5, 3, 2024);
        DT2 := CreateDateTime(D2, 090507T);
    end;

    trigger OnPreReport()
    begin
        Log.Add('before', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
        if Log.HasRegion() then
            CurrReport.FormatRegion := Log.GetRegion();
        Log.Add('after', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    local procedure Fmt(): Text
    begin
        exit(Format(Amt) + '#' + Format(D2) + '#' + Format(DT2));
    end;

    var
        Log: Codeunit "BD Region Log";
        Amt: Decimal;
        D2: Date;
        DT2: DateTime;
        Texts: Text;
}

// decimalformatter of Decimal columns: variables with 0 to 6 decimals, an expression, and table fields with and without DecimalPlaces / AutoFormatType.
report 81072 "BD Decimal Formatter"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "BD Amount Row")
        {
            column(Plain; Plain) { }
            column(Places25; Places25) { }
            column(Places00; Places00) { }
            column(Auto1; Auto1) { }
            column(Auto2; Auto2) { }
            column(V0; V0) { }
            column(V1; V1) { }
            column(V2; V2) { }
            column(V3; V3) { }
            column(V4; V4) { }
            column(V5; V5) { }
            column(V6; V6) { }
            column(VNeg3; VNeg3) { }
            column(VSmall; VSmall) { }
            column(VExpr; V3 * 2) { }
            column(VExpr2; Plain + 1) { }
        }
    }

    trigger OnInitReport()
    begin
        V0 := 1234;
        V1 := 1234.5;
        V2 := 1234.56;
        V3 := 1234.567;
        V4 := 1234.5678;
        V5 := 1234.56789;
        V6 := 1234.567891;
        VNeg3 := -1234.567;
        VSmall := 0.125;
    end;

    var
        V0: Decimal;
        V1: Decimal;
        V2: Decimal;
        V3: Decimal;
        V4: Decimal;
        V5: Decimal;
        V6: Decimal;
        VNeg3: Decimal;
        VSmall: Decimal;
}

// SummaryML of layouts: with ENU, DEU, FRA, DAN and NLD entries; without an ENU entry; with one DAN entry only.
report 81073 "BD Summary Langs"
{
    UsageCategory = None;
    DefaultRenderingLayout = SumAll;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(NumCol; Number) { }
        }
    }

    rendering
    {
        layout(SumAll)
        {
            Type = RDLC;
            LayoutFile = './reports/runtime/BdSumAll.rdlc';
            SummaryML = ENU = 'English all', DEU = 'Deutsch alle', FRA = 'Francais tous', DAN = 'Dansk alle', NLD = 'Nederlands alle';
        }
        layout(SumNoEnu)
        {
            Type = RDLC;
            LayoutFile = './reports/runtime/BdSumNoEnu.rdlc';
            SummaryML = DEU = 'Deutsch ohne', FRA = 'Francais sans';
        }
        layout(SumDanOnly)
        {
            Type = RDLC;
            LayoutFile = './reports/runtime/BdSumDan.rdlc';
            SummaryML = DAN = 'Kun dansk';
        }
    }
}
