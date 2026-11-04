// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained report 79256 (hand-written layout LtAmRdlcText.rdlc), test codeunit 79257,
// subscriber codeunit 79258, log codeunit 79259; writer QD: manual subscriber codeunit 86520 (the RequestPageXml text)
// What Report.SaveAs and Report.Run do with an RDLC layout (corpus #601 item 1; the corpus CI runs the Mono RDLC renderer, rdlc_renderer: true):
// whether it saves, the file signature, the PDF page count, and the order of SubstituteReport, OnPreRendering and OnDocumentReady.
// Pinned on every leg: Html is refused before rendering ('The Html output format is not supported by the current report layout format.',
// ReportUnsupportedFormat, no OnPreRendering); Xml writes the dataset without the layout (OnDocumentReady with an empty layout name).
// Pinned on BC 27 and 28 only (#if not BC29PLUS): Pdf renders one page, and Report.Run without a request page renders a Pdf document
// (OnDocumentReady documenttype application/pdf). The BC 29 Linux container turns the renderer off at boot ("the side-service compatibility
// patch failed"), so on BC 29 these calls answer with the Linux stub text, which is not Business Central behavior.
// PDF bytes are never compared (not stable) and PDF text is compressed, so only the page count is asserted.
// SaveAs Word and Excel of an RDLC layout: asserted with the Windows BC 27.5/28.5 values (Windows check 2026-10-20: zip with the marker, no
// error) and were held on Linux until the bc-linux #144 fix: the Linux image returned false with 'The system encountered an internal error
// while rendering the report.' (ReportingService:Rpc) after OnPreRendering. Windows BC 29.0 (check 2026-10-20) gives the same values; held on
// 29 until the bc-linux #143 fix (the BC 29 Linux container turned the renderer off at boot).
// BC versions: 27 - 29

codeunit 79259 "LT AM Rdlc Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        Active: Boolean;

    procedure Start()
    begin
        Entries := '';
        Active := true;
    end;

    procedure Add(Entry: Text)
    begin
        if Active then
            Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        Active := false;
        exit(Result);
    end;
}

report 79256 "LT AM Rdlc Text Rpt"
{
    DefaultRenderingLayout = LtAmRdlcText;

    dataset
    {
        dataitem(AmRow; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 3));
            column(AmNum; Number)
            {
            }
            column(AmReq; ReqText)
            {
            }
            column(AmMark; 'AMMARK')
            {
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ReqText; ReqText)
                {
                    ApplicationArea = All;
                    Caption = 'Request text';
                }
            }
        }
    }

    rendering
    {
        layout(LtAmRdlcText)
        {
            Type = RDLC;
            LayoutFile = './reports/layouts-saveas/LtAmRdlcText.rdlc';
        }
    }

    trigger OnPreRendering(var RenderingPayload: JsonObject)
    var
        Keys: Text;
        KeyName: Text;
    begin
        foreach KeyName in RenderingPayload.Keys() do
            Keys += KeyName + ',';
        AmLog.Add('OnPreRendering(' + Keys + ')');
    end;

    var
        AmLog: Codeunit "LT AM Rdlc Log";
        ReqText: Text[30];
}

codeunit 79258 "LT AM Rdlc Subscribers"
{
    var
        AmLog: Codeunit "LT AM Rdlc Log";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SubstituteReport', '', false, false)]
    local procedure AmSubstitute(ReportId: Integer; RunMode: Option Normal,ParametersOnly,Execute,Print,SaveAs,RunModal; RequestPageXml: Text; RecordRef: RecordRef; var NewReportId: Integer)
    begin
        if ReportId <> 79256 then
            exit;
        AmLog.Add('SubstituteReport(' + Format(ReportId) + ',' + Format(RunMode) + ',req=' + Format(StrPos(RequestPageXml, 'AMREQ42') > 0) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'OnDocumentReady', '', false, false)]
    local procedure AmDocumentReady(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var TargetStream: OutStream; var Success: Boolean)
    begin
        if ObjectId <> 79256 then
            exit;
        // The document stream is not read here: reading it could change what the caller receives.
        AmLog.Add('OnDocumentReady(' + Format(ObjectId) + ',keys=' + Format(ObjectPayload.Keys().Count()) + ',documenttype=' + Value(ObjectPayload, 'documenttype') +
            ',layoutmimetype=' + Value(ObjectPayload, 'layoutmimetype') + ',layoutname=' + Value(ObjectPayload, 'layoutname') + ',objectname=' + Value(ObjectPayload, 'objectname') +
            ',success=' + Format(Success) + ')');
    end;

    local procedure Value(Payload: JsonObject; KeyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not Payload.Get(KeyName, Token) then
            exit('<absent>');
        if not Token.IsValue() then
            exit('<not a value>');
        exit(Token.AsValue().AsText());
    end;
}

codeunit 79257 "LT AM Rdlc Output Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        AmLog: Codeunit "LT AM Rdlc Log";
        RequestXmlTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters><Options><Field name="ReqText">AMREQ42</Field></Options></ReportParameters>', Locked = true;

    [TryFunction]
    local procedure TrySaveAs(ReportId: Integer; Fmt: ReportFormat; var TempBlob: Codeunit "Temp Blob"; var Saved: Boolean)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Saved := Report.SaveAs(ReportId, RequestXmlTxt, Fmt, OutS);
    end;

    [TryFunction]
    local procedure TryRun(ReportId: Integer)
    begin
        Report.Run(ReportId, false, false);
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

    // The text the layout computes, from 'AMTXT[' to the next ']', or '' when the output does not contain it.
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

    local procedure ZipFacts(var TempBlob: Codeunit "Temp Blob"; var Entries: Text; var WithMarker: Text; var MarkerText: Text; var Unreadable: Text)
    var
        DataCompression: Codeunit "Data Compression";
        EntryBlob: Codeunit "Temp Blob";
        Names: List of [Text];
        Name: Text;
        InS: InStream;
        EntryOut: OutStream;
        Length: Integer;
        Content: Text;
    begin
        TempBlob.CreateInStream(InS);
        DataCompression.OpenZipArchive(InS, false);
        DataCompression.GetEntryList(Names);
        foreach Name in Names do begin
            Entries += Name + ',';
            // Only the XML parts are read as text; a binary part (an image, a thumbnail) cannot be read as UTF-8 text.
            if Name.EndsWith('.xml') or Name.EndsWith('.rels') then begin
                Clear(EntryBlob);
                EntryBlob.CreateOutStream(EntryOut);
                DataCompression.ExtractEntry(Name, EntryOut, Length);
                if not TryAllText(EntryBlob, TextEncoding::UTF8, Content) then
                    if not TryAllText(EntryBlob, TextEncoding::UTF16, Content) then begin
                        Content := '';
                        Unreadable += Name + ',';
                    end;
                if Marker(Content) <> '' then begin
                    WithMarker += Name + ',';
                    MarkerText := Marker(Content);
                end;
            end;
        end;
        DataCompression.CloseZipArchive();
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; ReportId: Integer; Fmt: ReportFormat)
    var
        TempBlob: Codeunit "Temp Blob";
        Saved: Boolean;
        Ok: Boolean;
        Kind: Text;
        Entries: Text;
        WithMarker: Text;
        MarkerText: Text;
        Unreadable: Text;
    begin
        AmLog.Start();
        ClearLastError();
        Ok := TrySaveAs(ReportId, Fmt, TempBlob, Saved);
        Observer.Observe('log', AmLog.Take());
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('saved', Format(Saved));
        Observer.Observe('has_output', Format(TempBlob.Length() > 0));
        Kind := Head(TempBlob);
        Observer.Observe('kind', Kind);
        case Kind of
            'pdf':
                Observer.Observe('pdf_pages', Format(PdfPages(TempBlob)));
            'zip':
                begin
                    ZipFacts(TempBlob, Entries, WithMarker, MarkerText, Unreadable);
                    Observer.Observe('main_part', Format(Entries.Contains('word/document.xml,')) + '/' + Format(Entries.Contains('xl/workbook.xml,')));
                    Observer.Observe('entries_with_marker', WithMarker);
                    Observer.Observe('marker', MarkerText);
                    Observer.Observe('unreadable_parts', Unreadable);
                end;
            'markup':
                Observer.Observe('marker', Marker(AllText(TempBlob, TextEncoding::UTF8)));
        end;
    end;

#if not BC29PLUS
    [Test]
    procedure TextRdlc_SaveAsPdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Rdlc Text Rpt", ReportFormat::Pdf);
        Observer.Expect('log', 'SubstituteReport(79256,SaveAs,req=Yes);OnPreRendering();OnDocumentReady(79256,keys=19,documenttype=application/pdf,layoutmimetype=Application/ReportLayout/Rdlc,layoutname=LtAmRdlcText,objectname=LT AM Rdlc Text Rpt,success=No);');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('has_output', 'Yes');
        Observer.Expect('kind', 'pdf');
        Observer.Expect('pdf_pages', '1');
        Observer.Verify();
    end;
#endif

    // Windows BC 27.5, 28.5 and 29.0 (Windows checks 2026-10-20; 29.0 gives the same values). Before the bc-linux fixes the Linux image failed in
    // the Mono renderer (ReportingService:Rpc, bc-linux #144; BC 29.0: renderer off at boot, bc-linux #143).
    [Test]
    procedure TextRdlc_SaveAsWord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Rdlc Text Rpt", ReportFormat::Word);
        Observer.Expect('log', 'SubstituteReport(79256,SaveAs,req=Yes);OnPreRendering();OnDocumentReady(79256,keys=19,documenttype=application/vnd.openxmlformats-officedocument.wordprocessingml.document,layoutmimetype=Application/ReportLayout/Rdlc,layoutname=LtAmRdlcText,objectname=LT AM Rdlc Text Rpt,success=No);');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('has_output', 'Yes');
        Observer.Expect('kind', 'zip');
        Observer.Expect('main_part', 'Yes/No');
        Observer.Expect('entries_with_marker', 'word/document.xml,');
        Observer.Expect('marker', 'AMTXT[REQ:AMREQ42|MARK:AMMARK|ROWS:3|SUM:6|LAST:3]');
        Observer.Expect('unreadable_parts', '');
        Observer.Verify();
    end;

    // Windows BC 27.5, 28.5 and 29.0 (Windows checks 2026-10-20; 29.0 gives the same values). Before the bc-linux fixes the Linux image failed in
    // the Mono renderer (ReportingService:Rpc, bc-linux #144; BC 29.0: renderer off at boot, bc-linux #143).
    [Test]
    procedure TextRdlc_SaveAsExcel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Rdlc Text Rpt", ReportFormat::Excel);
        Observer.Expect('log', 'SubstituteReport(79256,SaveAs,req=Yes);OnPreRendering();OnDocumentReady(79256,keys=19,documenttype=application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,layoutmimetype=Application/ReportLayout/Rdlc,layoutname=LtAmRdlcText,objectname=LT AM Rdlc Text Rpt,success=No);');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('has_output', 'Yes');
        Observer.Expect('kind', 'zip');
        Observer.Expect('main_part', 'No/Yes');
        Observer.Expect('entries_with_marker', 'xl/worksheets/sheet1.xml,');
        Observer.Expect('marker', 'AMTXT[REQ:AMREQ42|MARK:AMMARK|ROWS:3|SUM:6|LAST:3]');
        Observer.Expect('unreadable_parts', '');
        Observer.Verify();
    end;

    [Test]
    procedure TextRdlc_SaveAsHtml_IsRefused()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Rdlc Text Rpt", ReportFormat::Html);
        Observer.Expect('log', 'SubstituteReport(79256,SaveAs,req=Yes);');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('error|code', 'ReportUnsupportedFormat');
        Observer.Expect('saved', 'No');
        Observer.Expect('has_output', 'No');
        Observer.Expect('kind', 'empty');
        Observer.Verify();
    end;

    [Test]
    procedure TextRdlc_SaveAsXml_DoesNotRender()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, Report::"LT AM Rdlc Text Rpt", ReportFormat::Xml);
        Observer.Expect('log', 'SubstituteReport(79256,SaveAs,req=Yes);OnPreRendering();OnDocumentReady(79256,keys=19,documenttype=text/xml,layoutmimetype=,layoutname=,objectname=LT AM Rdlc Text Rpt,success=No);');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('has_output', 'Yes');
        Observer.Expect('kind', 'other');
        Observer.Verify();
    end;

#if not BC29PLUS
    [Test]
    procedure TextRdlc_Run_NoRequestPage_RendersPdf()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        AmLog.Start();
        ClearLastError();
        Ok := TryRun(Report::"LT AM Rdlc Text Rpt");
        Observer.Observe('log', AmLog.Take());
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Expect('log', 'SubstituteReport(79256,Normal,req=No);OnPreRendering();OnDocumentReady(79256,keys=19,documenttype=application/pdf,layoutmimetype=Application/ReportLayout/Rdlc,layoutname=LtAmRdlcText,objectname=LT AM Rdlc Text Rpt,success=No);');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Verify();
    end;
#endif

    // Writer QD (al-runtime-rs: the RequestPageXml text SubstituteReport receives): the whole text for an Html SaveAs of the RDLC report
    // (refused before rendering), with the parameters of RequestXmlTxt and with empty parameters, and for an Xml SaveAs as a contrast.
    local procedure QdRequestPageXml(Fmt: ReportFormat; Parameters: Text; Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        Sub: Codeunit "LT QD Rdlc Req Subscriber";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Ok: Boolean;
    begin
        BindSubscription(Sub);
        AmLog.Start();
        ClearLastError();
        TempBlob.CreateOutStream(OutS);
        Ok := TryQdSaveAs(Parameters, Fmt, OutS);
        AmLog.Take();
        UnbindSubscription(Sub);
        Observer.Observe(Prefix + '_ok', Format(Ok));
        Observer.Observe(Prefix + '_calls', Format(Sub.Calls()));
        Observer.Observe(Prefix + '_runmode', Sub.RunMode());
        Observer.Observe(Prefix + '_length', Format(StrLen(Sub.RequestPageXml())));
        Observer.Observe(Prefix + '_xml', Sub.RequestPageXml());
    end;

    [TryFunction]
    local procedure TryQdSaveAs(Parameters: Text; Fmt: ReportFormat; var OutS: OutStream)
    begin
        Report.SaveAs(Report::"LT AM Rdlc Text Rpt", Parameters, Fmt, OutS);
    end;

    [Test]
    procedure QD_TextRdlc_SaveAsHtml_RequestPageXml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        QdRequestPageXml(ReportFormat::Html, RequestXmlTxt, 'html', Observer);
        Observer.Expect('html_ok', 'No');
        Observer.Expect('html_calls', '1');
        Observer.Expect('html_runmode', 'SaveAs');
        Observer.Expect('html_length', '131');
        Observer.Expect('html_xml', '<?xml version="1.0" standalone="yes"?><ReportParameters><Options><Field name="ReqText">AMREQ42</Field></Options></ReportParameters>');
        Observer.Verify();
    end;

    [Test]
    procedure QD_TextRdlc_SaveAsHtml_EmptyParameters_RequestPageXml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        QdRequestPageXml(ReportFormat::Html, '', 'html_empty', Observer);
        Observer.Expect('html_empty_ok', 'No');
        Observer.Expect('html_empty_calls', '1');
        Observer.Expect('html_empty_runmode', 'SaveAs');
        Observer.Expect('html_empty_length', '0');
        Observer.Expect('html_empty_xml', '');
        Observer.Verify();
    end;

    [Test]
    procedure QD_TextRdlc_SaveAsXml_RequestPageXml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        QdRequestPageXml(ReportFormat::Xml, RequestXmlTxt, 'xml', Observer);
        Observer.Expect('xml_ok', 'Yes');
        Observer.Expect('xml_calls', '1');
        Observer.Expect('xml_runmode', 'SaveAs');
        Observer.Expect('xml_length', '131');
        Observer.Expect('xml_xml', '<?xml version="1.0" standalone="yes"?><ReportParameters><Options><Field name="ReqText">AMREQ42</Field></Options></ReportParameters>');
        Observer.Verify();
    end;
}

codeunit 86520 "LT QD Rdlc Req Subscriber"
{
    EventSubscriberInstance = Manual;

    var
        LastXml: Text;
        LastRunMode: Text;
        CallCount: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SubstituteReport', '', false, false)]
    local procedure QdSubstitute(ReportId: Integer; RunMode: Option Normal,ParametersOnly,Execute,Print,SaveAs,RunModal; RequestPageXml: Text; RecordRef: RecordRef; var NewReportId: Integer)
    begin
        if ReportId <> 79256 then
            exit;
        CallCount += 1;
        LastXml := RequestPageXml;
        LastRunMode := Format(RunMode);
    end;

    procedure RequestPageXml(): Text
    begin
        exit(LastXml);
    end;

    procedure RunMode(): Text
    begin
        exit(LastRunMode);
    end;

    procedure Calls(): Integer
    begin
        exit(CallCount);
    end;
}
