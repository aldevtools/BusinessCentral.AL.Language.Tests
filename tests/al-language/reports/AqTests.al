// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (System Application); objects of AqFixtures.al; test codeunits 79750-79753
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced (corpus issue 646).
// Facts: CurrReport.Language out of range (item 11), the data item systemId of two SaveAs runs (12), RequestOptionsPage.Caption set in
// OnOpenPage (13), SaveValues on a report extension request page (14), stored filter against SetTableView and a record passed to
// Report.RunModal (15), CalcFields on an extension data item and on a normal field (16), a procedure filter before RunModal (17),
// WordMergeDataItem and the SaveAs Xml data set (18), Report.WordXmlPart texts (19), the legacy ExcelLayout property (22),
// a layout without Subtype (24), RunRequestPage with a pending insert (5), seeded parameters against OnInit and an unknown option control (8),
// Invoke on a disabled and on a hidden request page action (9).
// BC versions: 27-29

codeunit 79750 "LT AQ Report Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT AQ Log";

    local procedure Seed()
    var
        Row: Record "LT AQ Row";
        Entry: Record "LT AQ Entry";
    begin
        Row.DeleteAll();
        Entry.DeleteAll();
        AddRow('A1', 1.5, 'n1');
        AddRow('A2', 2, 'n2');
        AddRow('B1', 3, 'n3');
        AddRow('C1', 4, '');
        Entry.EntryNo := 1; Entry.RowCode := 'A1'; Entry.Qty := 2; Entry.Insert();
        Entry.EntryNo := 2; Entry.RowCode := 'A1'; Entry.Qty := 3; Entry.Insert();
        Entry.EntryNo := 3; Entry.RowCode := 'B1'; Entry.Qty := 7; Entry.Insert();
        Commit();
        Log.Take();
    end;

    local procedure AddRow(NewCode: Code[20]; NewAmount: Decimal; NewName: Text[30])
    var
        Row: Record "LT AQ Row";
    begin
        Row.Code := NewCode;
        Row.Amount := NewAmount;
        Row.Name := NewName;
        Row.Insert();
    end;

    local procedure XmlOf(ReportId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Xml: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(ReportId, '', ReportFormat::Xml, OutS);
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Xml += Line + '|';
        end;
        exit(Xml);
    end;

    [TryFunction]
    local procedure TryXmlOf(ReportId: Integer; var Xml: Text)
    begin
        Xml := XmlOf(ReportId);
    end;

    local procedure DataItemsOf(Xml: Text): Text
    var
        At: Integer;
    begin
        At := StrPos(Xml, '<DataItems>');
        if At = 0 then
            exit('no DataItems element');
        exit(CopyStr(Xml, At));
    end;

    // Every systemId attribute value of the text, comma separated.
    local procedure SystemIds(Xml: Text): Text
    var
        Marker: Text;
        At: Integer;
        Result: Text;
    begin
        Marker := ' systemId="';
        At := StrPos(Xml, Marker);
        while At > 0 do begin
            Xml := CopyStr(Xml, At + StrLen(Marker));
            Result += CopyStr(Xml, 1, StrPos(Xml, '"') - 1) + ',';
            At := StrPos(Xml, Marker);
        end;
        exit(Result);
    end;

    // Per layout of the report: the Name, Layout Format, Description and User Defined columns of the Report Layout List row, and every column whose name holds
    // Subtype (Layout Subtype exists from BC 29 only; BC 28 adds Layout Status and BC 29 HeaderFooterPart and ThemePart, not asserted).
    local procedure LayoutRows(ReportId: Integer): Text
    var
        LayoutList: Record "Report Layout List";
        RR: RecordRef;
        FR: FieldRef;
        i: Integer;
        Result: Text;
    begin
        LayoutList.SetRange("Report ID", ReportId);
        if LayoutList.FindSet() then
            repeat
                RR.GetTable(LayoutList);
                Result += '[';
                for i := 1 to RR.FieldCount() do begin
                    FR := RR.FieldIndex(i);
                    if (FR.Name in ['Name', 'Layout Format', 'Description', 'User Defined']) or FR.Name.Contains('Subtype') then
                        Result += FR.Name + '=' + Format(FR.Value) + ' ';
                end;
                Result += ']';
            until LayoutList.Next() = 0
        else
            Result := 'no layouts';
        exit(Result);
    end;

    [Test]
    procedure Language_OutOfRange_SaveAs()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        XmlOf(Report::"LT AQ Lang");
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', '70000 error=An unsupported language was selected (''70000'' - ''Requested culture is not supported by the current platform''). code=ReportLanguageNotFound;99998 error=An unsupported language was selected (''99998'' - ''Requested culture is not supported by the current platform''). code=ReportLanguageNotFound;after=1033 global=Yes;');
        Observer.Verify();
    end;

    [Test]
    procedure Language_OutOfRange_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT AQ Lang Run");
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', '70000 error=An unsupported language was selected (''70000'' - ''Requested culture is not supported by the current platform''). code=ReportLanguageNotFound;99998 error=An unsupported language was selected (''99998'' - ''Requested culture is not supported by the current platform''). code=ReportLanguageNotFound;after=1033 global=Yes;');
        Observer.Verify();
    end;

    [Test]
    procedure SystemId_TwoRuns_SameAsRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AQ Row";
        First: Text;
        Second: Text;
        Expected: Text;
    begin
        Seed();
        First := SystemIds(XmlOf(Report::"LT AQ Rows"));
        Second := SystemIds(XmlOf(Report::"LT AQ Rows"));
        Row.FindSet();
        repeat
            Expected += LowerCase(DelChr(Format(Row.SystemId), '=', '{}')) + ',';
        until Row.Next() = 0;
        Observer.Observe('count', Format(StrLen(First) div 37));
        Observer.Observe('runs equal', Format(First = Second));
        Observer.Observe('equal to row SystemIds', Format(First = Expected));
#if BC28PLUS
        Observer.Expect('count', '4');
        Observer.Expect('runs equal', 'Yes');
        Observer.Expect('equal to row SystemIds', 'Yes');
#else
        // BC 27 writes no systemId attribute.
        Observer.Expect('count', '0');
        Observer.Expect('runs equal', 'Yes');
        Observer.Expect('equal to row SystemIds', 'No');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure CalcFields_ExtensionDataItem_Values()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
    begin
        Seed();
        Xml := DataItemsOf(XmlOf(Report::"LT AQ CalcF Base"));
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'ext A1 sum=5 cnt=2;');
        Observer.Verify();
    end;

    [Test]
    procedure CalcFields_NormalField_Run()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
    begin
        Seed();
        ClearLastError();
        Observer.Observe('ok', Format(TryXmlOf(Report::"LT AQ CalcF Normal", Xml)));
        Observer.ObserveError('error');
        Observer.Observe('log', Log.Take());
        Observer.Expect('ok', 'No');
        Observer.Expect('error|text', 'The Amount field in the LT AQ Row table must be a FlowField.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    procedure WordMergeDataItem_SaveAsXml_SameDataSet()
    var
        Observer: Codeunit "Probe Observer";
        WithProp: Text;
        Without: Text;
    begin
        Seed();
        // The decimalformatter of the EQty column follows General Ledger Setup "Amount Decimal Places" as the session first read
        // it (diagnostic runs 39255002308 and 39256045991, BC 27.5, 28.5 and 29.0); SelectLatestVersion makes it independent of
        // earlier tests that set '2:5' and roll it back.
        SelectLatestVersion();
        WithProp := DataItemsOf(XmlOf(Report::"LT AQ WM On"));
        Without := DataItemsOf(XmlOf(Report::"LT AQ WM Off"));
        Observer.Observe('equal', Format(WithProp = Without));
        Observer.Observe('length on', Format(StrLen(WithProp)));
        Observer.Observe('length off', Format(StrLen(Without)));
        Observer.Expect('equal', 'Yes');
#if BC28PLUS
        // BC 28 adds the tableId and systemId attributes to every DataItem element (64 characters each, 7 elements).
        Observer.Expect('length on', '1708');
        Observer.Expect('length off', '1708');
#else
        Observer.Expect('length on', '1260');
        Observer.Expect('length off', '1260');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_NestedSpecialNames()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT AQ Word Xml"));
        Observer.Observe('extended equal', Format(Report.WordXmlPart(Report::"LT AQ Word Xml", true) = Report.WordXmlPart(Report::"LT AQ Word Xml")));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-nav/reports/LT_AQ_Word_Xml/79720/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <Par_Item>\r\n    <Amt_x>Amt_x</Amt_x>\r\n    <Par_Code>Par_Code</Par_Code>\r\n    <Sales__x0026__Line_x>\r\n      <Qty_No>Qty_No</Qty_No>\r\n    </Sales__x0026__Line_x>\r\n  </Par_Item>\r\n</NavWordReportXmlPart>');
        Observer.Expect('extended equal', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_ReportExtension()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT AQ Word Xml Ext Base"));
        Observer.Observe('extended', Report.WordXmlPart(Report::"LT AQ Word Xml Ext Base", true));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-nav/reports/LT_AQ_Word_Xml_Ext_Base/79721/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <Base>\r\n    <BCode>BCode</BCode>\r\n    <XName>XName</XName>\r\n    <XEnt>\r\n      <XQty>XQty</XQty>\r\n    </XEnt>\r\n  </Base>\r\n</NavWordReportXmlPart>');
        Observer.Expect('extended', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-businesscentral/internal/extended/reports/LT_AQ_Word_Xml_Ext_Base/79721/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <Tooltips />\r\n  <Base ElementType="DataItem" ElementId="440217728">\r\n    <BCode ElementType="Column" ElementId="1669706382" DataType="Code">BCode</BCode>\r\n    <XName ElementType="Column" ElementId="1999091266" DataType="Text">XName</XName>\r\n    <XEnt ElementType="DataItem" ElementId="810720154">\r\n      <XQty ElementType="Column" ElementId="439971967" DataType="Decimal">XQty</XQty>\r\n    </XEnt>\r\n  </Base>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure ExcelLayout_Legacy_DefaultAndLayoutList()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('default', Format(Report.DefaultLayout(Report::"LT AQ Excel Legacy")));
        Observer.Observe('rows', LayoutRows(Report::"LT AQ Excel Legacy"));
        Observer.Expect('default', 'RDLC');
#if BC29PLUS
        Observer.Expect('rows', '[Name=./report/lt-aq/LtAqExcelLegacy.xlsx Layout Format=Excel Description=./report/lt-aq/LtAqExcelLegacy.xlsx User Defined=No Layout Subtype=Default ]');
#else
        Observer.Expect('rows', '[Name=./report/lt-aq/LtAqExcelLegacy.xlsx Layout Format=Excel Description=./report/lt-aq/LtAqExcelLegacy.xlsx User Defined=No ]');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Layout_NoSubtype_DefaultAndLayoutList()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('default', Format(Report.DefaultLayout(Report::"LT AQ No Subtype")));
        Observer.Observe('rows', LayoutRows(Report::"LT AQ No Subtype"));
        Observer.Expect('default', 'Word');
#if BC29PLUS
        Observer.Expect('rows', '[Name=AqRdlcFirst Layout Format=RDLC Description=AqRdlcFirst User Defined=No Layout Subtype=Default ][Name=AqWordNoSub Layout Format=Word Description=AqWordNoSub User Defined=No Layout Subtype=Default ]');
#else
        Observer.Expect('rows', '[Name=AqRdlcFirst Layout Format=RDLC Description=AqRdlcFirst User Defined=No ][Name=AqWordNoSub Layout Format=Word Description=AqWordNoSub User Defined=No ]');
#endif
        Observer.Verify();
    end;
}

codeunit 79751 "LT AQ Req Page Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT AQ Log Req Page";
        SeenCaption: Text;
        SeenValues: Text;
        ActionResults: Text;
        ReadPhase: Boolean;

    [Test]
    [HandlerFunctions('CaptionHandler')]
    procedure Caption_SetInOnOpenPage_TestRequestPageCaption()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeenCaption := '';
        Report.Run(Report::"LT AQ Caption");
        Observer.Observe('caption', SeenCaption);
        Observer.Expect('caption', 'LT AQ caption set in OnOpenPage');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure CaptionHandler(var RP: TestRequestPage "LT AQ Caption")
    begin
        SeenCaption := RP.Caption();
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('ActionsHandler')]
    procedure Actions_DisabledAndHidden_Invoke()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
    begin
        Log.SetMode(0);
        Log.Take();
        ActionResults := '';
        Params := Report.RunRequestPage(Report::"LT AQ Req Page");
        Observer.Observe('results', ActionResults);
        Observer.Observe('log', Log.Take());
        Observer.Expect('results', 'disabled: The action with ID = n is not found on the page. code=TestActionNotFound;hidden: The action with ID = n is not found on the page. code=TestActionNotFound;');
        Observer.Expect('log', 'OnInit int=0 opt=Alpha;OnOpenPage int=0 opt=Alpha;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ActionsHandler(var RP: TestRequestPage "LT AQ Req Page")
    begin
        asserterror RP.DisAct.Invoke();
        ActionResults += 'disabled: ' + GetLastErrorText() + ' code=' + GetLastErrorCode() + ';';
        asserterror RP.InvAct.Invoke();
        ActionResults += 'hidden: ' + GetLastErrorText() + ' code=' + GetLastErrorCode() + ';';
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('ValuesHandler')]
    procedure Seeded_OnInitSetsControl_HandlerReads()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
    begin
        Log.SetMode(1);
        Log.Take();
        Params := Report.RunRequestPage(Report::"LT AQ Req Page");
        Log.Take();
        SeenValues := '';
        ReadPhase := true;
        Params := Report.RunRequestPage(Report::"LT AQ Req Page", Params);
        ReadPhase := false;
        Log.SetMode(0);
        Observer.Observe('handler', SeenValues);
        Observer.Observe('log', Log.Take());
        Observer.Expect('handler', 'int=9 opt=Gamma');
        Observer.Expect('log', 'OnInit int=5 opt=Alpha;OnOpenPage int=9 opt=Gamma;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ValuesHandler')]
    procedure Seeded_UnknownOptionControl()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
    begin
        Log.SetMode(0);
        Log.Take();
        Params := Report.RunRequestPage(Report::"LT AQ Req Page");
        Observer.Observe('options', CopyStr(Params, StrPos(Params, '<Options>'), StrPos(Params, '</Options>') - StrPos(Params, '<Options>') + 10));
        Params := Params.Replace('name="OptVal"', 'name="GoneOpt"');
        Log.Take();
        SeenValues := '';
        ClearLastError();
        ReadPhase := true;
        Params := Report.RunRequestPage(Report::"LT AQ Req Page", Params);
        ReadPhase := false;
        Observer.ObserveError('error');
        Observer.Observe('handler', SeenValues);
        Observer.Observe('log', Log.Take());
        Observer.Expect('options', '<Options><Field name="IntVal">9</Field><Field name="OptVal">2</Field></Options>');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('handler', 'int=9 opt=Alpha');
        Observer.Expect('log', 'OnInit int=0 opt=Alpha;OnOpenPage int=9 opt=Alpha;');
        Observer.Verify();
    end;

    // The first RunRequestPage of a test (no value seeded) sets IntCtl 9 and OptCtl Gamma; the second one reads them.
    [RequestPageHandler]
    procedure ValuesHandler(var RP: TestRequestPage "LT AQ Req Page")
    begin
        if ReadPhase then
            SeenValues := 'int=' + RP.IntCtl.Value() + ' opt=' + RP.OptCtl.Value()
        else begin
            RP.IntCtl.SetValue(9);
            RP.OptCtl.SetValue('Gamma');
        end;
        RP.OK().Invoke();
    end;

    // RunRequestPage is refused before the request page opens, so the test declares no handler.
    [Test]
    procedure PendingInsert_RunRequestPage_InTheTest()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
        Row: Record "LT AQ Row";
    begin
        Row.DeleteAll();
        Commit();
        Row.Code := 'P1';
        Row.Insert();
        asserterror Params := Report.RunRequestPage(Report::"LT AQ Req Page");
        Observer.ObserveError('error');
        Observer.Observe('count after', Format(Row.Count()));
        Observer.Expect('error|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('count after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure PendingInsert_RunRequestPage_NextTest()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AQ Row";
    begin
        Observer.Observe('count', Format(Row.Count()));
        Observer.Expect('count', '0');
        Observer.Verify();
    end;
}

codeunit 79752 "LT AQ Saved Ext Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT AQ Log Saved Ext";
        SeenValues: Text;

    [Test]
    [HandlerFunctions('SetHandler')]
    procedure SavedExt_1_SetAndOK()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Report.Run(Report::"LT AQ Saved");
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'base=11;ext var=22 ext field=[nm];');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ReadHandler')]
    procedure SavedExt_2_NextRunShows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        SeenValues := '';
        Report.Run(Report::"LT AQ Saved");
        Observer.Observe('handler', SeenValues);
        Observer.Observe('log', Log.Take());
        Observer.Expect('handler', 'base=11 ext var=22 ext field=[nm]');
        Observer.Expect('log', 'base=11;ext var=22 ext field=[nm];');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure SetHandler(var RP: TestRequestPage "LT AQ Saved")
    begin
        RP.BaseCtl.SetValue(11);
        RP.ExtVarCtl.SetValue(22);
        RP.ExtFieldCtl.SetValue('nm');
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure ReadHandler(var RP: TestRequestPage "LT AQ Saved")
    begin
        SeenValues := 'base=' + RP.BaseCtl.Value() + ' ext var=' + RP.ExtVarCtl.Value() + ' ext field=[' + RP.ExtFieldCtl.Value() + ']';
        RP.OK().Invoke();
    end;
}

codeunit 79753 "LT AQ Filter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT AQ Log Filter";
        SeenFilter: Text;

    local procedure Seed()
    var
        Row: Record "LT AQ Row";
    begin
        Row.DeleteAll();
        Row.Code := 'A1'; Row.Insert();
        Row.Code := 'A2'; Row.Insert();
        Row.Code := 'B1'; Row.Insert();
        Row.Code := 'C1'; Row.Insert();
        Commit();
        Log.Take();
    end;

    [Test]
    [HandlerFunctions('FilterHandler')]
    procedure SavedFilter_StoredThenSetTableViewAndRunModalRecord()
    var
        Observer: Codeunit "Probe Observer";
        View: Record "LT AQ Row";
        Stored: Report "LT AQ Saved Filter";
        WithView: Report "LT AQ Saved Filter";
        Plain: Report "LT AQ Saved Filter";
    begin
        Seed();
        Log.SetMode(1);
        Stored.RunModal();
        Observer.Observe('stored A* run', Log.Take());

        Log.SetMode(2);
        SeenFilter := '';
        View.SetFilter(Code, 'C*');
        WithView.SetTableView(View);
        WithView.RunModal();
        Observer.Observe('SetTableView C* page', SeenFilter);
        Observer.Observe('SetTableView C* run', Log.Take());

        SeenFilter := '';
        Report.RunModal(Report::"LT AQ Saved Filter", true, false, View);
        Observer.Observe('RunModal record C* page', SeenFilter);
        Observer.Observe('RunModal record C* run', Log.Take());

        Log.SetMode(3);
        SeenFilter := '';
        Plain.RunModal();
        Log.SetMode(0);
        Observer.Observe('plain afterwards page', SeenFilter);
        Observer.Observe('plain afterwards run', Log.Take());
        Observer.Expect('stored A* run', 'pre count=2 filter=[A*];row A1;row A2;');
        Observer.Expect('SetTableView C* page', '[C*]');
        Observer.Expect('SetTableView C* run', 'pre count=1 filter=[C*];row C1;');
        Observer.Expect('RunModal record C* page', '[C*]');
        Observer.Expect('RunModal record C* run', 'pre count=1 filter=[C*];row C1;');
        Observer.Expect('plain afterwards page', '[C*]');
        Observer.Expect('plain afterwards run', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ProcFilterHandler')]
    procedure ProcedureFilter_BeforeRunModal_OK()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT AQ Proc Filter";
    begin
        Seed();
        SeenFilter := '';
        Rep.SetCallerFilter('B*');
        Rep.RunModal();
        Observer.Observe('page', SeenFilter);
        Observer.Observe('run', Log.Take());
        Observer.Expect('page', '[]');
        Observer.Expect('run', 'pre count=4 filter=[];row A1;row A2;row B1;row C1;');
        Observer.Verify();
    end;

    // Mode 1: set A* and OK. Mode 2: read the filter and OK. Mode 3: read the filter and Cancel.
    [RequestPageHandler]
    procedure FilterHandler(var RP: TestRequestPage "LT AQ Saved Filter")
    begin
        if Log.Mode() = 1 then begin
            RP.RowDi.SetFilter(Code, 'A*');
            RP.OK().Invoke();
            exit;
        end;
        SeenFilter := '[' + RP.RowDi.GetFilter(Code) + ']';
        if Log.Mode() = 2 then
            RP.OK().Invoke()
        else
            RP.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure ProcFilterHandler(var RP: TestRequestPage "LT AQ Proc Filter")
    begin
        SeenFilter := '[' + RP.RowDi.GetFilter(Code) + ']';
        RP.OK().Invoke();
    end;
}
