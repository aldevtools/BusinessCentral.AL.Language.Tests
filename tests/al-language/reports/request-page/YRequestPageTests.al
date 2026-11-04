// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-request-page
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Y Helper (75500), LT Y Seen (75501), YRequestPage.al (table 75530, reports 75531-75540), RsRequestPageRec.al (reports 88560-88564, 88566)
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced.
// Facts: see YRequestPage.al.
// BC versions: 27-29

codeunit 75512 "LT Y Request Page Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Y Helper";
        Seen: Codeunit "LT Y Seen";

    local procedure Seed()
    var
        Line: Record "LT Y Line";
    begin
        Line.DeleteAll();
        Seen.Reset();
        InsertLine('A', 10000, 'first');
        InsertLine('A', 20000, 'second');
        InsertLine('B', 10000, 'other');
        Commit();
    end;

    local procedure InsertLine(DocNo: Code[10]; LineNo: Integer; Descr: Text[30])
    var
        Line: Record "LT Y Line";
    begin
        Line.Init();
        Line.DocNo := DocNo;
        Line.LineNo := LineNo;
        Line.Descr := Descr;
        Line.Insert();
    end;

    local procedure Rows(): Text
    var
        Line: Record "LT Y Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                Result += Line.DocNo + '/' + Format(Line.LineNo) + '/' + Line.Descr + ';';
            until Line.Next() = 0;
        exit(Result);
    end;

    local procedure ObserveSeen(var Observer: Codeunit "Probe Observer"; Names: Text)
    var
        Name: Text;
    begin
        foreach Name in Names.Split(',') do
            Observer.Observe(Name, Seen.Get(Name));
    end;

    // ---- SourceTableView

    [RequestPageHandler]
    procedure ViewHandler(var RP: TestRequestPage "LT Y RP View")
    begin
        Seen.Put('caption', RP.Caption());
        Seen.Put('docno', RP.DocNoCtl.Value());
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('ViewHandler')]
    procedure SourceTableView_RequestPageRecord_HasTheView()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT Y RP View");
        ObserveSeen(Observer, 'view,filters,count,temporary,caption,docno');
        Observer.Expect('view', 'VERSION(1) SORTING(DocNo,LineNo)');
        Observer.Expect('filters', '');
        Observer.Expect('count', '3');
        Observer.Expect('temporary', 'No');
        Observer.Expect('caption', 'LT Y RP View');
        Observer.Expect('docno', 'A');
        Observer.Verify();
    end;

    // ---- SourceTableTemporary

    [RequestPageHandler]
    procedure TempHandler(var RP: TestRequestPage "LT Y RP Temp")
    begin
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('TempHandler')]
    procedure SourceTableTemporary_RequestPageRecords_AreNotStored()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT Y RP Temp");
        ObserveSeen(Observer, 'temporary,count_before,count_after');
        Observer.Observe('rows', Rows());
        Observer.Expect('temporary', 'Yes');
        Observer.Expect('count_before', '0');
        Observer.Expect('count_after', '1');
        Observer.Expect('rows', 'A/10000/first;A/20000/second;B/10000/other;');
        Observer.Verify();
    end;

    // ---- DeleteAllowed / ModifyAllowed

    [TryFunction]
    local procedure TryModifyLocked(var RP: TestRequestPage "LT Y RP Locked")
    begin
        RP.DescrCtl.SetValue('changed');
    end;

    [TryFunction]
    local procedure TryNewLocked(var RP: TestRequestPage "LT Y RP Locked")
    begin
        RP.New();
    end;

    [RequestPageHandler]
    procedure LockedHandler(var RP: TestRequestPage "LT Y RP Locked")
    begin
        Seen.Put('caption', RP.Caption());
        Seen.Put('docno', RP.DocNoCtl.Value());
        Seen.Put('editable', Format(RP.DescrCtl.Editable()));
        if TryModifyLocked(RP) then
            Seen.Put('modify', 'ok ' + RP.DescrCtl.Value())
        else
            Seen.Put('modify', Helper.Failed());
        if TryNewLocked(RP) then
            Seen.Put('new', 'ok')
        else
            Seen.Put('new', Helper.Failed());
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('LockedHandler')]
    procedure DeleteAllowedModifyAllowed_False_Refuse()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT Y RP Locked");
        ObserveSeen(Observer, 'caption,docno,editable,modify,new');
        Observer.Observe('rows', Rows());
        Observer.Expect('caption', 'LT Y RP Locked');
        Observer.Expect('docno', 'A');
        Observer.Expect('editable', 'No');
        Observer.Expect('modify', 'ok changed');
        Observer.Expect('new', 'error:New method failed because Insert is not allowed. Page = LT Y RP Locked, Id = 0.|DB:ClientInsertDenied');
        Observer.Expect('rows', 'A/10000/first;A/20000/second;B/10000/other;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryModifyOpen(var RP: TestRequestPage "LT Y RP Open")
    begin
        RP.DescrCtl.SetValue('changed');
    end;

    [TryFunction]
    local procedure TryNewOpen(var RP: TestRequestPage "LT Y RP Open")
    begin
        RP.New();
    end;

    [RequestPageHandler]
    procedure OpenHandler(var RP: TestRequestPage "LT Y RP Open")
    begin
        Seen.Put('caption', RP.Caption());
        Seen.Put('docno', RP.DocNoCtl.Value());
        Seen.Put('editable', Format(RP.DescrCtl.Editable()));
        if TryModifyOpen(RP) then
            Seen.Put('modify', 'ok ' + RP.DescrCtl.Value())
        else
            Seen.Put('modify', Helper.Failed());
        if TryNewOpen(RP) then
            Seen.Put('new', 'ok')
        else
            Seen.Put('new', Helper.Failed());
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('OpenHandler')]
    procedure DeleteAllowedModifyAllowed_True_Succeed()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT Y RP Open");
        ObserveSeen(Observer, 'caption,docno,editable,modify,new');
        Observer.Observe('rows', Rows());
        Observer.Expect('caption', 'LT Y RP Open');
        Observer.Expect('docno', 'A');
        Observer.Expect('editable', 'Yes');
        Observer.Expect('modify', 'ok changed');
        Observer.Expect('new', 'ok');
        Observer.Expect('rows', 'A/10000/first;A/20000/second;B/10000/other;');
        Observer.Verify();
    end;

    // ---- DataCaptionFields / DataCaptionExpression

    [RequestPageHandler]
    procedure CaptionFieldsHandler(var RP: TestRequestPage "LT Y RP Caption Fields")
    begin
        Seen.Put('caption', RP.Caption());
        RP.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure CaptionExprHandler(var RP: TestRequestPage "LT Y RP Caption Expr")
    begin
        Seen.Put('caption', RP.Caption());
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('CaptionFieldsHandler')]
    procedure DataCaptionFields_RequestPage_Caption()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT Y RP Caption Fields");
        ObserveSeen(Observer, 'caption');
        Observer.Expect('caption', 'LT Y request');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CaptionExprHandler')]
    procedure DataCaptionExpression_RequestPage_Caption()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT Y RP Caption Expr");
        ObserveSeen(Observer, 'caption');
        Observer.Expect('caption', 'LT Y request');
        Observer.Verify();
    end;

    // ---- AutoSplitKey / MultipleNewLines

    [TryFunction]
    local procedure TryNewLines(var RP: TestRequestPage "LT Y RP Split")
    begin
        RP.GoToKey('A', 10000);
        RP.New();
        RP.DocNoCtl.SetValue('A');
        RP.DescrCtl.SetValue('inserted 1');
        Seen.Put('first_key', RP.LineNoCtl.Value());
        RP.New();
        RP.DocNoCtl.SetValue('A');
        RP.DescrCtl.SetValue('inserted 2');
        Seen.Put('second_key', RP.LineNoCtl.Value());
    end;

    [RequestPageHandler]
    procedure SplitHandler(var RP: TestRequestPage "LT Y RP Split")
    begin
        if TryNewLines(RP) then
            Seen.Put('new', 'ok')
        else
            Seen.Put('new', Helper.Failed());
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('SplitHandler')]
    procedure AutoSplitKey_NewLineBetweenLines_GetsSplitKey()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT Y RP Split");
        ObserveSeen(Observer, 'new,first_key,second_key');
        Observer.Observe('rows', Rows());
        Observer.Expect('new', 'ok');
        Observer.Expect('first_key', '0');
        Observer.Expect('second_key', '0');
        Observer.Expect('rows', 'A/10000/first;A/20000/second;A/30000/inserted 2;A/40000/inserted 1;B/10000/other;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryNewLinesNoSplit(var RP: TestRequestPage "LT Y RP NoSplit")
    begin
        RP.GoToKey('A', 10000);
        RP.New();
        RP.DocNoCtl.SetValue('A');
        RP.DescrCtl.SetValue('inserted 1');
        Seen.Put('first_key', RP.LineNoCtl.Value());
        RP.New();
        RP.DocNoCtl.SetValue('A');
        RP.DescrCtl.SetValue('inserted 2');
        Seen.Put('second_key', RP.LineNoCtl.Value());
    end;

    [RequestPageHandler]
    procedure NoSplitHandler(var RP: TestRequestPage "LT Y RP NoSplit")
    begin
        if TryNewLinesNoSplit(RP) then
            Seen.Put('new', 'ok')
        else
            Seen.Put('new', Helper.Failed());
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('NoSplitHandler')]
    procedure AutoSplitKey_NotSet_NewLineHasNoSplitKey()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT Y RP NoSplit");
        ObserveSeen(Observer, 'new,first_key,second_key');
        Observer.Observe('rows', Rows());
        Observer.Expect('new', 'ok');
        Observer.Expect('first_key', '0');
        Observer.Expect('second_key', '0');
        Observer.Expect('rows', 'A/0/inserted 2;A/10000/first;A/20000/second;B/10000/other;');
        Observer.Verify();
    end;

    // ---- CardPageId, LinksAllowed, PopulateAllFields, HelpLink

    [RequestPageHandler]
    procedure MiscHandler(var RP: TestRequestPage "LT Y RP Misc")
    begin
        Seen.Put('caption', RP.Caption());
        Seen.Put('docno', RP.DocNoCtl.Value());
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('MiscHandler')]
    procedure CardPageIdLinksAllowedPopulateAllFields_RequestPage_Opens()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT Y RP Misc");
        ObserveSeen(Observer, 'caption,docno');
        Observer.Expect('caption', 'LT Y RP Misc');
        Observer.Expect('docno', 'A');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure LinksHandler(var RP: TestRequestPage "LT Y RP Links")
    begin
        Seen.Put('caption', RP.Caption());
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('LinksHandler')]
    procedure LinksAllowed_True_RequestPage_Opens()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT Y RP Links");
        ObserveSeen(Observer, 'caption');
        Observer.Expect('caption', 'LT Y RP Links');
        Observer.Verify();
    end;

    [Test]
    procedure RequestPageReports_MetadataRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('misc', Helper.ReportFacts(Report::"LT Y RP Misc"));
        Observer.Observe('misc_items', Helper.DataItemRows(Report::"LT Y RP Misc"));
#if BC29PLUS
        Observer.Expect('misc', 'UseRequestPage=Yes;ProcessingOnly=Yes;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=RDLC;DefaultLayoutName=;FormatRegion=;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=;DefaultThemePartName=;');
#else
        Observer.Expect('misc', 'UseRequestPage=Yes;ProcessingOnly=Yes;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=RDLC;DefaultLayoutName=;FormatRegion=;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=absent;DefaultThemePartName=absent;');
#endif
        Observer.Expect('misc_items', '[Line filter_fields= view=]');
        Observer.Verify();
    end;

    // ---- Rec of a request page with SourceTable: Modify and Insert in OnOpenPage, Rec in the report triggers (RsRequestPageRec.al, al-runner issue 5756)

    [RequestPageHandler]
    procedure RsUnpositionedHandler(var RP: TestRequestPage "LT RS RP Modify Unpositioned")
    begin
        Seen.Put('handler', 'shown');
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('RsUnpositionedHandler')]
    procedure RS_RequestPageRec_ModifyUnpositioned_InOnOpenPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.RunModal(Report::"LT RS RP Modify Unpositioned", true, false);
        ObserveSeen(Observer, 'open_rec,modify_bool,handler');
        Observer.Observe('rows', Rows());
        Observer.Expect('open_rec', '[/0] filters=[] count=3 temporary=No table=LT Y Line');
        Observer.Expect('modify_bool', 'No');
        Observer.Expect('handler', 'shown');
        Observer.Expect('rows', 'A/10000/first;A/20000/second;B/10000/other;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure RsFoundHandler(var RP: TestRequestPage "LT RS RP Modify Found")
    begin
        Seen.Put('docno', RP.DocNoCtl.Value());
        Seen.Put('descr', RP.DescrCtl.Value());
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('RsFoundHandler')]
    procedure RS_RequestPageRec_ModifyAndInsert_InOnOpenPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.RunModal(Report::"LT RS RP Modify Found", true, false);
        ObserveSeen(Observer, 'modify,insert,open_rec,docno,descr');
        Observer.Observe('rows', Rows());
        Observer.Expect('modify', 'Yes');
        Observer.Expect('insert', 'Yes');
        Observer.Expect('open_rec', '[N/1/inserted] count=4');
        Observer.Expect('docno', 'N');
        Observer.Expect('descr', 'inserted');
        Observer.Expect('rows', 'A/10000/first;A/20000/second;B/10000/modified;N/1/inserted;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure RsInReportHandler(var RP: TestRequestPage "LT RS RP Rec In Report")
    begin
        Seen.Put('docno', RP.DocNoCtl.Value());
        Seen.Put('descr', RP.DescrCtl.Value());
        RP.DescrCtl.SetValue('typed');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('RsInReportHandler')]
    procedure RS_RequestPageRec_ReadInReportTriggers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.RunModal(Report::"LT RS RP Rec In Report", true, false);
        ObserveSeen(Observer, 'open_rec,docno,descr,pre_rec,dataitem_rec,post_rec,proc_rec');
        Observer.Observe('rows', Rows());
        Observer.Expect('open_rec', '[A/20000/second]');
        Observer.Expect('docno', 'A');
        Observer.Expect('descr', 'second');
        Observer.Expect('pre_rec', '[A/20000/typed] filters=[] count=3 temporary=No');
        Observer.Expect('dataitem_rec', '[A/20000/typed]');
        Observer.Expect('post_rec', '[A/20000/typed]');
        Observer.Expect('proc_rec', '[A/20000/typed]');
        Observer.Expect('rows', 'A/10000/first;A/20000/typed;B/10000/other;');
        Observer.Verify();
    end;

    [Test]
    procedure RS_RequestPageRec_ReadInReportTriggers_WithoutRequestPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.RunModal(Report::"LT RS RP Rec In Report", false, false);
        ObserveSeen(Observer, 'open_rec,pre_rec,dataitem_rec,post_rec,proc_rec');
        Observer.Observe('rows', Rows());
        Observer.Expect('open_rec', '<none>');
        Observer.Expect('pre_rec', '[/0/] filters=[] count=3 temporary=No');
        Observer.Expect('dataitem_rec', '[/0/]');
        Observer.Expect('post_rec', '[/0/]');
        Observer.Expect('proc_rec', '[/0/]');
        Observer.Expect('rows', 'A/10000/first;A/20000/second;B/10000/other;');
        Observer.Verify();
    end;

    [Test]
    procedure RS_RequestPageRec_NoHandler_FailsBeforeOnOpenPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        asserterror Report.RunModal(Report::"LT RS RP Modify Raises", true, false);
        Observer.Observe('error', GetLastErrorText() + '|' + GetLastErrorCode());
        ObserveSeen(Observer, 'before_modify,after_modify');
        Observer.Observe('rows', Rows());
        Observer.Expect('error', 'Unhandled UI: RequestPage 88563|MissingUIHandler');
        Observer.Expect('before_modify', '<none>');
        Observer.Expect('after_modify', '<none>');
        Observer.Expect('rows', 'A/10000/first;A/20000/second;B/10000/other;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure RsTempHandler(var RP: TestRequestPage "LT RS RP Temp Rec In Report")
    begin
        Seen.Put('docno', RP.DocNoCtl.Value());
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('RsTempHandler')]
    procedure RS_TemporaryRequestPageRec_ModifyInsertAndReportTrigger()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.RunModal(Report::"LT RS RP Temp Rec In Report", true, false);
        ObserveSeen(Observer, 'modify,insert,docno,pre_rec');
        Observer.Observe('rows', Rows());
        Observer.Expect('modify', 'error:The LT Y Line does not exist. Identification fields and values: DocNo='''',LineNo=''0''|DB:RecordNotFound');
        Observer.Expect('insert', 'Yes');
        Observer.Expect('docno', 'T');
        Observer.Expect('pre_rec', '[T/1] count=1 temporary=Yes');
        Observer.Expect('rows', 'A/10000/first;A/20000/second;B/10000/other;');
        Observer.Verify();
    end;

    [Test]
    procedure RS_RequestPageRec_ReadInOnInitReport_Raises()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        asserterror Report.RunModal(Report::"LT RS RP Rec In Init", false, false);
        Observer.Observe('error', GetLastErrorText() + '|' + GetLastErrorCode());
        ObserveSeen(Observer, 'init_before,init_rec,init_after');
        Observer.Expect('error', 'You cannot call the RequestPage from the OnInitReport Trigger in Report ID "88566" because the RequestPage is not yet initialized.|ReportRequestPageNotInitialized');
        Observer.Expect('init_before', 'reached');
        Observer.Expect('init_rec', '<none>');
        Observer.Expect('init_after', '<none>');
        Observer.Verify();
    end;
}
