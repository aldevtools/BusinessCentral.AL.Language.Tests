// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: LT RptMrg Blob (70825), LT RptMrg Helper (70835), report 70883 of ReportMergerFixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// so that a compile problem of the static form drops only this file and the tests that use it (ReportMergerPayload.al, ReportMergerAction.al).
// Risky: static Report.SaveAs. Tests: the ReportAction per format of the static form (issue 176 item 3) and the payload of the static form against the Report variable form (item 1).
// BC versions: 29 (the final facts get added later)

codeunit 70846 "LT RptMrg Static"
{
    [TryFunction]
    procedure TrySaveAsStatic(Fmt: ReportFormat; var Output: Text; var Saved: Boolean)
    var
        Helper: Codeunit "LT RptMrg Helper";
        Tmp: Record "LT RptMrg Blob" temporary;
        OutS: OutStream;
    begin
        Output := '';
        Tmp.Init();
        Tmp.Id := 1;
        Tmp.Data.CreateOutStream(OutS);
        Saved := Report.SaveAs(Report::"LT RptMrg Report", '', Fmt, OutS);
        Tmp.Insert();
        Output := Helper.ReadAll(Tmp);
    end;
}

codeunit 70847 "LT RptMrg Static Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ObserveStatic(var Observer: Codeunit "Probe Observer"; Tag: Text; Fmt: ReportFormat)
    var
        Helper: Codeunit "LT RptMrg Helper";
        StaticSave: Codeunit "LT RptMrg Static";
        Cap: Codeunit "LT RptMrg Capture";
        Output: Text;
        Saved: Boolean;
    begin
        BindSubscription(Cap);
        if StaticSave.TrySaveAsStatic(Fmt, Output, Saved) then;
        UnbindSubscription(Cap);
        Observer.Observe(Tag + ' calls', Format(Cap.CallCount()));
        Observer.Observe(Tag + ' action', Cap.Item('action', 1));
        Observer.Observe(Tag + ' ordinal', Cap.Item('ordinal', 1));
    end;

    [Test]
    procedure SaveAs_StaticReport_AllFormats_ReportAction()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
    begin
        Helper.SeedRows(1);
        ObserveStatic(Observer, 'pdf', ReportFormat::Pdf);
        ObserveStatic(Observer, 'word', ReportFormat::Word);
        ObserveStatic(Observer, 'excel', ReportFormat::Excel);
        ObserveStatic(Observer, 'html', ReportFormat::Html);
        ObserveStatic(Observer, 'xml', ReportFormat::Xml);
        Observer.Expect('pdf calls', '1');
        Observer.Expect('pdf action', 'SaveAsPdf');
        Observer.Expect('pdf ordinal', '0');
        Observer.Expect('word calls', '1');
        Observer.Expect('word action', 'SaveAsWord');
        Observer.Expect('word ordinal', '1');
        Observer.Expect('excel calls', '1');
        Observer.Expect('excel action', 'SaveAsExcel');
        Observer.Expect('excel ordinal', '2');
        Observer.Expect('html calls', '1');
        Observer.Expect('html action', 'SaveAsHtml');
        Observer.Expect('html ordinal', '5');
        Observer.Expect('xml calls', '0');
        Observer.Expect('xml action', '<no call 1>');
        Observer.Expect('xml ordinal', '<no call 1>');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_StaticReportSaveAs_PayloadSameAsInstance()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        StaticSave: Codeunit "LT RptMrg Static";
        CapStatic: Codeunit "LT RptMrg Capture";
        CapInst: Codeunit "LT RptMrg Capture";
        Output: Text;
        Saved: Boolean;
    begin
        Helper.SeedRows(1);
        BindSubscription(CapStatic);
        if StaticSave.TrySaveAsStatic(ReportFormat::Pdf, Output, Saved) then;
        UnbindSubscription(CapStatic);
        BindSubscription(CapInst);
        if Helper.TrySaveAs(ReportFormat::Pdf, '', Output, Saved) then;
        UnbindSubscription(CapInst);
        Observer.Observe('static calls', Format(CapStatic.CallCount()));
        Observer.Observe('instance calls', Format(CapInst.CallCount()));
        Observer.Observe('payload equal', Format(CapStatic.Item('payload', 1) = CapInst.Item('payload', 1)));
        Observer.Observe('static keys', CapStatic.Item('payload keys', 1));
        Helper.ObserveLong(Observer, 'static payload', CapStatic.Item('payload', 1));
        Observer.Expect('static calls', '1');
        Observer.Expect('instance calls', '1');
        Observer.Expect('payload equal', 'Yes');
        Observer.Expect('static keys', 'filterviews,version,objectname,objectid,documenttype,invokedby,invokeddatetime,companyname,printername,duplex,color,defaultcopies,papertray,intent,layoutmodel,layoutname,layoutmimetype,layoutapplicationid,reportrunid');
        Observer.Expect('static payload length', '414');
        Observer.Expect('static payload part 1', 'filterviews=[] ; version=1 ; objectname="LT Merger Main" ; objectid=70883 ; documenttype="application/pdf" ; invokedby=<guid> ; invokeddatetime=<datetime> ; companyname=<masked> ; printername="" ; duplex=false ; color=false ; defaultcopies=1 ; papertray=null ; intent="Save" ; layoutmodel="Custom" ; layoutname="CustomA" ; layoutmimetype="application/x-lmc-layout" ; layoutapplicationid=<guid> ; reportrunid=<guid>');
        Observer.Verify();
    end;
}
