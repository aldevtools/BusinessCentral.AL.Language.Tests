// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-defaultrenderinglayout-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT RptMrg Helper (70835), LT RptMrg Capture (70831), reports 70883 and 70884, layout files ReportMergerLayoutA/B.rlblayout
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// application/x-lmc-layout) and CustomB; report 70884 declares CustomB first, then CustomA, and no DefaultRenderingLayout. Observed: the LayoutData text and byte info, the mime type
// and layout name keys of the ObjectPayload, per Pdf and Word. Choosing a layout by name through Report.SaveAs is not testable: SaveAs has no layout-name argument, and the
// selection API is a Base Application table.
// BC versions: 29 (the final facts get added later)

codeunit 70845 "LT RptMrg Layout"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ObserveMain(var Observer: Codeunit "Probe Observer"; Fmt: ReportFormat)
    var
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT RptMrg Capture";
    begin
        Helper.SeedRows(1);
        Helper.ProbeSave(Observer, Fmt, '', Cap);
        Observer.Observe('layout data', Cap.Item('layout', 1));
        Observer.Observe('layout info', Cap.Item('layout info', 1));
        Helper.ObserveLong(Observer, 'payload', Cap.Item('payload', 1));
    end;

    [Test]
    procedure SaveAs_Pdf_DefaultRenderingLayout_ChoosesCustomA()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveMain(Observer, ReportFormat::Pdf);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDEREDLMC-OUT');
        Observer.Expect('calls', '1');
        Observer.Expect('layout data', '');
        Observer.Expect('layout info', 'cr=0 lf=0 first=');
        Observer.Expect('payload length', '414');
        Observer.Expect('payload part 1', 'filterviews=[] ; version=1 ; objectname="LT Merger Main" ; objectid=70883 ; documenttype="application/pdf" ; invokedby=<guid> ; invokeddatetime=<datetime> ; companyname=<masked> ; printername="" ; duplex=false ; color=false ; defaultcopies=1 ; papertray=null ; intent="Save" ; layoutmodel="Custom" ; layoutname="CustomA" ; layoutmimetype="application/x-lmc-layout" ; layoutapplicationid=<guid> ; reportrunid=<guid>');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_Word_DefaultRenderingLayout_ChoosesCustomA()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveMain(Observer, ReportFormat::Word);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDEREDLMC-OUT');
        Observer.Expect('calls', '1');
        Observer.Expect('layout data', '');
        Observer.Expect('layout info', 'cr=0 lf=0 first=');
        Observer.Expect('payload length', '470');
        Observer.Expect('payload part 1', 'filterviews=[] ; version=1 ; objectname="LT Merger Main" ; objectid=70883 ; documenttype="application/vnd.openxmlformats-officedocument.wordprocessingml.document" ; invokedby=<guid> ; invokeddatetime=<datetime> ; companyname=<masked> ; printername="" ; duplex=false ; color=false ; defaultcopies=1 ; papertray=null ; intent="Save" ; layoutmodel="Custom" ; layoutname="CustomA" ; layoutmimetype="application/x-lmc-layout" ; layoutapplicationid=<guid> ; reportrunid=<guid>');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_NoDefaultRenderingLayout_TwoCustomLayouts_Choice()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT RptMrg Capture";
        Output: Text;
        Saved: Boolean;
        Completed: Boolean;
    begin
        Helper.SeedRows(1);
        ClearLastError();
        BindSubscription(Cap);
        Completed := Helper.TrySaveAsNoDefault(ReportFormat::Pdf, Output, Saved);
        UnbindSubscription(Cap);
        Observer.Observe('try completed', Format(Completed));
        Observer.Observe('saved', Format(Saved));
        Observer.Observe('error', CopyStr(GetLastErrorText(), 1, 200));
        Observer.Observe('calls', Format(Cap.CallCount()));
        Observer.Observe('layout data', Cap.Item('layout', 1));
        Observer.Observe('layout info', Cap.Item('layout info', 1));
        Helper.ObserveLong(Observer, 'payload', Cap.Item('payload', 1));
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('calls', '1');
        Observer.Expect('layout data', '');
        Observer.Expect('layout info', 'cr=0 lf=0 first=');
        Observer.Expect('payload length', '422');
        Observer.Expect('payload part 1', 'filterviews=[] ; version=1 ; objectname="LT Merger No Default" ; objectid=70884 ; documenttype="application/pdf" ; invokedby=<guid> ; invokeddatetime=<datetime> ; companyname=<masked> ; printername="" ; duplex=false ; color=false ; defaultcopies=1 ; papertray=null ; intent="Save" ; layoutmodel="Custom" ; layoutname="CustomB" ; layoutmimetype="application/x-lmc-layout-b" ; layoutapplicationid=<guid> ; reportrunid=<guid>');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_LayoutData_SameForRepeatedSaves()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT RptMrg Capture";
        Output: Text;
        Saved: Boolean;
    begin
        Helper.SeedRows(1);
        BindSubscription(Cap);
        if Helper.TrySaveAs(ReportFormat::Pdf, '', Output, Saved) then;
        if Helper.TrySaveAs(ReportFormat::Pdf, '', Output, Saved) then;
        UnbindSubscription(Cap);
        Observer.Observe('calls', Format(Cap.CallCount()));
        Observer.Observe('layout 1', Cap.Item('layout', 1));
        Observer.Observe('layout 2', Cap.Item('layout', 2));
        Observer.Observe('layout info 2', Cap.Item('layout info', 2));
        Observer.Observe('payload equal', Format(Cap.Item('payload', 1) = Cap.Item('payload', 2)));
        Observer.Expect('calls', '2');
        Observer.Expect('layout 1', '');
        Observer.Expect('layout 2', '');
        Observer.Expect('layout info 2', 'cr=0 lf=0 first=');
        Observer.Expect('payload equal', 'Yes');
        Observer.Verify();
    end;
}
