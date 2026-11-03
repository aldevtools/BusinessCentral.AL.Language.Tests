//sub:report
// CurrReport.ObjectId (md:666), CurrReport.Preview (md:671), CurrReport.Language and FormatRegion (md:471).
// Writer QV: report 87470 "LT QV Preview Rpt" (AL Runner issue 5666), CurrReport.Preview per start mode, layout ./QvPreviewLayout.rdl (generated).
// The report ids in observed texts are replaced by <id>.

codeunit 67756 "W3 ObjId Log"
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

report 67757 "W3 ObjId Cap"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    Caption = 'W3 ObjId Caption';

    dataset
    {
        dataitem(Row; "W3 Row")
        {
        }
    }

    var
        L: Codeunit "W3 ObjId Log";

    trigger OnPreReport()
    begin
        L.Add('pre: names=' + CurrReport.ObjectId(true) + ' ids=' + CurrReport.ObjectId(false) + ' preview=' + Format(CurrReport.Preview()));
    end;
}

report 67758 "W3 ObjId NoCap"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
        }
    }

    var
        L: Codeunit "W3 ObjId Log";

    trigger OnPreReport()
    begin
        L.Add('pre: names=' + CurrReport.ObjectId(true) + ' ids=' + CurrReport.ObjectId(false) + ' preview=' + Format(CurrReport.Preview()));
    end;
}

// Not ProcessingOnly, with a request page, so SaveAs and the request page actions can reach OnPreReport.
report 67759 "W3 ObjId Save"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            column(Id; Id) { }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Ctl; CtlVal)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        CtlVal: Integer;
        L: Codeunit "W3 ObjId Log";

    trigger OnPreReport()
    begin
        L.Add('pre: names=' + CurrReport.ObjectId(true) + ' ids=' + CurrReport.ObjectId(false) + ' preview=' + Format(CurrReport.Preview()));
    end;
}

// Language and FormatRegion set in OnPreReport; the columns hold values that depend on the culture.
report 67760 "W3 Lang Rpt"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            column(Id; Id) { }
            column(DecC; DecVar) { }
            column(DateC; DateVar) { }
            column(DtC; DtVar) { }
            column(BoolC; BoolVar) { }

            trigger OnAfterGetRecord()
            begin
                DecVar := 1234.5;
                DateVar := DMY2Date(25, 12, 2024);
                DtVar := CreateDateTime(DateVar, 143005T);
                BoolVar := true;
            end;
        }
    }

    var
        DecVar: Decimal;
        DateVar: Date;
        DtVar: DateTime;
        BoolVar: Boolean;
        ModeValue: Text;
        L: Codeunit "W3 ObjId Log";

    procedure SetMode(NewMode: Text)
    begin
        ModeValue := NewMode;
    end;

    [TryFunction]
    local procedure TrySetLanguage(Value: Integer)
    begin
        CurrReport.Language := Value;
    end;

    [TryFunction]
    local procedure TrySetFormatRegion(Value: Text)
    begin
        CurrReport.FormatRegion := Value;
    end;

    local procedure Formats(): Text
    begin
        exit(Format(DMY2Date(25, 12, 2024)) + '|' + Format(1234.5) + '|' + Format(true));
    end;

    trigger OnPreReport()
    var
        Before: Text;
    begin
        L.Add('language before set equals GlobalLanguage=' + Format(CurrReport.Language = GlobalLanguage()) + ' region=[' + CurrReport.FormatRegion + ']');
        case ModeValue of
            'lang':
                begin
                    Before := Formats();
                    CurrReport.Language := 1031;
                    L.Add('language after set=' + Format(CurrReport.Language) + ' Format changed=' + Format(Before <> Formats()));
                end;
            'region':
                begin
                    Before := Formats();
                    CurrReport.FormatRegion := 'de-DE';
                    L.Add('region after set=[' + CurrReport.FormatRegion + '] Format changed=' + Format(Before <> Formats()));
                end;
            'both':
                begin
                    CurrReport.Language := 1031;
                    CurrReport.FormatRegion := 'de-DE';
                    L.Add('both set language=' + Format(CurrReport.Language) + ' region=[' + CurrReport.FormatRegion + ']');
                end;
            'rejects':
                begin
                    if TrySetLanguage(0) then
                        L.Add('Language 0 accepted')
                    else
                        L.Add('Language 0 error=' + GetLastErrorText() + ' code=' + GetLastErrorCode());
                    if TrySetLanguage(-1) then
                        L.Add('Language -1 accepted, reads ' + Format(CurrReport.Language))
                    else
                        L.Add('Language -1 error=' + GetLastErrorText() + ' code=' + GetLastErrorCode());
                    if TrySetLanguage(65536) then
                        L.Add('Language 65536 accepted, reads ' + Format(CurrReport.Language))
                    else
                        L.Add('Language 65536 error=' + GetLastErrorText() + ' code=' + GetLastErrorCode());
                    if TrySetLanguage(1) then
                        L.Add('Language 1 accepted, reads ' + Format(CurrReport.Language))
                    else
                        L.Add('Language 1 error=' + GetLastErrorText() + ' code=' + GetLastErrorCode());
                    L.Add('language after the rejects=' + Format(CurrReport.Language));
                end;
            'regions':
                begin
                    if TrySetFormatRegion('xx-YY') then
                        L.Add('region xx-YY accepted, reads [' + CurrReport.FormatRegion + ']')
                    else
                        L.Add('region xx-YY error=' + GetLastErrorText() + ' code=' + GetLastErrorCode());
                    if TrySetFormatRegion('de') then
                        L.Add('region de accepted, reads [' + CurrReport.FormatRegion + ']')
                    else
                        L.Add('region de error=' + GetLastErrorText() + ' code=' + GetLastErrorCode());
                    if TrySetFormatRegion('') then
                        L.Add('region empty accepted, reads [' + CurrReport.FormatRegion + ']')
                    else
                        L.Add('region empty error=' + GetLastErrorText() + ' code=' + GetLastErrorCode());
                    if TrySetFormatRegion('fr-FR') then
                        L.Add('region fr-FR accepted, reads [' + CurrReport.FormatRegion + ']')
                    else
                        L.Add('region fr-FR error=' + GetLastErrorText() + ' code=' + GetLastErrorCode());
                end;
        end;
    end;
}

// Writer RB (AL Runner issues 5681 and 5666): the dataset values when the language or region is set before SaveAs (GlobalLanguage, the
// Language and FormatRegion of the report variable), for Decimal, Integer, Date, Time, DateTime and Boolean columns and for Format() texts.
report 87800 "LT RB Fmt Rpt"
{
    ProcessingOnly = false;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            column(Id; Id) { }
            column(DecC; DecVar) { }
            column(NegDecC; NegDecVar) { }
            column(IntC; IntVar) { }
            column(DateC; DateVar) { }
            column(TimeC; TimeVar) { }
            column(DtC; DtVar) { }
            column(BoolC; BoolVar) { }
            column(FmtC; FmtVar) { }

            trigger OnAfterGetRecord()
            begin
                DecVar := 1234.5;
                NegDecVar := -1234567.891;
                IntVar := 1234567;
                DateVar := DMY2Date(5, 3, 2024);
                TimeVar := 093005T;
                DtVar := CreateDateTime(DateVar, TimeVar);
                BoolVar := true;
                FmtVar := Format(DecVar) + '|' + Format(NegDecVar) + '|' + Format(IntVar) + '|' + Format(DateVar) + '|' + Format(TimeVar) + '|' + Format(BoolVar);
            end;
        }
    }

    var
        DecVar: Decimal;
        NegDecVar: Decimal;
        IntVar: Integer;
        DateVar: Date;
        TimeVar: Time;
        DtVar: DateTime;
        BoolVar: Boolean;
        FmtVar: Text;
        L: Codeunit "W3 ObjId Log";

    trigger OnPreReport()
    begin
        L.Add('pre language=' + Format(CurrReport.Language) + ' region=[' + CurrReport.FormatRegion + '] global=' + Format(GlobalLanguage()));
    end;
}

// Writer QV (AL Runner issue 5666): CurrReport.Preview read in a dataset column (directly and through a report procedure), in the report
// triggers and in the request page triggers, for each way the tests of codeunit 67761 start the report. RDLC layout, so SaveAs Pdf and
// the Preview and Print actions of the request page have a layout.
report 87470 "LT QV Preview Rpt"
{
    UsageCategory = None;
    DefaultRenderingLayout = QvRdlc;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            column(Id; Id) { }
            column(PreviewValue; CurrReport.Preview()) { }
            column(PreviewLogged; ColumnPreview()) { }

            trigger OnAfterGetRecord()
            begin
                LogPreview('get');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Ctl; CtlVal)
                {
                    ApplicationArea = All;
                }
            }
        }

        trigger OnOpenPage()
        begin
            LogPreview('rp open');
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            LogPreview('rp close ' + Format(CloseAction));
            exit(true);
        end;
    }

    rendering
    {
        layout(QvRdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/QvPreviewLayout.rdl';
            Caption = 'LT QV preview layout';
        }
    }

    var
        CtlVal: Integer;
        L: Codeunit "W3 ObjId Log";

    local procedure LogPreview(Where: Text)
    begin
        L.Add(Where + ' preview=' + Format(CurrReport.Preview()));
    end;

    local procedure ColumnPreview(): Boolean
    begin
        LogPreview('column');
        exit(CurrReport.Preview());
    end;

    trigger OnInitReport()
    begin
        LogPreview('init');
    end;

    trigger OnPreReport()
    begin
        LogPreview('pre');
    end;

    trigger OnPostReport()
    begin
        LogPreview('post');
    end;
}

codeunit 67761 "W3 ObjId Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "W3 ObjId Log";
        Dataset: Codeunit "W3 Dataset";
        Runner: Codeunit "W3 Runner";
        QvRpAction: Text;

    local procedure Seed()
    var
        Row: Record "W3 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Commit();
        L.Take();
    end;

    local procedure Mask(Value: Text): Text
    begin
        Value := Value.Replace(Format(Report::"W3 ObjId Cap"), '<cap>');
        Value := Value.Replace(Format(Report::"W3 ObjId NoCap"), '<nocap>');
        Value := Value.Replace(Format(Report::"W3 ObjId Save"), '<save>');
        exit(Value);
    end;

    [TryFunction]
    local procedure TrySetGlobalLanguage(Value: Integer)
    begin
        GlobalLanguage(Value);
    end;

    [TryFunction]
    local procedure TryInvokePreview(var RP: TestRequestPage "W3 ObjId Save")
    begin
        RP.Preview().Invoke();
    end;

    [TryFunction]
    local procedure TryCancel(var RP: TestRequestPage "W3 ObjId Save")
    begin
        RP.Cancel().Invoke();
    end;

    // md:666: the text of ObjectId on a report variable that has not run.
    [Test]
    procedure ObjectId_ReportVariable_WithAndWithoutCaption()
    var
        Observer: Codeunit "Probe Observer";
        Cap: Report "W3 ObjId Cap";
        NoCap: Report "W3 ObjId NoCap";
    begin
        Observer.Observe('Cap names', Mask(Cap.ObjectId(true)));
        Observer.Observe('Cap ids', Mask(Cap.ObjectId(false)));
        Observer.Observe('NoCap names', Mask(NoCap.ObjectId(true)));
        Observer.Observe('NoCap ids', Mask(NoCap.ObjectId(false)));
        Observer.Expect('Cap names', 'Report W3 ObjId Caption');
        Observer.Expect('Cap ids', 'Report <cap>');
        Observer.Expect('NoCap names', 'Report W3 ObjId NoCap');
        Observer.Expect('NoCap ids', 'Report <nocap>');
        Observer.Verify();
    end;

    // md:666: CurrReport.ObjectId inside a trigger, the same two reports.
    [Test]
    procedure ObjectId_CurrReport_InOnPreReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"W3 ObjId Cap");
        Report.Run(Report::"W3 ObjId NoCap");
        Observer.Observe('log', Mask(L.Take()));
        Observer.Expect('log', 'pre: names=Report W3 ObjId Caption ids=Report <cap> preview=No;pre: names=Report W3 ObjId NoCap ids=Report <nocap> preview=No;');
        Observer.Verify();
    end;

    // md:666: does the text with names depend on the session language?
    [Test]
    procedure ObjectId_WithAnotherGlobalLanguage()
    var
        Observer: Codeunit "Probe Observer";
        Cap: Report "W3 ObjId Cap";
        NoCap: Report "W3 ObjId NoCap";
        OldLanguage: Integer;
        Ok: Boolean;
    begin
        OldLanguage := GlobalLanguage();
        Ok := TrySetGlobalLanguage(1031);
        Observer.Observe('set 1031 ok', Format(Ok));
        Observer.ObserveError('set 1031');
        if Ok then begin
            Observer.Observe('Cap names', Mask(Cap.ObjectId(true)));
            Observer.Observe('NoCap names', Mask(NoCap.ObjectId(true)));
            Observer.Observe('Cap ids', Mask(Cap.ObjectId(false)));
        end;
        TrySetGlobalLanguage(OldLanguage);
        Observer.Observe('language restored', Format(GlobalLanguage() = OldLanguage));
        Observer.Expect('set 1031 ok', 'Ja');
        Observer.Expect('set 1031|text', '');
        Observer.Expect('set 1031|code', '');
        Observer.Expect('Cap names', 'Report W3 ObjId Caption');
        Observer.Expect('NoCap names', 'Report W3 ObjId NoCap');
        Observer.Expect('Cap ids', 'Report <cap>');
        Observer.Expect('language restored', 'Yes');
        Observer.Verify();
    end;

    // md:671: CurrReport.Preview in OnPreReport for each way to run.
    [Test]
    procedure Preview_ReportRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"W3 ObjId Cap");
        Observer.Observe('log', Mask(L.Take()));
        Observer.Expect('log', 'pre: names=Report W3 ObjId Caption ids=Report <cap> preview=No;');
        Observer.Verify();
    end;

    [Test]
    procedure Preview_ReportRunModal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.RunModal(Report::"W3 ObjId Cap");
        Observer.Observe('log', Mask(L.Take()));
        Observer.Expect('log', 'pre: names=Report W3 ObjId Caption ids=Report <cap> preview=No;');
        Observer.Verify();
    end;

    [Test]
    procedure Preview_ReportExecute()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Execute(Report::"W3 ObjId Cap", '');
        Observer.Observe('log', Mask(L.Take()));
        Observer.Expect('log', 'pre: names=Report W3 ObjId Caption ids=Report <cap> preview=Yes;');
        Observer.Verify();
    end;

    [Test]
    procedure Preview_ReportSaveAs()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
    begin
        Seed();
        Observer.Observe('saved', Format(Dataset.Save(Report::"W3 ObjId Save", '', Xml)));
        Observer.Observe('log', Mask(L.Take()));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('log', 'pre: names=Report W3 ObjId Save ids=Report <save> preview=No;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PreviewActionHandler')]
    procedure Preview_RequestPagePreviewAction()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Runner.Exec(Report::"W3 ObjId Save", 0, '', Result);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('log', Mask(L.Take()));
        Observer.Expect('ok', 'No');
        Observer.Expect('error|text', 'Report 67759 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('error|code', 'ReportNoLayout');
        Observer.Expect('log', 'Preview action invoked;Cancel after Preview error=The TestPage is not open.;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure PreviewActionHandler(var RP: TestRequestPage "W3 ObjId Save")
    begin
        if TryInvokePreview(RP) then
            L.Add('Preview action invoked')
        else
            L.Add('Preview action error=' + GetLastErrorText());
        if not TryCancel(RP) then
            L.Add('Cancel after Preview error=' + GetLastErrorText());
    end;

    local procedure LangRun(Mode: Text; var Observer: Codeunit "Probe Observer")
    var
        Rpt: Report "W3 Lang Rpt";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Xml: Text;
    begin
        Seed();
        Rpt.SetMode(Mode);
        TempBlob.CreateOutStream(OutS);
        Rpt.SaveAs('', ReportFormat::Xml, OutS);
        Xml := Dataset.ReadAll(TempBlob);
        Observer.Observe('log', L.Take());
        Observer.Observe('columns', Dataset.ColumnLines(Xml));
        Observer.Observe('item language', Dataset.ItemAttribute(Xml, 1, 'language'));
        Observer.Observe('item formatRegion', Dataset.ItemAttribute(Xml, 1, 'formatRegion'));
    end;

    // md:471: Language before any set, after Language := 1031, and the columns afterwards.
    [Test]
    procedure Language_NoSet_ReadsTheSessionLanguage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LangRun('', Observer);
        Observer.Expect('log', 'language before set equals GlobalLanguage=Yes region=[];');
        Observer.Expect('columns', '<Column name="Id">1</Column>|<Column name="DecC" decimalformatter="#,##0.00">1234.5</Column>|<Column name="DateC">12/25/2024</Column>|<Column name="DtC">12/25/2024 2:30:05 PM</Column>|<Column name="BoolC">True</Column>|');
        Observer.Expect('item language', 'en-US');
        Observer.Expect('item formatRegion', 'en-US');
        Observer.Verify();
    end;

    [Test]
    procedure Language_Set1031_FormatAndColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LangRun('lang', Observer);
        Observer.Expect('log', 'language before set equals GlobalLanguage=Yes region=[];language after set=1031 Format changed=Ja;');
        Observer.Expect('columns', '<Column name="Id">1</Column>|<Column name="DecC" decimalformatter="#,##0.00">1234.5</Column>|<Column name="DateC">12/25/2024</Column>|<Column name="DtC">12/25/2024 2:30:05 PM</Column>|<Column name="BoolC">True</Column>|');
        Observer.Expect('item language', 'de-DE');
        Observer.Expect('item formatRegion', 'en-US');
        Observer.Verify();
    end;

    [Test]
    procedure FormatRegion_SetDeDE_FormatAndColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LangRun('region', Observer);
        Observer.Expect('log', 'language before set equals GlobalLanguage=Yes region=[];region after set=[de-DE] Format changed=Yes;');
        Observer.Expect('columns', '<Column name="Id">1</Column>|<Column name="DecC" decimalformatter="#,##0.00">1234,5</Column>|<Column name="DateC">25.12.2024</Column>|<Column name="DtC">25.12.2024 14:30:05</Column>|<Column name="BoolC">True</Column>|');
        Observer.Expect('item language', 'en-US');
        Observer.Expect('item formatRegion', 'de-DE');
        Observer.Verify();
    end;

    [Test]
    procedure LanguageAndFormatRegion_BothSet_Columns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LangRun('both', Observer);
        Observer.Expect('log', 'language before set equals GlobalLanguage=Yes region=[];both set language=1031 region=[de-DE];');
        Observer.Expect('columns', '<Column name="Id">1</Column>|<Column name="DecC" decimalformatter="#,##0.00">1234,5</Column>|<Column name="DateC">25.12.2024</Column>|<Column name="DtC">25.12.2024 14:30:05</Column>|<Column name="BoolC">True</Column>|');
        Observer.Expect('item language', 'de-DE');
        Observer.Expect('item formatRegion', 'de-DE');
        Observer.Verify();
    end;

    [Test]
    procedure Language_RejectedValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LangRun('rejects', Observer);
        Observer.Expect('log', 'language before set equals GlobalLanguage=Yes region=[];Language 0 error=Invalid language ID supplied: 0. code=Argument;Language -1 accepted, reads 1033;Language 65536 error=An unsupported language was selected (''65536'' - ''Requested culture is not supported by the current platform''). code=ReportLanguageNotFound;Language 1 error=An unsupported language was selected (''1'' - ''Requested culture is not supported by the current platform''). code=ReportLanguageNotFound;language after the rejects=1033;');
        Observer.Expect('columns', '<Column name="Id">1</Column>|<Column name="DecC" decimalformatter="#,##0.00">1234.5</Column>|<Column name="DateC">12/25/2024</Column>|<Column name="DtC">12/25/2024 2:30:05 PM</Column>|<Column name="BoolC">True</Column>|');
        Observer.Expect('item language', 'en-US');
        Observer.Expect('item formatRegion', 'en-US');
        Observer.Verify();
    end;

    [Test]
    procedure FormatRegion_OddValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LangRun('regions', Observer);
        Observer.Expect('log', 'language before set equals GlobalLanguage=Yes region=[];region xx-YY error=An unsupported language was selected (''xx-YY'' - ''Requested culture is not supported by the current platform''). code=ReportFormatCultureNotFound;region de error=An unsupported language was selected (''de'' - ''Requested culture is not supported by the current platform''). code=ReportFormatCultureNotFound;region empty error=Invalid language ID supplied: 0. code=Argument;region fr-FR accepted, reads [fr-FR];');
        Observer.Expect('columns', '<Column name="Id">1</Column>|<Column name="DecC" decimalformatter="#,##0.00">1234,5</Column>|<Column name="DateC">25/12/2024</Column>|<Column name="DtC">25/12/2024 14:30:05</Column>|<Column name="BoolC">True</Column>|');
        Observer.Expect('item language', 'en-US');
        Observer.Expect('item formatRegion', 'fr-FR');
        Observer.Verify();
    end;

    // Writer QV (AL Runner issue 5666): CurrReport.Preview for report 87470 per start mode (log of the report and request page triggers,
    // and the dataset column values where the start mode gives a dataset).
    local procedure QvColumns(Xml: Text): Text
    var
        Line: Text;
        Lf: Text[1];
        Result: Text;
    begin
        Lf[1] := 10;
        foreach Line in Xml.Split(Lf) do
            if Line.Contains('<Column name="Preview') then
                Result += Line.Trim() + '|';
        exit(Result);
    end;

    [Test]
    procedure QV_Preview_SaveAsXml_Column()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Xml: Text;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS);
        ClearLastError();
        Observer.Observe('saved', Format(Report.SaveAs(Report::"LT QV Preview Rpt", '', ReportFormat::Xml, OutS)));
        Observer.ObserveError('save error');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Xml += Line + Dataset.Lf();
        end;
        Observer.Observe('columns', QvColumns(Xml));
        Observer.Observe('log', L.Take());
        Observer.Expect('saved', 'Yes');
        Observer.Expect('save error|text', '');
        Observer.Expect('save error|code', '');
        Observer.Expect('columns', '<Column name="PreviewValue">False</Column>|<Column name="PreviewLogged">False</Column>|');
        Observer.Expect('log', 'init preview=No;pre preview=No;get preview=No;column preview=No;post preview=No;');
        Observer.Verify();
    end;

    [Test]
    procedure QV_Preview_SaveAsPdf()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS);
        ClearLastError();
        Observer.Observe('saved', Format(Report.SaveAs(Report::"LT QV Preview Rpt", '', ReportFormat::Pdf, OutS)));
        Observer.ObserveError('save error');
        Observer.Observe('has output', Format(TempBlob.Length() > 0));
        Observer.Observe('log', L.Take());
        Observer.Expect('saved', 'Yes');
        Observer.Expect('save error|text', '');
        Observer.Expect('save error|code', '');
        Observer.Expect('has output', 'Yes');
        Observer.Expect('log', 'init preview=No;pre preview=No;get preview=No;column preview=No;post preview=No;');
        Observer.Verify();
    end;

    [Test]
    procedure QV_Preview_Execute()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        Seed();
        Observer.Observe('ok', Format(Runner.Exec(Report::"LT QV Preview Rpt", 5, '', Result)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'init preview=No;pre preview=Yes;get preview=Yes;column preview=Yes;post preview=Yes;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QvPreviewRequestHandler')]
    procedure QV_Preview_RunRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        Seed();
        QvRpAction := 'ok';
        Observer.Observe('ok', Format(Runner.Exec(Report::"LT QV Preview Rpt", 2, '', Result)));
        Observer.ObserveError('error');
        Observer.Observe('has parameters', Format(Result <> ''));
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('has parameters', 'Yes');
        Observer.Expect('log', 'init preview=No;rp open preview=No;rp close OK preview=No;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QvPreviewRequestHandler')]
    procedure QV_Preview_Run_PreviewAction()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        Seed();
        QvRpAction := 'preview';
        Observer.Observe('ok', Format(Runner.Exec(Report::"LT QV Preview Rpt", 0, '', Result)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'init preview=No;rp open preview=No;rp close Preview preview=No;pre preview=Yes;get preview=Yes;column preview=Yes;post preview=Yes;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QvPreviewRequestHandler')]
    procedure QV_Preview_Run_PrintAction()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        Seed();
        QvRpAction := 'print';
        Observer.Observe('ok', Format(Runner.Exec(Report::"LT QV Preview Rpt", 0, '', Result)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'init preview=No;rp open preview=No;rp close Print preview=No;pre preview=No;get preview=No;column preview=No;post preview=No;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure QvPreviewRequestHandler(var RP: TestRequestPage "LT QV Preview Rpt")
    begin
        case QvRpAction of
            'ok':
                if not QvTryInvoke(RP, 'ok') then
                    L.Add('OK error=' + GetLastErrorText());
            'preview':
                if not QvTryInvoke(RP, 'preview') then
                    L.Add('Preview error=' + GetLastErrorText());
            'print':
                if not QvTryInvoke(RP, 'print') then
                    L.Add('Print error=' + GetLastErrorText());
        end;
    end;

    [TryFunction]
    local procedure QvTryInvoke(var RP: TestRequestPage "LT QV Preview Rpt"; What: Text)
    begin
        case What of
            'ok':
                RP.OK().Invoke();
            'preview':
                RP.Preview().Invoke();
            'print':
                RP.Print().Invoke();
        end;
    end;

    // Writer RB: SaveAs Xml of report 87800 with nothing set, after GlobalLanguage(1031), and with Language / FormatRegion set on the
    // report variable before SaveAs. GlobalLanguage is put back.
    // BC 29.0: a language (global or on the variable) changes only Format() texts (Yes/Ja) and the item language; FormatRegion changes
    // the column values and Format() texts of decimals, dates and times.
    local procedure RbRun(var Rpt: Report "LT RB Fmt Rpt"; var Observer: Codeunit "Probe Observer")
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Xml: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        Observer.Observe('saved', Format(Rpt.SaveAs('', ReportFormat::Xml, OutS), 0, 9));
        Xml := Dataset.ReadAll(TempBlob);
        Observer.Observe('log', L.Take());
        Observer.Observe('columns', Dataset.ColumnLines(Xml));
        Observer.Observe('item language', Dataset.ItemAttribute(Xml, 1, 'language'));
        Observer.Observe('item formatRegion', Dataset.ItemAttribute(Xml, 1, 'formatRegion'));
    end;

    [Test]
    procedure RB_SaveAs_NothingSet()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RB Fmt Rpt";
    begin
        Seed();
        RbRun(Rpt, Observer);
        Observer.Expect('saved', 'true');
        Observer.Expect('log', 'pre language=1033 region=[] global=1033;');
        Observer.Expect('columns', '<Column name="Id">1</Column>|<Column name="DecC" decimalformatter="#,##0.00">1234.5</Column>|<Column name="NegDecC" decimalformatter="#,##0.00">-1234567.891</Column>|<Column name="IntC">1234567</Column>|<Column name="DateC">3/5/2024</Column>|<Column name="TimeC">9:30:05 AM</Column>|<Column name="DtC">3/5/2024 9:30:05 AM</Column>|<Column name="BoolC">True</Column>|<Column name="FmtC">1,234.5|-1,234,567.891|1234567|03/05/24| 9:30:05 AM|Yes</Column>|');
        Observer.Expect('item language', 'en-US');
        Observer.Expect('item formatRegion', 'en-US');
        Observer.Verify();
    end;

    [Test]
    procedure RB_SaveAs_AfterGlobalLanguage1031()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RB Fmt Rpt";
        OldLanguage: Integer;
    begin
        Seed();
        OldLanguage := GlobalLanguage();
        Observer.Observe('set 1031 ok', Format(TrySetGlobalLanguage(1031), 0, 9));
        RbRun(Rpt, Observer);
        TrySetGlobalLanguage(OldLanguage);
        Observer.Observe('language restored', Format(GlobalLanguage() = OldLanguage, 0, 9));
        Observer.Expect('set 1031 ok', 'true');
        Observer.Expect('saved', 'true');
        Observer.Expect('log', 'pre language=1031 region=[] global=1031;');
        Observer.Expect('columns', '<Column name="Id">1</Column>|<Column name="DecC" decimalformatter="#,##0.00">1234.5</Column>|<Column name="NegDecC" decimalformatter="#,##0.00">-1234567.891</Column>|<Column name="IntC">1234567</Column>|<Column name="DateC">3/5/2024</Column>|<Column name="TimeC">9:30:05 AM</Column>|<Column name="DtC">3/5/2024 9:30:05 AM</Column>|<Column name="BoolC">True</Column>|<Column name="FmtC">1,234.5|-1,234,567.891|1234567|03/05/24| 9:30:05 AM|Ja</Column>|');
        Observer.Expect('item language', 'de-DE');
        Observer.Expect('item formatRegion', 'en-US');
        Observer.Expect('language restored', 'true');
        Observer.Verify();
    end;

    [Test]
    procedure RB_SaveAs_ReportVariableLanguage1031()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RB Fmt Rpt";
    begin
        Seed();
        Rpt.Language := 1031;
        Observer.Observe('read before run', Format(Rpt.Language));
        RbRun(Rpt, Observer);
        Observer.Expect('read before run', '1031');
        Observer.Expect('saved', 'true');
        Observer.Expect('log', 'pre language=1031 region=[] global=1033;');
        Observer.Expect('columns', '<Column name="Id">1</Column>|<Column name="DecC" decimalformatter="#,##0.00">1234.5</Column>|<Column name="NegDecC" decimalformatter="#,##0.00">-1234567.891</Column>|<Column name="IntC">1234567</Column>|<Column name="DateC">3/5/2024</Column>|<Column name="TimeC">9:30:05 AM</Column>|<Column name="DtC">3/5/2024 9:30:05 AM</Column>|<Column name="BoolC">True</Column>|<Column name="FmtC">1,234.5|-1,234,567.891|1234567|03/05/24| 9:30:05 AM|Ja</Column>|');
        Observer.Expect('item language', 'de-DE');
        Observer.Expect('item formatRegion', 'en-US');
        Observer.Verify();
    end;

    [Test]
    procedure RB_SaveAs_ReportVariableFormatRegionDeDE()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RB Fmt Rpt";
    begin
        Seed();
        Rpt.FormatRegion := 'de-DE';
        Observer.Observe('read before run', Rpt.FormatRegion);
        RbRun(Rpt, Observer);
        Observer.Expect('read before run', 'de-DE');
        Observer.Expect('saved', 'true');
        Observer.Expect('log', 'pre language=1033 region=[de-DE] global=1033;');
        Observer.Expect('columns', '<Column name="Id">1</Column>|<Column name="DecC" decimalformatter="#,##0.00">1234,5</Column>|<Column name="NegDecC" decimalformatter="#,##0.00">-1234567,891</Column>|<Column name="IntC">1234567</Column>|<Column name="DateC">05.03.2024</Column>|<Column name="TimeC">09:30:05</Column>|<Column name="DtC">05.03.2024 09:30:05</Column>|<Column name="BoolC">True</Column>|<Column name="FmtC">1.234,5|-1.234.567,891|1234567|05.03.24|09:30:05|Yes</Column>|');
        Observer.Expect('item language', 'en-US');
        Observer.Expect('item formatRegion', 'de-DE');
        Observer.Verify();
    end;
}
