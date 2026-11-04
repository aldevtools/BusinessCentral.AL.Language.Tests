// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveaspdf-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (File, TemporaryPath, Report.SaveAs* to a file name and TestRequestPage.SaveAs* are Scope = OnPrem)
// Fixtures used: Probe Observer (69160); self-contained table 98600, reports 98601 and 98602 (hand-written layouts LtAmOpSave.rdlc and
// LtAmOpRp.rdlc), row log 98604, file helper 98605, test codeunit 98603
// Corpus #595 items 4-11 and 16-18 with an RDLC layout (the corpus CI runs the Mono RDLC renderer, rdlc_renderer: true): Report.SaveAsExcel,
// SaveAsHtml, SaveAsPdf and SaveAsWord, static (report id, file name, record) and on a Report variable (with and without SetTableView), and
// TestRequestPage.SaveAsExcel, SaveAsPdf and SaveAsWord from a request page handler. Per call: the return value, the last error, whether the
// file exists and its signature; RecordFilter_RowsTheDatasetReads pins the rows each form reads (the Record filter used).
// Pinned on every leg: SaveAsHtml returns false with 'The Html output format is not supported by the current report layout format.'
// (ReportUnsupportedFormat) and writes no file.
// Pinned on BC 27 and 28 only (#if not BC29PLUS): SaveAsPdf writes a one-page PDF; TestRequestPage.SaveAsPdf writes the PDF, the request page
// handler runs once, and the request page is closed afterwards (Cancel: 'The TestPage is not open.'). The BC 29 Linux container turns the
// renderer off at boot ("the side-service compatibility patch failed"), so on BC 29 these calls answer with the Linux stub text.
// SaveAsWord and SaveAsExcel, static, instance and from the request page: asserted with the Windows BC 27.5/28.5 values (Windows check
// 2026-10-20: the file is written, marker in word/document.xml or xl/worksheets/sheet1.xml) and were held on Linux until the bc-linux #144 fix:
// the Linux image failed inside the Mono renderer with 'The system encountered an internal error while rendering the report.'
// (ReportingService:Rpc; the request page forms raise it uncaught). Windows BC 29.0 (check 2026-10-20) gives the same values; held on 29
// until the bc-linux #143 fix (the BC 29 Linux container turned the renderer off at boot).
// PDF text is compressed: only the page count is asserted.
// BC versions: 27 - 29

table 98600 "LT AM OP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 98601 "LT AM OP Save Rpt"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = LtAmOpSave;

    dataset
    {
        dataitem(T; "LT AM OP Row")
        {
            column(Id; Id) { }
            column(Txt; Txt) { }

            trigger OnAfterGetRecord()
            begin
                RowLog.Add(Format(T.Id));
            end;
        }
    }

    rendering
    {
        layout(LtAmOpSave)
        {
            Type = RDLC;
            LayoutFile = './reports/layouts-saveas/LtAmOpSave.rdlc';
        }
    }

    var
        RowLog: Codeunit "LT AM OP Row Log";
}

codeunit 98604 "LT AM OP Row Log"
{
    SingleInstance = true;

    var
        Rows: Text;

    procedure Add(Row: Text)
    begin
        Rows += Row + ',';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Rows;
        Rows := '';
        exit(Result);
    end;
}

report 98602 "LT AM OP RP Rpt"
{
    UsageCategory = None;
    DefaultRenderingLayout = LtAmOpRp;

    dataset
    {
        dataitem(T; "LT AM OP Row")
        {
            column(Id; Id) { }
            column(Txt; Txt) { }

            trigger OnPreDataItem()
            begin
                T.SetFilter(Id, '>=%1', Threshold);
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ThresholdField; Threshold) { ApplicationArea = All; }
            }
        }
    }

    rendering
    {
        layout(LtAmOpRp)
        {
            Type = RDLC;
            LayoutFile = './reports/layouts-saveas/LtAmOpRp.rdlc';
        }
    }

    var
        Threshold: Integer;
}

codeunit 98605 "LT AM OP File Facts"
{
    procedure Seed()
    var
        Row: Record "LT AM OP Row";
        Index: Integer;
    begin
        Row.DeleteAll();
        for Index := 1 to 4 do begin
            Row.Id := Index;
            Row.Txt := 'row' + Format(Index);
            Row.Insert();
        end;
        Commit();
    end;

    procedure FreshName(Tag: Text; Ext: Text): Text
    var
        Name: Text;
    begin
        Name := TemporaryPath() + 'lt-am-op-' + Tag + '.' + Ext;
        if Exists(Name) then
            Erase(Name);
        exit(Name);
    end;

    // Observes whether the file exists, its signature and the layout text it carries, then erases it.
    procedure Describe(var Observer: Codeunit "Probe Observer"; Tag: Text; Name: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        SaveFile: File;
        InStr: InStream;
        OutStr: OutStream;
        Kind: Text;
    begin
        Observer.Observe(Tag + ' exists', Format(Exists(Name)));
        if not Exists(Name) then
            exit;
        SaveFile.Open(Name);
        SaveFile.CreateInStream(InStr);
        TempBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
        SaveFile.Close();
        Erase(Name);
        Kind := Head(TempBlob);
        Observer.Observe(Tag + ' kind', Kind);
        case Kind of
            'pdf':
                Observer.Observe(Tag + ' pdf pages', Format(PdfPages(TempBlob)));
            'zip':
                Observer.Observe(Tag + ' zip marker', ZipMarker(TempBlob));
            'markup':
                Observer.Observe(Tag + ' marker', Marker(AllText(TempBlob, TextEncoding::UTF8)));
        end;
    end;

    local procedure Head(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Txt: Text;
    begin
        if TempBlob.Length() = 0 then
            exit('empty');
        TempBlob.CreateInStream(InS, TextEncoding::Windows);
        InS.ReadText(Txt, 5);
        if Txt.StartsWith('%PDF-') then
            exit('pdf');
        if Txt.StartsWith('PK') then
            exit('zip');
        if Txt.StartsWith('<') then
            exit('markup');
        exit('other');
    end;

    local procedure AllText(var TempBlob: Codeunit "Temp Blob"; Encoding: TextEncoding): Text
    var
        InS: InStream;
        Line: Text;
        All: TextBuilder;
    begin
        TempBlob.CreateInStream(InS, Encoding);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            All.Append(Line);
            All.Append(' ');
        end;
        exit(All.ToText());
    end;

    [TryFunction]
    local procedure TryAllText(var TempBlob: Codeunit "Temp Blob"; Encoding: TextEncoding; var Content: Text)
    begin
        Content := AllText(TempBlob, Encoding);
    end;

    local procedure PdfPages(var TempBlob: Codeunit "Temp Blob"): Integer
    var
        Txt: Text;
        Pos: Integer;
        Pages: Integer;
    begin
        Txt := AllText(TempBlob, TextEncoding::Windows).Replace('/Type /Page', '/Type/Page');
        Pos := StrPos(Txt, '/Type/Page');
        while Pos > 0 do begin
            if CopyStr(Txt, Pos + 10, 1) <> 's' then
                Pages += 1;
            Txt := CopyStr(Txt, Pos + 10);
            Pos := StrPos(Txt, '/Type/Page');
        end;
        exit(Pages);
    end;

    local procedure Marker(Content: Text): Text
    var
        Pos: Integer;
        Rest: Text;
    begin
        Pos := StrPos(Content, 'AMTXT[');
        if Pos = 0 then
            exit('');
        Rest := CopyStr(Content, Pos);
        Pos := StrPos(Rest, ']');
        if Pos = 0 then
            exit(CopyStr(Rest, 1, 80));
        exit(CopyStr(Rest, 1, Pos));
    end;

    // The part name and layout text of the first XML part that carries the layout text: 'part=marker', or '' when none does.
    local procedure ZipMarker(var TempBlob: Codeunit "Temp Blob"): Text
    var
        DataCompression: Codeunit "Data Compression";
        EntryBlob: Codeunit "Temp Blob";
        Names: List of [Text];
        Name: Text;
        InS: InStream;
        EntryOut: OutStream;
        Length: Integer;
        Content: Text;
        Found: Text;
    begin
        TempBlob.CreateInStream(InS);
        DataCompression.OpenZipArchive(InS, false);
        DataCompression.GetEntryList(Names);
        foreach Name in Names do
            if (Found = '') and Name.EndsWith('.xml') then begin
                Clear(EntryBlob);
                EntryBlob.CreateOutStream(EntryOut);
                DataCompression.ExtractEntry(Name, EntryOut, Length);
                if not TryAllText(EntryBlob, TextEncoding::UTF8, Content) then
                    Content := '';
                if Marker(Content) <> '' then
                    Found := Name + '=' + Marker(Content);
            end;
        DataCompression.CloseZipArchive();
        exit(Found);
    end;
}

codeunit 98603 "LT AM OP SaveAs Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT AM OP File Facts";
        RowLog: Codeunit "LT AM OP Row Log";
        Target: Text;
        Kind: Text;

    [TryFunction]
    local procedure TryStatic(Fmt: Text; Name: Text; Filtered: Boolean; var Saved: Boolean)
    var
        Row: Record "LT AM OP Row";
    begin
        Row.SetFilter(Id, '>=%1', 3);
        case Fmt of
            'pdf':
                if Filtered then
                    Saved := Report.SaveAsPdf(Report::"LT AM OP Save Rpt", Name, Row)
                else
                    Saved := Report.SaveAsPdf(Report::"LT AM OP Save Rpt", Name);
            'docx':
                if Filtered then
                    Saved := Report.SaveAsWord(Report::"LT AM OP Save Rpt", Name, Row)
                else
                    Saved := Report.SaveAsWord(Report::"LT AM OP Save Rpt", Name);
            'xlsx':
                if Filtered then
                    Saved := Report.SaveAsExcel(Report::"LT AM OP Save Rpt", Name, Row)
                else
                    Saved := Report.SaveAsExcel(Report::"LT AM OP Save Rpt", Name);
            'html':
                if Filtered then
                    Saved := Report.SaveAsHtml(Report::"LT AM OP Save Rpt", Name, Row)
                else
                    Saved := Report.SaveAsHtml(Report::"LT AM OP Save Rpt", Name);
        end;
    end;

    [TryFunction]
    local procedure TryInstance(Fmt: Text; Name: Text; Filtered: Boolean; var Saved: Boolean)
    var
        Row: Record "LT AM OP Row";
        Rpt: Report "LT AM OP Save Rpt";
    begin
        if Filtered then begin
            Row.SetFilter(Id, '>=%1', 3);
            Rpt.SetTableView(Row);
        end;
        case Fmt of
            'pdf':
                Saved := Rpt.SaveAsPdf(Name);
            'docx':
                Saved := Rpt.SaveAsWord(Name);
            'xlsx':
                Saved := Rpt.SaveAsExcel(Name);
            'html':
                Saved := Rpt.SaveAsHtml(Name);
        end;
    end;

    local procedure One(Form: Text; Fmt: Text; Filtered: Boolean)
    var
        Tag: Text;
        Name: Text;
        Ok: Boolean;
        Saved: Boolean;
    begin
        Tag := Form + ' ' + Fmt;
        if Filtered then
            Tag += ' filtered';
        Name := Facts.FreshName(Form + '-' + Format(Filtered), Fmt);
        ClearLastError();
        if Form = 'static' then
            Ok := TryStatic(Fmt, Name, Filtered, Saved)
        else
            Ok := TryInstance(Fmt, Name, Filtered, Saved);
        Observer.Observe(Tag + ' ok', Format(Ok));
        Observer.Observe(Tag + ' saved', Format(Saved));
        Observer.ObserveError(Tag + ' error');
        Facts.Describe(Observer, Tag, Name);
    end;

    local procedure Both(Form: Text; Fmt: Text)
    begin
        Facts.Seed();
        RowLog.Take();
        One(Form, Fmt, false);
        One(Form, Fmt, true);
    end;

    // The rows the data item reads, per form and filter. Only the dataset is observed, not the output or the error.
    local procedure Rows(Form: Text; Fmt: Text; Filtered: Boolean)
    var
        Name: Text;
        Saved: Boolean;
        Tag: Text;
    begin
        Tag := Form + ' ' + Fmt;
        if Filtered then
            Tag += ' filtered';
        Name := Facts.FreshName('rows', Fmt);
        RowLog.Take();
        if Form = 'static' then begin
            if TryStatic(Fmt, Name, Filtered, Saved) then;
        end else
            if TryInstance(Fmt, Name, Filtered, Saved) then;
        ClearLastError();
        if Exists(Name) then
            Erase(Name);
        Observer.Observe(Tag + ' rows', RowLog.Take());
    end;

#if not BC29PLUS
    [Test]
    procedure Static_SaveAsPdf()
    begin
        Both('static', 'pdf');
        Observer.Expect('static pdf ok', 'Yes');
        Observer.Expect('static pdf saved', 'Yes');
        Observer.Expect('static pdf error|text', '');
        Observer.Expect('static pdf error|code', '');
        Observer.Expect('static pdf exists', 'Yes');
        Observer.Expect('static pdf kind', 'pdf');
        Observer.Expect('static pdf pdf pages', '1');
        Observer.Expect('static pdf filtered ok', 'Yes');
        Observer.Expect('static pdf filtered saved', 'Yes');
        Observer.Expect('static pdf filtered error|text', '');
        Observer.Expect('static pdf filtered error|code', '');
        Observer.Expect('static pdf filtered exists', 'Yes');
        Observer.Expect('static pdf filtered kind', 'pdf');
        Observer.Expect('static pdf filtered pdf pages', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Instance_SaveAsPdf()
    begin
        Both('instance', 'pdf');
        Observer.Expect('instance pdf ok', 'Yes');
        Observer.Expect('instance pdf saved', 'Yes');
        Observer.Expect('instance pdf error|text', '');
        Observer.Expect('instance pdf error|code', '');
        Observer.Expect('instance pdf exists', 'Yes');
        Observer.Expect('instance pdf kind', 'pdf');
        Observer.Expect('instance pdf pdf pages', '1');
        Observer.Expect('instance pdf filtered ok', 'Yes');
        Observer.Expect('instance pdf filtered saved', 'Yes');
        Observer.Expect('instance pdf filtered error|text', '');
        Observer.Expect('instance pdf filtered error|code', '');
        Observer.Expect('instance pdf filtered exists', 'Yes');
        Observer.Expect('instance pdf filtered kind', 'pdf');
        Observer.Expect('instance pdf filtered pdf pages', '1');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure Static_SaveAsHtml_IsRefused()
    begin
        Both('static', 'html');
        Observer.Expect('static html ok', 'Yes');
        Observer.Expect('static html saved', 'No');
        Observer.Expect('static html error|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('static html error|code', 'ReportUnsupportedFormat');
        Observer.Expect('static html exists', 'No');
        Observer.Expect('static html filtered ok', 'Yes');
        Observer.Expect('static html filtered saved', 'No');
        Observer.Expect('static html filtered error|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('static html filtered error|code', 'ReportUnsupportedFormat');
        Observer.Expect('static html filtered exists', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Instance_SaveAsHtml_IsRefused()
    begin
        Both('instance', 'html');
        Observer.Expect('instance html ok', 'Yes');
        Observer.Expect('instance html saved', 'No');
        Observer.Expect('instance html error|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('instance html error|code', 'ReportUnsupportedFormat');
        Observer.Expect('instance html exists', 'No');
        Observer.Expect('instance html filtered ok', 'Yes');
        Observer.Expect('instance html filtered saved', 'No');
        Observer.Expect('instance html filtered error|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('instance html filtered error|code', 'ReportUnsupportedFormat');
        Observer.Expect('instance html filtered exists', 'No');
        Observer.Verify();
    end;

    // Windows BC 27.5, 28.5 and 29.0 (Windows checks 2026-10-20; 29.0 gives the same values) write the docx/xlsx with the marker in the main
    // part and no error. Before the bc-linux fixes the Linux image failed inside the Mono renderer (ReportingService:Rpc, bc-linux #144; BC 29.0:
    // renderer off at boot, bc-linux #143).
    [Test]
    procedure Static_SaveAsWord()
    begin
        Both('static', 'docx');
        Observer.Expect('static docx ok', 'Yes');
        Observer.Expect('static docx saved', 'Yes');
        Observer.Expect('static docx error|text', '');
        Observer.Expect('static docx error|code', '');
        Observer.Expect('static docx exists', 'Yes');
        Observer.Expect('static docx kind', 'zip');
        Observer.Expect('static docx zip marker', 'word/document.xml=AMTXT[FIRST:row1|LAST:row4|ROWS:4]');
        Observer.Expect('static docx filtered ok', 'Yes');
        Observer.Expect('static docx filtered saved', 'Yes');
        Observer.Expect('static docx filtered error|text', '');
        Observer.Expect('static docx filtered error|code', '');
        Observer.Expect('static docx filtered exists', 'Yes');
        Observer.Expect('static docx filtered kind', 'zip');
        Observer.Expect('static docx filtered zip marker', 'word/document.xml=AMTXT[FIRST:row3|LAST:row4|ROWS:2]');
        Observer.Verify();
    end;

    [Test]
    procedure Static_SaveAsExcel()
    begin
        Both('static', 'xlsx');
        Observer.Expect('static xlsx ok', 'Yes');
        Observer.Expect('static xlsx saved', 'Yes');
        Observer.Expect('static xlsx error|text', '');
        Observer.Expect('static xlsx error|code', '');
        Observer.Expect('static xlsx exists', 'Yes');
        Observer.Expect('static xlsx kind', 'zip');
        Observer.Expect('static xlsx zip marker', 'xl/worksheets/sheet1.xml=AMTXT[FIRST:row1|LAST:row4|ROWS:4]');
        Observer.Expect('static xlsx filtered ok', 'Yes');
        Observer.Expect('static xlsx filtered saved', 'Yes');
        Observer.Expect('static xlsx filtered error|text', '');
        Observer.Expect('static xlsx filtered error|code', '');
        Observer.Expect('static xlsx filtered exists', 'Yes');
        Observer.Expect('static xlsx filtered kind', 'zip');
        Observer.Expect('static xlsx filtered zip marker', 'xl/worksheets/sheet1.xml=AMTXT[FIRST:row3|LAST:row4|ROWS:2]');
        Observer.Verify();
    end;

    [Test]
    procedure Instance_SaveAsWord()
    begin
        Both('instance', 'docx');
        Observer.Expect('instance docx ok', 'Yes');
        Observer.Expect('instance docx saved', 'Yes');
        Observer.Expect('instance docx error|text', '');
        Observer.Expect('instance docx error|code', '');
        Observer.Expect('instance docx exists', 'Yes');
        Observer.Expect('instance docx kind', 'zip');
        Observer.Expect('instance docx zip marker', 'word/document.xml=AMTXT[FIRST:row1|LAST:row4|ROWS:4]');
        Observer.Expect('instance docx filtered ok', 'Yes');
        Observer.Expect('instance docx filtered saved', 'Yes');
        Observer.Expect('instance docx filtered error|text', '');
        Observer.Expect('instance docx filtered error|code', '');
        Observer.Expect('instance docx filtered exists', 'Yes');
        Observer.Expect('instance docx filtered kind', 'zip');
        Observer.Expect('instance docx filtered zip marker', 'word/document.xml=AMTXT[FIRST:row3|LAST:row4|ROWS:2]');
        Observer.Verify();
    end;

    [Test]
    procedure Instance_SaveAsExcel()
    begin
        Both('instance', 'xlsx');
        Observer.Expect('instance xlsx ok', 'Yes');
        Observer.Expect('instance xlsx saved', 'Yes');
        Observer.Expect('instance xlsx error|text', '');
        Observer.Expect('instance xlsx error|code', '');
        Observer.Expect('instance xlsx exists', 'Yes');
        Observer.Expect('instance xlsx kind', 'zip');
        Observer.Expect('instance xlsx zip marker', 'xl/worksheets/sheet1.xml=AMTXT[FIRST:row1|LAST:row4|ROWS:4]');
        Observer.Expect('instance xlsx filtered ok', 'Yes');
        Observer.Expect('instance xlsx filtered saved', 'Yes');
        Observer.Expect('instance xlsx filtered error|text', '');
        Observer.Expect('instance xlsx filtered error|code', '');
        Observer.Expect('instance xlsx filtered exists', 'Yes');
        Observer.Expect('instance xlsx filtered kind', 'zip');
        Observer.Expect('instance xlsx filtered zip marker', 'xl/worksheets/sheet1.xml=AMTXT[FIRST:row3|LAST:row4|ROWS:2]');
        Observer.Verify();
    end;

    [Test]
    procedure RecordFilter_RowsTheDatasetReads()
    var
        Formats: List of [Text];
        Fmt: Text;
    begin
        Facts.Seed();
        Formats.AddRange('pdf', 'docx', 'xlsx', 'html');
        foreach Fmt in Formats do begin
            Rows('static', Fmt, false);
            Rows('static', Fmt, true);
            Rows('instance', Fmt, false);
            Rows('instance', Fmt, true);
        end;
        // Every form reads the dataset before rendering: all four rows, or rows 3 and 4 with the Record filter (Id >= 3).
        // Html is refused before the dataset is read (no rows). BC 29 measured locally; BC 27 and 28 in the corpus CI.
        Observer.Expect('static pdf rows', '1,2,3,4,');
        Observer.Expect('static pdf filtered rows', '3,4,');
        Observer.Expect('instance pdf rows', '1,2,3,4,');
        Observer.Expect('instance pdf filtered rows', '3,4,');
        Observer.Expect('static docx rows', '1,2,3,4,');
        Observer.Expect('static docx filtered rows', '3,4,');
        Observer.Expect('instance docx rows', '1,2,3,4,');
        Observer.Expect('instance docx filtered rows', '3,4,');
        Observer.Expect('static xlsx rows', '1,2,3,4,');
        Observer.Expect('static xlsx filtered rows', '3,4,');
        Observer.Expect('instance xlsx rows', '1,2,3,4,');
        Observer.Expect('instance xlsx filtered rows', '3,4,');
        Observer.Expect('static html rows', '');
        Observer.Expect('static html filtered rows', '');
        Observer.Expect('instance html rows', '');
        Observer.Expect('instance html filtered rows', '');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure SaveHandler(var RP: TestRequestPage "LT AM OP RP Rpt")
    begin
        RP.ThresholdField.SetValue(3);
        ClearLastError();
        case Kind of
            'xlsx':
                RP.SaveAsExcel(Target);
            'pdf':
                RP.SaveAsPdf(Target);
            'docx':
                RP.SaveAsWord(Target);
        end;
        Observer.ObserveError('handler');
        Observer.Observe('file in handler', Format(Exists(Target)));
        Observer.Observe('cancel ok', Format(TryCancel(RP)));
        Observer.ObserveError('cancel');
    end;

    [TryFunction]
    local procedure TryCancel(var RP: TestRequestPage "LT AM OP RP Rpt")
    begin
        RP.Cancel().Invoke();
    end;

    local procedure RunKind(NewKind: Text)
    begin
        Facts.Seed();
        Kind := NewKind;
        Target := Facts.FreshName('rp', NewKind);
        ClearLastError();
        Report.Run(Report::"LT AM OP RP Rpt");
        Observer.ObserveError('after run');
        Facts.Describe(Observer, NewKind, Target);
    end;

#if not BC29PLUS
    [Test]
    [HandlerFunctions('SaveHandler')]
    procedure RequestPage_SaveAsPdf()
    begin
        RunKind('pdf');
        Observer.Expect('handler|text', '');
        Observer.Expect('handler|code', '');
        Observer.Expect('file in handler', 'No');
        Observer.Expect('cancel ok', 'No');
        Observer.Expect('cancel|text', 'The TestPage is not open.');
        Observer.Expect('cancel|code', 'TestPageNotOpened');
        Observer.Expect('after run|text', '');
        Observer.Expect('after run|code', '');
        Observer.Expect('pdf exists', 'Yes');
        Observer.Expect('pdf kind', 'pdf');
        Observer.Expect('pdf pdf pages', '1');
        Observer.Verify();
    end;
#endif

    // Windows BC 27.5, 28.5 and 29.0 (Windows checks 2026-10-20; 29.0 gives the same values) write the docx/xlsx with the marker in the main
    // part and no error. Before the bc-linux fixes the Linux image failed inside the Mono renderer (ReportingService:Rpc, bc-linux #144; BC 29.0:
    // renderer off at boot, bc-linux #143).
    [Test]
    [HandlerFunctions('SaveHandler')]
    procedure RequestPage_SaveAsExcel()
    begin
        RunKind('xlsx');
        Observer.Expect('handler|text', '');
        Observer.Expect('handler|code', '');
        Observer.Expect('file in handler', 'No');
        Observer.Expect('cancel ok', 'No');
        Observer.Expect('cancel|text', 'The TestPage is not open.');
        Observer.Expect('cancel|code', 'TestPageNotOpened');
        Observer.Expect('after run|text', '');
        Observer.Expect('after run|code', '');
        Observer.Expect('xlsx exists', 'Yes');
        Observer.Expect('xlsx kind', 'zip');
        Observer.Expect('xlsx zip marker', 'xl/worksheets/sheet1.xml=AMTXT[FIRST:row3|LAST:row4|ROWS:2]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SaveHandler')]
    procedure RequestPage_SaveAsWord()
    begin
        RunKind('docx');
        Observer.Expect('handler|text', '');
        Observer.Expect('handler|code', '');
        Observer.Expect('file in handler', 'No');
        Observer.Expect('cancel ok', 'No');
        Observer.Expect('cancel|text', 'The TestPage is not open.');
        Observer.Expect('cancel|code', 'TestPageNotOpened');
        Observer.Expect('after run|text', '');
        Observer.Expect('after run|code', '');
        Observer.Expect('docx exists', 'Yes');
        Observer.Expect('docx kind', 'zip');
        Observer.Expect('docx zip marker', 'word/document.xml=AMTXT[FIRST:row3|LAST:row4|ROWS:2]');
        Observer.Verify();
    end;
}
