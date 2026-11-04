// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained enum 68370, table 68371, reports 68372..68374,
//                codeunits 68375 (log) and 68376 (tests); Base Application table "Company Information"
// Probe: written against a real BC 27.5 service tier on Linux (en-US); every literal below is what that
// tier produced. Other BC versions were not measured.
//
// Pins what Report.SaveAs(.., ReportFormat::Xml, ..) writes for each kind of column and for the
// Labels block, and how it fails:
//  - one <Column> per column in declaration order; text escaped; Integer, Code, BigInteger as digits;
//    Decimal with a decimalformatter attribute (#,##0.00 for a field with AutoFormatType, #,##0.000 for
//    DecimalPlaces = 3, #,##0.0 for an expression with DecimalPlaces = 1 : 1) and the full value;
//    Date m/d/yyyy; Time and DateTime in the en-US form with a narrow no-break space (U+202F) before AM/PM; Boolean True/False; an Option
//    and an Enum as their captions; Duration as words; Guid without braces; an expression column as
//    its value; two columns may name the same field.
//  - IncludeCaption = true adds a <Labels> block with a <Label name="<Column>Caption"> element.
//  - A data item over "Company Information" shows the company's name.
//  - A ProcessingOnly report is refused: false, "Report <id> is a processing-only report. Output cannot
//    be rendered and saved to a file." / ReportProcessingOnly, no trigger runs, no bytes.
//  - An error raised in a trigger of a report with a layout: false, the error's own text and the code
//    "Dialog", the data item stops at the first error, no bytes.
// BC versions: 27.5

enum 68370 "Probe Col Enum"
{
    Extensible = true;

    value(0; Zero) { Caption = 'Zero cap'; }
    value(1; One) { Caption = 'One cap'; }
}

table 68371 "Probe Col Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { Caption = 'Id caption'; }
        field(2; Txt; Text[30]) { }
        field(3; Cod; Code[10]) { }
        field(4; Dec; Decimal) { AutoFormatType = 1; }
        field(5; Dt; Date) { }
        field(6; Tm; Time) { }
        field(7; Dtm; DateTime) { }
        field(8; Bl; Boolean) { }
        field(9; Opt; Option)
        {
            OptionMembers = Alpha,Beta,Gamma;
            OptionCaption = 'Alpha cap,Beta cap,Gamma cap';
        }
        field(10; En; Enum "Probe Col Enum") { }
        field(11; Big; BigInteger) { }
        field(12; Dur; Duration) { }
        field(13; Gd; Guid) { }
        field(14; Dec3; Decimal) { DecimalPlaces = 3 : 3; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 68372 "Probe Col Types Report"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(Row; "Probe Col Table")
        {
            column(IdC; Id) { IncludeCaption = true; }
            column(TxtC; Txt) { }
            column(CodC; Cod) { }
            column(DecC; Dec) { }
            column(DtC; Dt) { }
            column(TmC; Tm) { }
            column(DtmC; Dtm) { }
            column(BlC; Bl) { }
            column(OptC; Opt) { }
            column(EnC; En) { }
            column(BigC; Big) { }
            column(DurC; Dur) { }
            column(GdC; Gd) { }
            column(Dec3C; Dec3) { }
            column(Expr; Id * 2) { }
            column(ExprDec; Dec * 1.5) { DecimalPlaces = 1 : 1; }
            column(TxtAgain; Txt) { }
            column(OptTxt; Format(Opt)) { }
        }
        dataitem(CI; "Company Information")
        {
            column(CIName; Name) { }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/ProbeColTypesLayout_4.rdl';
            Caption = 'Probe layout';
        }
    }
}

report 68373 "Probe Col Processing Only"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "Probe Col Table")
        {
            column(IdC; Id) { }

            trigger OnAfterGetRecord()
            begin
                ColLog.Add('Row' + Format(Id));
            end;
        }
    }

    var
        ColLog: Codeunit "Probe Col Log";

    trigger OnPostReport()
    begin
        ColLog.Add('PostReport');
    end;
}

report 68374 "Probe Col Error Report"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(Row; "Probe Col Table")
        {
            column(IdC; Id) { }

            trigger OnAfterGetRecord()
            begin
                ColLog.Add('Row' + Format(Id));
                Error('boom %1', Id);
            end;
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/ProbeColErrorLayout.rdl';
            Caption = 'Probe error layout';
        }
    }

    var
        ColLog: Codeunit "Probe Col Log";
}

codeunit 68375 "Probe Col Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

codeunit 68376 "Probe Col SaveAs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        ColLog: Codeunit "Probe Col Log";

    local procedure Seed()
    var
        ColRec: Record "Probe Col Table";
    begin
        ColRec.DeleteAll();
        ColRec.Init();
        ColRec.Id := 1;
        ColRec.Txt := 'x <&> y';
        ColRec.Cod := 'ABC';
        ColRec.Dec := 12.345678;
        ColRec.Dt := DMY2Date(5, 3, 2024);
        ColRec.Tm := 123456T;
        ColRec.Dtm := CreateDateTime(DMY2Date(5, 3, 2024), 123456T);
        ColRec.Bl := true;
        ColRec.Opt := ColRec.Opt::Beta;
        ColRec.En := ColRec.En::One;
        ColRec.Big := 1234567890123L;
        ColRec.Dur := 90061001;
        ColRec.Gd := '{11111111-2222-3333-4444-555555555555}';
        ColRec.Dec3 := 1.23456;
        ColRec.Insert();
        ColRec.Init();
        ColRec.Id := 2;
        ColRec.Insert();
        Commit();
        ColLog.Take();
    end;

    local procedure DatasetText(ReportId: Integer; var Saved: Boolean): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        ClearLastError();
        Saved := Report.SaveAs(ReportId, '', ReportFormat::Xml, OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    local procedure Between(Text: Text; FromMarker: Text; ToMarker: Text): Text
    var
        StartAt: Integer;
        Rest: Text;
    begin
        StartAt := Text.IndexOf(FromMarker);
        Assert.IsTrue(StartAt > 0, 'marker ' + FromMarker);
        Rest := Text.Substring(StartAt);
        exit(Rest.Substring(1, Rest.IndexOf(ToMarker) - 1));
    end;

    local procedure StripIdentity(Block: Text): Text
    var
        StartAt: Integer;
        EndAt: Integer;
        Rest: Text;
        Result: Text;
    begin
        // BC 28.5 adds ` tableId="<id>" systemId="<guid>"` to every DataItem element.
        Rest := Block;
        while Rest.Contains(' tableId="') do begin
            StartAt := Rest.IndexOf(' tableId="');
            EndAt := Rest.IndexOf('" systemId="') + StrLen('" systemId="');
            EndAt := EndAt + Rest.Substring(EndAt).IndexOf('"') - 1;
            Result += Rest.Substring(1, StartAt - 1);
            Rest := Rest.Substring(EndAt + 1);
        end;
        exit(Result + Rest);
    end;

    [Test]
    procedure SaveAs_Xml_ColumnsOfEveryType_ExactText()
    var
        Saved: Boolean;
        Block: Text;
        Nnbsp: Text[1];
    begin
        Seed();
        // The en-US time format of this tier puts a narrow no-break space (U+202F) before AM/PM.
        Nnbsp[1] := 32; // a plain space: the Windows tier writes no narrow no-break space before AM/PM

        Block := StripIdentity(DatasetText(Report::"Probe Col Types Report", Saved));

        Assert.IsTrue(Saved, 'SaveAs');
        Assert.AreEqual(
            '    <DataItem language="en-US" formatRegion="en-US" name="Row">|' +
            '      <Columns>|' +
            '        <Column name="IdC">1</Column>|' +
            '        <Column name="TxtC">x &lt;&amp;&gt; y</Column>|' +
            '        <Column name="CodC">ABC</Column>|' +
            '        <Column name="DecC" decimalformatter="#,##0.00">12.345678</Column>|' +
            '        <Column name="DtC">3/5/2024</Column>|' +
            '        <Column name="TmC">12:34:56' + Nnbsp + 'PM</Column>|' +
            '        <Column name="DtmC">3/5/2024 12:34:56' + Nnbsp + 'PM</Column>|' +
            '        <Column name="BlC">True</Column>|' +
            '        <Column name="OptC">Beta cap</Column>|' +
            '        <Column name="EnC">One cap</Column>|' +
            '        <Column name="BigC">1234567890123</Column>|' +
            '        <Column name="DurC">1 day 1 hour 1 minute 1 second 1 millisecond</Column>|' +
            '        <Column name="GdC">11111111-2222-3333-4444-555555555555</Column>|' +
            '        <Column name="Dec3C" decimalformatter="#,##0.000">1.23456</Column>|' +
            '        <Column name="Expr">2</Column>|' +
            '        <Column name="ExprDec" decimalformatter="#,##0.0">18.5185170</Column>|' +
            '        <Column name="TxtAgain">x &lt;&amp;&gt; y</Column>|' +
            '        <Column name="OptTxt">Beta cap</Column>|' +
            '      </Columns>|' +
            '    </DataItem>|',
            Between(Block, '    <DataItem language="en-US" formatRegion="en-US" name="Row">|      <Columns>|        <Column name="IdC">1', '    <DataItem language="en-US" formatRegion="en-US" name="Row">|      <Columns>|        <Column name="IdC">2'),
            'first row');
    end;

    [Test]
    procedure SaveAs_Xml_IncludeCaption_WritesALabel_AndTheSecondRowIsInitialValues()
    var
        Saved: Boolean;
        Text: Text;
    begin
        Seed();

        Text := DatasetText(Report::"Probe Col Types Report", Saved);

        Assert.AreEqual('  <Labels>|    <Label name="IdCCaption">Id caption</Label>|  </Labels>|', Between(Text, '  <Labels>', '  <DataItems>'), 'labels');
        Assert.IsTrue(Text.Contains('        <Column name="IdC">2</Column>|        <Column name="TxtC"></Column>|        <Column name="CodC"></Column>|        <Column name="DecC" decimalformatter="#,##0.00">0</Column>|        <Column name="DtC"></Column>|'), 'second row start: blank text, zero decimal, undefined date');
        Assert.IsTrue(Text.Contains('        <Column name="OptC">Alpha cap</Column>|        <Column name="EnC">Zero cap</Column>|'), 'second row option and enum');
    end;

    [Test]
    procedure SaveAs_Xml_CompanyInformationItem_ShowsTheCompanyName()
    var
        CompanyInfo: Record "Company Information";
        Saved: Boolean;
        OldName: Text[100];
        Existed: Boolean;
        Text: Text;
    begin
        Seed();
        Existed := CompanyInfo.Get();
        if Existed then
            OldName := CompanyInfo.Name
        else begin
            CompanyInfo.Init();
            CompanyInfo.Insert();
        end;
        CompanyInfo.Name := 'Probe Company & Co';
        CompanyInfo.Modify();
        Commit();

        Text := DatasetText(Report::"Probe Col Types Report", Saved);

        CompanyInfo.Get();
        if Existed then begin
            CompanyInfo.Name := OldName;
            CompanyInfo.Modify();
        end else
            CompanyInfo.Delete();
        Commit();

        Assert.IsTrue(Text.Contains('<Column name="CIName">Probe Company &amp; Co</Column>'), 'company name column');
        Assert.IsTrue(Text.Contains('<CompanyName>' + CompanyName() + '</CompanyName>'), 'header company name is the session company, not the information record');
    end;

    [Test]
    procedure SaveAs_Xml_ProcessingOnlyReport_IsRefused()
    var
        Saved: Boolean;
        Text: Text;
    begin
        Seed();

        Text := DatasetText(Report::"Probe Col Processing Only", Saved);

        Assert.IsFalse(Saved, 'SaveAs');
        Assert.AreEqual('Report 68373 is a processing-only report. Output cannot be rendered and saved to a file.', GetLastErrorText(), 'text');
        Assert.AreEqual('ReportProcessingOnly', GetLastErrorCode(), 'code');
        Assert.AreEqual('', ColLog.Take(), 'no trigger ran');
        Assert.AreEqual('', Text, 'no bytes');
    end;

    [Test]
    procedure SaveAs_Xml_ErrorInATrigger_ReturnsFalseWithTheErrorText()
    var
        Saved: Boolean;
        Text: Text;
    begin
        Seed();

        Text := DatasetText(Report::"Probe Col Error Report", Saved);

        Assert.IsFalse(Saved, 'SaveAs');
        Assert.AreEqual('boom 1', GetLastErrorText(), 'text');
        Assert.AreEqual('Dialog', GetLastErrorCode(), 'code');
        Assert.AreEqual('Row1;', ColLog.Take(), 'the data item stops at the first error');
        Assert.AreEqual('', Text, 'no bytes');
    end;
}
