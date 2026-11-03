// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: tables and helper of PnH1Fix.al; SingleInstance log 70670 is used only by test codeunit 70679
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Probes-needed rows: Report.SaveAs dataset | Only Xml is produced; Pdf, Html, Word and Excel of a ProcessingOnly report and of a report with no layout
// (result, last error, triggers run, size of the stream), the ReportFormat ordinals; and: a report that is not ProcessingOnly or declares no layout when its run
// reaches the output (Run, RunModal, Execute).
// BC versions: 29 (27 and 28 by CI)

codeunit 70670 "LT PnH SaveAs Log"
{
    SingleInstance = true;

    var
        Entries: Text;

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
}

report 70671 "LT PnH SaveAsPO"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT PnH Row")
        {
            trigger OnPreDataItem()
            begin
                L.Add('row pre');
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id));
            end;

            trigger OnPostDataItem()
            begin
                L.Add('row post');
            end;
        }
    }

    trigger OnPreReport()
    begin
        L.Add('pre');
    end;

    trigger OnPostReport()
    begin
        L.Add('post');
    end;

    var
        L: Codeunit "LT PnH SaveAs Log";
}

report 70672 "LT PnH SaveAsCols"
{
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT PnH Row")
        {
            column(RowId; Row.Id) { }
            column(RowName; Row.Name) { }

            trigger OnPreDataItem()
            begin
                L.Add('row pre');
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id));
            end;
        }
    }

    trigger OnPreReport()
    begin
        L.Add('pre');
    end;

    trigger OnPostReport()
    begin
        L.Add('post');
    end;

    var
        L: Codeunit "LT PnH SaveAs Log";
}

codeunit 70679 "LT PnH SaveAs Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT PnH SaveAs Log";
        Helper: Codeunit "LT PnH Helper";

    local procedure Start()
    begin
        Helper.Seed();
        L.Take();
        ClearLastError();
    end;

    [TryFunction]
    local procedure TrySaveAs(ReportId: Integer; Fmt: ReportFormat; var Ok: Boolean; var Size: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Ok := Report.SaveAs(ReportId, '', Fmt, OutS);
        Size := TempBlob.Length();
    end;

    [TryFunction]
    local procedure TryRunNo()
    begin
        Report.Run(Report::"LT PnH SaveAsCols");
    end;

    [TryFunction]
    local procedure TryRunModalNo()
    begin
        Report.RunModal(Report::"LT PnH SaveAsCols");
    end;

    [TryFunction]
    local procedure TryExecuteNo()
    begin
        Report.Execute(Report::"LT PnH SaveAsCols", '');
    end;

    local procedure Formats(var Result: List of [ReportFormat])
    var
        Fmt: ReportFormat;
    begin
        Fmt := ReportFormat::Pdf;
        Result.Add(Fmt);
        Fmt := ReportFormat::Word;
        Result.Add(Fmt);
        Fmt := ReportFormat::Excel;
        Result.Add(Fmt);
        Fmt := ReportFormat::Html;
        Result.Add(Fmt);
        Fmt := ReportFormat::Xml;
        Result.Add(Fmt);
    end;

    local procedure Each(ReportId: Integer; FromIdx: Integer; ToIdx: Integer; var Observer: Codeunit "Probe Observer")
    var
        Fmts: List of [ReportFormat];
        Fmt: ReportFormat;
        Ok: Boolean;
        Size: Integer;
        Name: Text;
        i: Integer;
    begin
        Formats(Fmts);
        for i := FromIdx to ToIdx do begin
            Fmt := Fmts.Get(i);
            Name := Format(Fmt);
            Ok := false;
            Size := -1;
            ClearLastError();
            L.Take();
            Observer.Observe(Name + ' try', Format(TrySaveAs(ReportId, Fmt, Ok, Size)));
            Observer.ObserveError(Name + ' err');
            Observer.Observe(Name + ' result', Format(Ok));
            Observer.Observe(Name + ' has output', Format(Size > 0));
            Observer.Observe(Name + ' log', L.Take());
        end;
    end;

    [Test]
    procedure Formats_ProcessingOnly_PdfWord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Each(Report::"LT PnH SaveAsPO", 1, 2, Observer);
        Observer.Expect('Pdf try', 'Yes');
        Observer.Expect('Pdf err|text', 'Report 70671 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('Pdf err|code', 'ReportProcessingOnly');
        Observer.Expect('Pdf result', 'No');
        Observer.Expect('Pdf has output', 'No');
        Observer.Expect('Pdf log', '');
        Observer.Expect('Word try', 'Yes');
        Observer.Expect('Word err|text', 'Report 70671 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('Word err|code', 'ReportProcessingOnly');
        Observer.Expect('Word result', 'No');
        Observer.Expect('Word has output', 'No');
        Observer.Expect('Word log', '');
        Observer.Verify();
    end;

    [Test]
    procedure Formats_ProcessingOnly_ExcelHtmlXml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Each(Report::"LT PnH SaveAsPO", 3, 5, Observer);
        Observer.Expect('Excel try', 'Yes');
        Observer.Expect('Excel err|text', 'Report 70671 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('Excel err|code', 'ReportProcessingOnly');
        Observer.Expect('Excel result', 'No');
        Observer.Expect('Excel has output', 'No');
        Observer.Expect('Excel log', '');
        Observer.Expect('Html try', 'Yes');
        Observer.Expect('Html err|text', 'Report 70671 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('Html err|code', 'ReportProcessingOnly');
        Observer.Expect('Html result', 'No');
        Observer.Expect('Html has output', 'No');
        Observer.Expect('Html log', '');
        Observer.Expect('Xml try', 'Yes');
        Observer.Expect('Xml err|text', 'Report 70671 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('Xml err|code', 'ReportProcessingOnly');
        Observer.Expect('Xml result', 'No');
        Observer.Expect('Xml has output', 'No');
        Observer.Expect('Xml log', '');
        Observer.Verify();
    end;

    [Test]
    procedure Formats_NoLayout_PdfWord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Each(Report::"LT PnH SaveAsCols", 1, 2, Observer);
        Observer.Expect('Pdf try', 'Yes');
        Observer.Expect('Pdf err|text', 'Report 70672 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('Pdf err|code', 'ReportNoLayout');
        Observer.Expect('Pdf result', 'No');
        Observer.Expect('Pdf has output', 'No');
        Observer.Expect('Pdf log', '');
        Observer.Expect('Word try', 'Yes');
        Observer.Expect('Word err|text', 'Report 70672 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('Word err|code', 'ReportNoLayout');
        Observer.Expect('Word result', 'No');
        Observer.Expect('Word has output', 'No');
        Observer.Expect('Word log', '');
        Observer.Verify();
    end;

    [Test]
    procedure Formats_NoLayout_ExcelHtmlXml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Each(Report::"LT PnH SaveAsCols", 3, 5, Observer);
        Observer.Expect('Excel try', 'Yes');
        Observer.Expect('Excel err|text', 'Report 70672 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('Excel err|code', 'ReportNoLayout');
        Observer.Expect('Excel result', 'No');
        Observer.Expect('Excel has output', 'No');
        Observer.Expect('Excel log', '');
        Observer.Expect('Html try', 'Yes');
        Observer.Expect('Html err|text', 'Report 70672 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('Html err|code', 'ReportNoLayout');
        Observer.Expect('Html result', 'No');
        Observer.Expect('Html has output', 'No');
        Observer.Expect('Html log', '');
        Observer.Expect('Xml try', 'Yes');
        Observer.Expect('Xml err|text', '');
        Observer.Expect('Xml err|code', '');
        Observer.Expect('Xml result', 'Yes');
        Observer.Expect('Xml has output', 'Yes');
        Observer.Expect('Xml log', 'pre;row pre;row 1;row 2;row 3;post;');
        Observer.Verify();
    end;

    [Test]
    procedure ReportFormat_Ordinals()
    var
        Observer: Codeunit "Probe Observer";
        Fmt: ReportFormat;
    begin
        Fmt := ReportFormat::Pdf;
        Observer.Observe('Pdf', Format(Fmt) + '|' + Format(Fmt, 0, 2));
        Fmt := ReportFormat::Word;
        Observer.Observe('Word', Format(Fmt) + '|' + Format(Fmt, 0, 2));
        Fmt := ReportFormat::Excel;
        Observer.Observe('Excel', Format(Fmt) + '|' + Format(Fmt, 0, 2));
        Fmt := ReportFormat::Html;
        Observer.Observe('Html', Format(Fmt) + '|' + Format(Fmt, 0, 2));
        Fmt := ReportFormat::Xml;
        Observer.Observe('Xml', Format(Fmt) + '|' + Format(Fmt, 0, 2));
        Observer.Expect('Pdf', 'Pdf|2');
        Observer.Expect('Word', 'Word|3');
        Observer.Expect('Excel', 'Excel|1');
        Observer.Expect('Html', 'Html|5');
        Observer.Expect('Xml', 'Xml|4');
        Observer.Verify();
    end;

    [Test]
    procedure Instance_SaveAs_Pdf_ProcessingOnly()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT PnH SaveAsPO";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Ok: Boolean;
    begin
        Start();
        TempBlob.CreateOutStream(OutS);
        Ok := Rpt.SaveAs('', ReportFormat::Pdf, OutS);
        Observer.Observe('result', Format(Ok));
        Observer.Observe('has output', Format(TempBlob.Length() > 0));
        Observer.Observe('last error', GetLastErrorText());
        Observer.Observe('log', L.Take());
        Observer.Expect('result', 'No');
        Observer.Expect('has output', 'No');
        Observer.Expect('last error', 'Report 70671 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    procedure Xml_ProcessingOnly_Dataset_Shape()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Whole: Text;
    begin
        Start();
        TempBlob.CreateOutStream(OutS);
        Observer.Observe('result', Format(Report.SaveAs(Report::"LT PnH SaveAsPO", '', ReportFormat::Xml, OutS)));
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Whole += Line.Trim();
        end;
        Observer.Observe('has DataSet', Format(Whole.Contains('<DataSet')));
        Observer.Observe('has DataItem Row', Format(Whole.Contains('name="Row"')));
        Observer.Observe('has Id column', Format(Whole.Contains('RowId')));
        Observer.Observe('log', L.Take());
        Observer.Expect('result', 'No');
        Observer.Expect('has DataSet', 'No');
        Observer.Expect('has DataItem Row', 'No');
        Observer.Expect('has Id column', 'No');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    procedure NotProcessingOnly_NoLayout_Run_RunModal_Execute()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Observer.Observe('run', Format(TryRunNo()));
        Observer.ObserveError('run');
        Observer.Observe('run log', L.Take());
        Observer.Observe('runmodal', Format(TryRunModalNo()));
        Observer.ObserveError('runmodal');
        Observer.Observe('runmodal log', L.Take());
        Observer.Observe('execute', Format(TryExecuteNo()));
        Observer.ObserveError('execute');
        Observer.Observe('execute log', L.Take());
        Observer.Expect('run', 'No');
        Observer.Expect('run|text', 'Report 70672 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('run|code', 'ReportNoLayout');
        Observer.Expect('run log', '');
        Observer.Expect('runmodal', 'No');
        Observer.Expect('runmodal|text', 'Report 70672 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('runmodal|code', 'ReportNoLayout');
        Observer.Expect('runmodal log', '');
        Observer.Expect('execute', 'No');
        Observer.Expect('execute|text', 'Report 70672 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('execute|code', 'ReportNoLayout');
        Observer.Expect('execute log', '');
        Observer.Verify();
    end;
}
