// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/reportinstance-language-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); Temp Blob (System Application); own reports 96770 and 96771, codeunits 96772 and 96775.
// Probe: the area table of al-runner reports ("Format after CurrReport.Language in a report not started by Run"). reports/
//   W3ReportObjectIdPreviewLanguage.al:599 Language_Set1031_FormatAndColumns shows that Format changes after CurrReport.Language := 1031 in a
//   SaveAs (Format of a Boolean writes Ja) but not which texts change. This file sets CurrReport.Language := 2067 (Dutch, Belgium) and records
//   the Format texts of Date, Decimal, Boolean, Time, DateTime, Integer and the Month Text / Weekday Text parts, in OnPreReport, OnAfterGetRecord
//   and OnPostReport and after the report ends, for each way a report is started: variable and static SaveAs (Xml), variable and static Execute,
//   variable Run and static RunModal (control: started by Run), a procedure of a report variable that is not running, the Language of the report
//   variable before SaveAs, and Language with FormatRegion nl-BE.
// Area: reports/runtime, CurrReport.Language and Format.
// BC versions: 27.5, 28.5, 29.0. The expected values are what the corpus CI legs returned (BC28PLUS where 27.5 differs).

codeunit 96772 "LT RLN Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        ModeValue: Text;

    procedure SetMode(NewMode: Text)
    begin
        ModeValue := NewMode;
        Entries := '';
    end;

    procedure Mode(): Text
    begin
        exit(ModeValue);
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    // The Format texts the probe compares, in a short form.
    procedure Formats(): Text
    var
        D: Date;
    begin
        D := DMY2Date(25, 12, 2024);
        exit('d=' + Format(D) + ' d4=' + Format(D, 0, 4) + ' mw=' + Format(D, 0, '<Month Text> <Weekday Text>') +
            ' n=' + Format(1234567.891) + ' p=' + Format(1234.5, 0, '<Precision,2:2><Standard Format,0>') + ' i=' + Format(1234567) +
            ' b=' + Format(true) + '/' + Format(false) + ' t=' + Format(143005T) + ' dt=' + Format(CreateDateTime(D, 143005T)) +
            ' gl=' + Format(GlobalLanguage()));
    end;
}

report 96770 "LT RLN Data Rpt"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(DecC; DecVar)
            {
            }
            column(DateC; DateVar)
            {
            }
            column(TimeC; TimeVar)
            {
            }
            column(BoolC; BoolVar)
            {
            }
            column(TextC; TextVar)
            {
            }

            trigger OnAfterGetRecord()
            begin
                DecVar := 1234.5;
                DateVar := DMY2Date(25, 12, 2024);
                TimeVar := 143005T;
                BoolVar := true;
                TextVar := Format(DateVar) + ' ' + Format(DecVar) + ' ' + Format(BoolVar);
                L.Add('row ' + L.Formats());
            end;
        }
    }

    var
        L: Codeunit "LT RLN Log";
        DecVar: Decimal;
        DateVar: Date;
        TimeVar: Time;
        BoolVar: Boolean;
        TextVar: Text;

    trigger OnPreReport()
    begin
        case L.Mode() of
            'lang':
                CurrReport.Language := 2067;
            'lang region':
                begin
                    CurrReport.Language := 2067;
                    CurrReport.FormatRegion := 'nl-BE';
                end;
        end;
        L.Add('pre lang=' + Format(CurrReport.Language) + ' region=[' + CurrReport.FormatRegion + '] ' + L.Formats());
    end;

    trigger OnPostReport()
    begin
        L.Add('post ' + L.Formats());
    end;
}

report 96771 "LT RLN Proc Rpt"
{
    UsageCategory = None;
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + L.Formats());
            end;
        }
    }

    var
        L: Codeunit "LT RLN Log";

    trigger OnPreReport()
    begin
        CurrReport.Language := 2067;
        L.Add('pre lang=' + Format(CurrReport.Language) + ' ' + L.Formats());
    end;

    trigger OnPostReport()
    begin
        L.Add('post ' + L.Formats());
    end;

    // Called on a report variable that is not running.
    procedure SetLanguageAndFormat(): Text
    begin
        CurrReport.Language := 2067;
        exit('lang=' + Format(CurrReport.Language) + ' ' + L.Formats());
    end;

    procedure FormatsOnly(): Text
    begin
        exit('lang=' + Format(CurrReport.Language) + ' ' + L.Formats());
    end;
}

codeunit 96775 "LT RLN Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT RLN Log";

    local procedure Lines(Xml: Text; Marker: Text): Text
    var
        Line: Text;
        Lf: Text[1];
        Result: Text;
    begin
        Lf[1] := 10;
        foreach Line in Xml.Split(Lf) do
            if Line.Contains(Marker) then
                Result += Line.Trim() + '|';
        exit(Result);
    end;

    local procedure Dataset(var TempBlob: Codeunit "Temp Blob"; var Observer: Codeunit "Probe Observer")
    var
        InS: InStream;
        Xml: Text;
        Part: Text;
        Lf: Text[1];
    begin
        Lf[1] := 10;
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Part);
            Xml += Part + Lf;
        end;
        Observer.Observe('columns', Lines(Xml, '<Column '));
        Observer.Observe('items', Lines(Xml, '<DataItem '));
    end;

    [TryFunction]
    local procedure TryProcedure(var Rpt: Report "LT RLN Proc Rpt"; var Result: Text)
    begin
        Result := Rpt.SetLanguageAndFormat();
    end;

    [TryFunction]
    local procedure TryExecuteVar(var Rpt: Report "LT RLN Proc Rpt")
    begin
        Rpt.Execute('');
    end;

    [TryFunction]
    local procedure TryExecuteStatic()
    begin
        Report.Execute(Report::"LT RLN Proc Rpt", '');
    end;

    [Test]
    procedure RLN_SaveAsVariable_Language2067()
    var
        Rpt: Report "LT RLN Data Rpt";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
    begin
        L.SetMode('lang');
        TempBlob.CreateOutStream(OutS);
        Observer.Observe('saved', Format(Rpt.SaveAs('', ReportFormat::Xml, OutS)));
        Observer.Observe('log', L.Take());
        Dataset(TempBlob, Observer);
        Observer.Observe('after', L.Formats());
        Observer.Expect('saved', 'Yes');
        Observer.Expect('log', 'pre lang=2067 region=[] d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033;row d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033;post d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033;');
        Observer.Expect('columns', '<Column name="DecC" decimalformatter="#,##0.00">1234.5</Column>|<Column name="DateC">12/25/2024</Column>|<Column name="TimeC">2:30:05 PM</Column>|<Column name="BoolC">True</Column>|<Column name="TextC">12/25/24 1,234.5 Ja</Column>|');
#if BC28PLUS
        Observer.Expect('items', '<DataItem language="nl-BE" formatRegion="en-US" name="Row" tableId="2000000026">|');
#else
        Observer.Expect('items', '<DataItem language="nl-BE" formatRegion="en-US" name="Row">|');
#endif
        Observer.Expect('after', 'd=12/25/24 d4=December 25, 2024 mw=December Wednesday n=1,234,567.891 p=1,234.50 i=1234567 b=Yes/No t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033');
        Observer.Verify();
    end;

    [Test]
    procedure RLN_SaveAsStatic_Language2067()
    var
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
    begin
        L.SetMode('lang');
        TempBlob.CreateOutStream(OutS);
        Observer.Observe('saved', Format(Report.SaveAs(Report::"LT RLN Data Rpt", '', ReportFormat::Xml, OutS)));
        Observer.Observe('log', L.Take());
        Dataset(TempBlob, Observer);
        Observer.Observe('after', L.Formats());
        Observer.Expect('saved', 'Yes');
        Observer.Expect('log', 'pre lang=2067 region=[] d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033;row d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033;post d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033;');
        Observer.Expect('columns', '<Column name="DecC" decimalformatter="#,##0.00">1234.5</Column>|<Column name="DateC">12/25/2024</Column>|<Column name="TimeC">2:30:05 PM</Column>|<Column name="BoolC">True</Column>|<Column name="TextC">12/25/24 1,234.5 Ja</Column>|');
#if BC28PLUS
        Observer.Expect('items', '<DataItem language="nl-BE" formatRegion="en-US" name="Row" tableId="2000000026">|');
#else
        Observer.Expect('items', '<DataItem language="nl-BE" formatRegion="en-US" name="Row">|');
#endif
        Observer.Expect('after', 'd=12/25/24 d4=December 25, 2024 mw=December Wednesday n=1,234,567.891 p=1,234.50 i=1234567 b=Yes/No t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033');
        Observer.Verify();
    end;

    [Test]
    procedure RLN_SaveAsVariable_Language2067AndRegionNlBE()
    var
        Rpt: Report "LT RLN Data Rpt";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
    begin
        L.SetMode('lang region');
        TempBlob.CreateOutStream(OutS);
        Observer.Observe('saved', Format(Rpt.SaveAs('', ReportFormat::Xml, OutS)));
        Observer.Observe('log', L.Take());
        Dataset(TempBlob, Observer);
        Observer.Expect('saved', 'Yes');
        Observer.Expect('log', 'pre lang=2067 region=[nl-BE] d=25/12/24 d4=25 december 2024 mw=december woensdag n=1.234.567,891 p=1.234,50 i=1234567 b=Ja/Nee t=14:30:05 dt=25/12/24 14:30 gl=1033;row d=25/12/24 d4=25 december 2024 mw=december woensdag n=1.234.567,891 p=1.234,50 i=1234567 b=Ja/Nee t=14:30:05 dt=25/12/24 14:30 gl=1033;post d=25/12/24 d4=25 december 2024 mw=december woensdag n=1.234.567,891 p=1.234,50 i=1234567 b=Ja/Nee t=14:30:05 dt=25/12/24 14:30 gl=1033;');
        Observer.Expect('columns', '<Column name="DecC" decimalformatter="#,##0.00">1234,5</Column>|<Column name="DateC">25/12/2024</Column>|<Column name="TimeC">14:30:05</Column>|<Column name="BoolC">True</Column>|<Column name="TextC">25/12/24 1.234,5 Ja</Column>|');
#if BC28PLUS
        Observer.Expect('items', '<DataItem language="nl-BE" formatRegion="nl-BE" name="Row" tableId="2000000026">|');
#else
        Observer.Expect('items', '<DataItem language="nl-BE" formatRegion="nl-BE" name="Row">|');
#endif
        Observer.Verify();
    end;

    // The Language of the report variable set before SaveAs; nothing is set in the report.
    [Test]
    procedure RLN_SaveAsVariable_VariableLanguage2067()
    var
        Rpt: Report "LT RLN Data Rpt";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
    begin
        L.SetMode('');
        Rpt.Language := 2067;
        TempBlob.CreateOutStream(OutS);
        Observer.Observe('saved', Format(Rpt.SaveAs('', ReportFormat::Xml, OutS)));
        Observer.Observe('log', L.Take());
        Dataset(TempBlob, Observer);
        Observer.Observe('after', L.Formats());
        Observer.Expect('saved', 'Yes');
        Observer.Expect('log', 'pre lang=2067 region=[] d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033;row d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033;post d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033;');
        Observer.Expect('columns', '<Column name="DecC" decimalformatter="#,##0.00">1234.5</Column>|<Column name="DateC">12/25/2024</Column>|<Column name="TimeC">2:30:05 PM</Column>|<Column name="BoolC">True</Column>|<Column name="TextC">12/25/24 1,234.5 Ja</Column>|');
#if BC28PLUS
        Observer.Expect('items', '<DataItem language="nl-BE" formatRegion="en-US" name="Row" tableId="2000000026">|');
#else
        Observer.Expect('items', '<DataItem language="nl-BE" formatRegion="en-US" name="Row">|');
#endif
        Observer.Expect('after', 'd=12/25/24 d4=December 25, 2024 mw=December Wednesday n=1,234,567.891 p=1,234.50 i=1234567 b=Yes/No t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033');
        Observer.Verify();
    end;

    [Test]
    procedure RLN_Execute_VariableAndStatic_Language2067()
    var
        Rpt: Report "LT RLN Proc Rpt";
        Observer: Codeunit "Probe Observer";
    begin
        L.SetMode('');
        Observer.Observe('var ok', Format(TryExecuteVar(Rpt)));
        Observer.ObserveError('var');
        Observer.Observe('var log', L.Take());
        Observer.Observe('var after', L.Formats());
        Observer.Observe('static ok', Format(TryExecuteStatic()));
        Observer.ObserveError('static');
        Observer.Observe('static log', L.Take());
        Observer.Expect('var ok', 'Yes');
        Observer.Expect('var|text', '');
        Observer.Expect('var|code', '');
        Observer.Expect('var log', 'pre lang=2067 d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033;row d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033;post d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033;');
        Observer.Expect('var after', 'd=12/25/24 d4=December 25, 2024 mw=December Wednesday n=1,234,567.891 p=1,234.50 i=1234567 b=Yes/No t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033');
        Observer.Expect('static ok', 'Yes');
        Observer.Expect('static|text', '');
        Observer.Expect('static|code', '');
        Observer.Expect('static log', 'pre lang=2067 d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033;row d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033;post d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033;');
        Observer.Verify();
    end;

    // Control: a report started by Run (variable) and RunModal (static).
    [Test]
    procedure RLN_RunVariable_RunModalStatic_Language2067()
    var
        Rpt: Report "LT RLN Proc Rpt";
        Observer: Codeunit "Probe Observer";
    begin
        L.SetMode('');
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('run log', L.Take());
        Observer.Observe('run after', L.Formats());
        Report.RunModal(Report::"LT RLN Proc Rpt", false);
        Observer.Observe('runmodal log', L.Take());
        Observer.Expect('run log', 'pre lang=2067 d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033;row d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033;post d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033;');
        Observer.Expect('run after', 'd=12/25/24 d4=December 25, 2024 mw=December Wednesday n=1,234,567.891 p=1,234.50 i=1234567 b=Yes/No t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033');
        Observer.Expect('runmodal log', 'pre lang=2067 d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033;row d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033;post d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033;');
        Observer.Verify();
    end;

    // CurrReport.Language := 2067 in a procedure of a report variable that is not running, then Format there, in a second procedure of the
    // same variable, and in the test.
    [Test]
    procedure RLN_ProcedureOfAReportNotRunning_Language2067()
    var
        Rpt: Report "LT RLN Proc Rpt";
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        L.SetMode('');
        Observer.Observe('set ok', Format(TryProcedure(Rpt, Result)));
        Observer.ObserveError('set');
        Observer.Observe('set result', Result);
        Observer.Observe('second procedure', Rpt.FormatsOnly());
        Observer.Observe('test', L.Formats());
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set result', 'lang=2067 d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033');
        Observer.Expect('second procedure', 'lang=2067 d=12/25/24 d4=december 25, 2024 mw=december woensdag n=1,234,567.891 p=1,234.50 i=1234567 b=Ja/Nee t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033');
        Observer.Expect('test', 'd=12/25/24 d4=December 25, 2024 mw=December Wednesday n=1,234,567.891 p=1,234.50 i=1234567 b=Yes/No t= 2:30:05 PM dt=12/25/24 02:30 PM gl=1033');
        Observer.Verify();
    end;
}
