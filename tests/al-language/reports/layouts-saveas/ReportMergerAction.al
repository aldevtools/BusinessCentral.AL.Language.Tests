// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT RptMrg Helper (70835), LT RptMrg Capture (70831), report 70883 of ReportMergerFixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// through a Report variable and through the static Report.SaveAs(Id, RequestPageXml, Format, OutStream), and how many times the merger is called.
// Risky: Report.SaveAs; the whole file is one unit.
// BC versions: 29 (the final facts get added later)

codeunit 70838 "LT RptMrg Action"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ObserveInstance(var Observer: Codeunit "Probe Observer"; Tag: Text; Fmt: ReportFormat)
    var
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT RptMrg Capture";
        Output: Text;
        Saved: Boolean;
    begin
        BindSubscription(Cap);
        if Helper.TrySaveAs(Fmt, '', Output, Saved) then;
        UnbindSubscription(Cap);
        Observer.Observe(Tag + ' calls', Format(Cap.CallCount()));
        Observer.Observe(Tag + ' action', Cap.Item('action', 1));
        Observer.Observe(Tag + ' ordinal', Cap.Item('ordinal', 1));
    end;

    [Test]
    procedure SaveAs_ReportVariable_AllFormats_ReportAction()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
    begin
        Helper.SeedRows(1);
        ObserveInstance(Observer, 'pdf', ReportFormat::Pdf);
        ObserveInstance(Observer, 'word', ReportFormat::Word);
        ObserveInstance(Observer, 'excel', ReportFormat::Excel);
        ObserveInstance(Observer, 'html', ReportFormat::Html);
        ObserveInstance(Observer, 'xml', ReportFormat::Xml);
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
    procedure SaveAs_TwoSavesOneSubscription_CallsAndActions()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT RptMrg Capture";
        Output: Text;
        Saved: Boolean;
    begin
        Helper.SeedRows(1);
        BindSubscription(Cap);
        if Helper.TrySaveAs(ReportFormat::Word, '', Output, Saved) then;
        if Helper.TrySaveAs(ReportFormat::Excel, '', Output, Saved) then;
        if Helper.TrySaveAs(ReportFormat::Pdf, '', Output, Saved) then;
        UnbindSubscription(Cap);
        Observer.Observe('calls', Format(Cap.CallCount()));
        Observer.Observe('action 1', Cap.Item('action', 1));
        Observer.Observe('action 2', Cap.Item('action', 2));
        Observer.Observe('action 3', Cap.Item('action', 3));
        Observer.Observe('ordinal 1', Cap.Item('ordinal', 1));
        Observer.Observe('ordinal 2', Cap.Item('ordinal', 2));
        Observer.Observe('ordinal 3', Cap.Item('ordinal', 3));
        Observer.Expect('calls', '3');
        Observer.Expect('action 1', 'SaveAsWord');
        Observer.Expect('action 2', 'SaveAsExcel');
        Observer.Expect('action 3', 'SaveAsPdf');
        Observer.Expect('ordinal 1', '1');
        Observer.Expect('ordinal 2', '2');
        Observer.Expect('ordinal 3', '0');
        Observer.Verify();
    end;
}
