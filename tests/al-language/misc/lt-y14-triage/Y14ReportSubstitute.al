// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-runrequestpage-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained reports 91650-91651, codeunits 91652-91654
// Probe: observe probe (writer Y14, 2026-10-31, runtime asks from partner-app triage); every literal asserted below is what the BC service tier produced.
// Facts: two processing-only reports with a request page each, and a manually bound subscriber that sets NewReportId in SubstituteReport
//   (Reporting Triggers) or in OnAfterSubstituteReport (ReportManagement): which request page handler runs for Report.RunRequestPage, the returned
//   parameters XML, the run mode the subscriber sees, and which report runs for Report.Run, RunModal, Execute and SaveAs. A request page handler typed
//   on the report that was asked for (not the substituted one) is never called; a test that names such a handler and never consumes it fails with
//   'The following UI handlers were not executed', so those tests consume the handler with a second, unswapped call.
//   Related pins: events/lt-platform-events-v/PeVTests.al (SubstituteReport with SaveAs) and report/lt-report-members-testrequestpage/SqSubstituteObjects.al.
// BC versions: 27, 28, 29

report 91650 "LT Y14 Rep A"
{
    ProcessingOnly = true;
    UseRequestPage = true;

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(AField; AText) { ApplicationArea = All; }
            }
        }

        trigger OnOpenPage()
        begin
            Log.Add('A-rp-open');
        end;
    }

    var
        AText: Text[30];
        Log: Codeunit "LT Y14 Rep Log";

    trigger OnInitReport()
    begin
        Log.Add('A-init');
    end;

    trigger OnPreReport()
    begin
        Log.Add('A-pre(' + AText + ')');
    end;

    trigger OnPostReport()
    begin
        Log.Add('A-post');
    end;
}

report 91651 "LT Y14 Rep B"
{
    ProcessingOnly = true;
    UseRequestPage = true;

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(BField; BText) { ApplicationArea = All; }
            }
        }

        trigger OnOpenPage()
        begin
            Log.Add('B-rp-open');
        end;
    }

    var
        BText: Text[30];
        Log: Codeunit "LT Y14 Rep Log";

    trigger OnInitReport()
    begin
        Log.Add('B-init');
    end;

    trigger OnPreReport()
    begin
        Log.Add('B-pre(' + BText + ')');
    end;

    trigger OnPostReport()
    begin
        Log.Add('B-post');
    end;
}

codeunit 91652 "LT Y14 Rep Log"
{
    SingleInstance = true;

    var
        Text: Text;

    procedure Add(Entry: Text)
    begin
        Text += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Text;
        Text := '';
        exit(Result);
    end;
}

codeunit 91653 "LT Y14 Rep Subs"
{
    EventSubscriberInstance = Manual;

    var
        Log: Codeunit "LT Y14 Rep Log";
        Platform: Boolean;
        After: Boolean;

    procedure Bind(UsePlatform: Boolean; UseAfter: Boolean)
    begin
        Platform := UsePlatform;
        After := UseAfter;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SubstituteReport', '', false, false)]
    local procedure OnSubstitute(ReportId: Integer; RunMode: Option Normal,ParametersOnly,Execute,Print,SaveAs,RunModal; RequestPageXml: Text; RecordRef: RecordRef; var NewReportId: Integer)
    begin
        Log.Add('Sub(' + Format(ReportId) + ',' + Format(RunMode) + ',xmlLen=' + Format(StrLen(RequestPageXml)) + ',in=' + Format(NewReportId) + ')');
        if Platform and (ReportId = Report::"LT Y14 Rep A") then
            NewReportId := Report::"LT Y14 Rep B";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterSubstituteReport', '', false, false)]
    local procedure OnAfterSubstitute(ReportId: Integer; RunMode: Option; RequestPageXml: Text; RecordRef: RecordRef; var NewReportId: Integer)
    begin
        Log.Add('After(' + Format(ReportId) + ',' + Format(RunMode) + ',xmlLen=' + Format(StrLen(RequestPageXml)) + ',in=' + Format(NewReportId) + ')');
        if After and (ReportId = Report::"LT Y14 Rep A") then
            NewReportId := Report::"LT Y14 Rep B";
    end;
}

codeunit 91654 "LT Y14 Rep Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y14 Rep Log";

    [RequestPageHandler]
    procedure HandlerA(var Request: TestRequestPage "LT Y14 Rep A")
    begin
        Log.Add('handler-A');
        Request.AField.SetValue('a1');
        Request.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure HandlerB(var Request: TestRequestPage "LT Y14 Rep B")
    begin
        Log.Add('handler-B');
        Request.BField.SetValue('b1');
        Request.OK().Invoke();
    end;

    [TryFunction]
    local procedure TryRrp(var Parameters: Text; Old: Text; WithOld: Boolean)
    begin
        if WithOld then
            Parameters := Report.RunRequestPage(Report::"LT Y14 Rep A", Old)
        else
            Parameters := Report.RunRequestPage(Report::"LT Y14 Rep A");
    end;

    local procedure RrpCase(Observer: Codeunit "Probe Observer"; Name: Text; Bind: Boolean; Platform: Boolean; After: Boolean; WithOld: Boolean; Old: Text)
    var
        Subs: Codeunit "LT Y14 Rep Subs";
        Parameters: Text;
    begin
        ClearLastError();
        Log.Take();
        Commit();
        if Bind then begin
            Subs.Bind(Platform, After);
            BindSubscription(Subs);
        end;
        Observer.Observe(Name + ' ok', Format(TryRrp(Parameters, Old, WithOld)));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' xml', Parameters);
        Observer.Observe(Name + ' log', Log.Take());
        if Bind then
            UnbindSubscription(Subs);
    end;

    [Test]
    [HandlerFunctions('HandlerA')]
    procedure RunRequestPage_Swap_Platform_HandlerA()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RrpCase(Observer, 'platform handlerA', true, true, false, false, '');
        RrpCase(Observer, 'noswap consumes handlerA', false, false, false, false, '');
        Observer.Expect('platform handlerA ok', 'Yes');
        Observer.Expect('platform handlerA|text', '');
        Observer.Expect('platform handlerA|code', '');
        Observer.Expect('platform handlerA xml', '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT Y14 Rep B" id="91651" />');
        Observer.Expect('platform handlerA log', 'After(91650,1,xmlLen=0,in=-1);Sub(91650,ParametersOnly,xmlLen=0,in=-1);B-init;B-pre();B-post;');
        Observer.Expect('noswap consumes handlerA ok', 'Yes');
        Observer.Expect('noswap consumes handlerA|text', '');
        Observer.Expect('noswap consumes handlerA|code', '');
        Observer.Expect('noswap consumes handlerA xml', '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT Y14 Rep A" id="91650"><Options><Field name="AText">a1</Field></Options></ReportParameters>');
        Observer.Expect('noswap consumes handlerA log', 'A-init;A-rp-open;handler-A;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerB')]
    procedure RunRequestPage_Swap_Platform_HandlerB()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RrpCase(Observer, 'platform handlerB', true, true, false, false, '');
        Observer.Expect('platform handlerB ok', 'Yes');
        Observer.Expect('platform handlerB|text', '');
        Observer.Expect('platform handlerB|code', '');
        Observer.Expect('platform handlerB xml', '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT Y14 Rep B" id="91651"><Options><Field name="BText">b1</Field></Options></ReportParameters>');
        Observer.Expect('platform handlerB log', 'After(91650,1,xmlLen=0,in=-1);Sub(91650,ParametersOnly,xmlLen=0,in=-1);B-init;B-rp-open;handler-B;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerA')]
    procedure RunRequestPage_Swap_After_HandlerA()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RrpCase(Observer, 'after handlerA', true, false, true, false, '');
        RrpCase(Observer, 'noswap consumes handlerA', false, false, false, false, '');
        Observer.Expect('after handlerA ok', 'Yes');
        Observer.Expect('after handlerA|text', '');
        Observer.Expect('after handlerA|code', '');
        Observer.Expect('after handlerA xml', '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT Y14 Rep B" id="91651" />');
        Observer.Expect('after handlerA log', 'After(91650,1,xmlLen=0,in=-1);Sub(91650,ParametersOnly,xmlLen=0,in=91651);B-init;B-pre();B-post;');
        Observer.Expect('noswap consumes handlerA ok', 'Yes');
        Observer.Expect('noswap consumes handlerA|text', '');
        Observer.Expect('noswap consumes handlerA|code', '');
        Observer.Expect('noswap consumes handlerA xml', '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT Y14 Rep A" id="91650"><Options><Field name="AText">a1</Field></Options></ReportParameters>');
        Observer.Expect('noswap consumes handlerA log', 'A-init;A-rp-open;handler-A;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerB')]
    procedure RunRequestPage_Swap_After_HandlerB()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RrpCase(Observer, 'after handlerB', true, false, true, false, '');
        Observer.Expect('after handlerB ok', 'Yes');
        Observer.Expect('after handlerB|text', '');
        Observer.Expect('after handlerB|code', '');
        Observer.Expect('after handlerB xml', '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT Y14 Rep B" id="91651"><Options><Field name="BText">b1</Field></Options></ReportParameters>');
        Observer.Expect('after handlerB log', 'After(91650,1,xmlLen=0,in=-1);Sub(91650,ParametersOnly,xmlLen=0,in=91651);B-init;B-rp-open;handler-B;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerA')]
    procedure RunRequestPage_NoSwap_HandlerA()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RrpCase(Observer, 'noswap bound handlerA', true, false, false, false, '');
        RrpCase(Observer, 'noswap unbound handlerA', false, false, false, false, '');
        Observer.Expect('noswap bound handlerA ok', 'Yes');
        Observer.Expect('noswap bound handlerA|text', '');
        Observer.Expect('noswap bound handlerA|code', '');
        Observer.Expect('noswap bound handlerA xml', '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT Y14 Rep A" id="91650"><Options><Field name="AText">a1</Field></Options></ReportParameters>');
        Observer.Expect('noswap bound handlerA log', 'After(91650,1,xmlLen=0,in=-1);Sub(91650,ParametersOnly,xmlLen=0,in=-1);A-init;A-rp-open;handler-A;');
        Observer.Expect('noswap unbound handlerA ok', 'Yes');
        Observer.Expect('noswap unbound handlerA|text', '');
        Observer.Expect('noswap unbound handlerA|code', '');
        Observer.Expect('noswap unbound handlerA xml', '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT Y14 Rep A" id="91650"><Options><Field name="AText">a1</Field></Options></ReportParameters>');
        Observer.Expect('noswap unbound handlerA log', 'A-init;A-rp-open;handler-A;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryCall(Which: Text; Params: Text)
    var
        Rep: Report "LT Y14 Rep A";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        Dummy: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        case Which of
            'run':
                Report.Run(Report::"LT Y14 Rep A");
            'runmodal':
                Report.RunModal(Report::"LT Y14 Rep A");
            'run var':
                Rep.Run();
            'execute static':
                Report.Execute(Report::"LT Y14 Rep A", Params);
            'saveas static':
                Report.SaveAs(Report::"LT Y14 Rep A", Params, ReportFormat::Xml, OutStr);
            'rrp old':
                Dummy := Report.RunRequestPage(Report::"LT Y14 Rep A", Params);
        end;
    end;

    local procedure RunCase(Observer: Codeunit "Probe Observer"; Name: Text; Which: Text; Platform: Boolean; Params: Text)
    var
        Subs: Codeunit "LT Y14 Rep Subs";
    begin
        ClearLastError();
        Log.Take();
        Commit();
        Subs.Bind(Platform, false);
        BindSubscription(Subs);
        Observer.Observe(Name + ' ok', Format(TryCall(Which, Params)));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' log', Log.Take());
        UnbindSubscription(Subs);
    end;

    local procedure XmlA(): Text
    begin
        exit('<?xml version="1.0" standalone="yes"?><ReportParameters name="LT Y14 Rep A" id="91650"><Options><Field name="AText">a1</Field></Options></ReportParameters>');
    end;

    local procedure XmlB(): Text
    begin
        exit('<?xml version="1.0" standalone="yes"?><ReportParameters name="LT Y14 Rep B" id="91651"><Options><Field name="BText">b1</Field></Options></ReportParameters>');
    end;

    [Test]
    [HandlerFunctions('HandlerA')]
    procedure Run_Swap_HandlerA()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'run', 'run', true, '');
        RunCase(Observer, 'runmodal', 'runmodal', true, '');
        RunCase(Observer, 'run var', 'run var', true, '');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'After(91650,0,xmlLen=0,in=-1);Sub(91650,Normal,xmlLen=0,in=-1);B-init;B-pre();B-post;');
        Observer.Expect('runmodal ok', 'Yes');
        Observer.Expect('runmodal|text', '');
        Observer.Expect('runmodal|code', '');
        Observer.Expect('runmodal log', 'After(91650,5,xmlLen=0,in=-1);Sub(91650,RunModal,xmlLen=0,in=-1);B-init;B-pre();B-post;');
        Observer.Expect('run var ok', 'Yes');
        Observer.Expect('run var|text', '');
        Observer.Expect('run var|code', '');
        Observer.Expect('run var log', 'A-init;A-rp-open;handler-A;A-pre(a1);A-post;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerB')]
    procedure Run_Swap_HandlerB()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'run', 'run', true, '');
        RunCase(Observer, 'runmodal', 'runmodal', true, '');
        RunCase(Observer, 'run var', 'run var', true, '');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'After(91650,0,xmlLen=0,in=-1);Sub(91650,Normal,xmlLen=0,in=-1);B-init;B-rp-open;handler-B;B-pre(b1);B-post;');
        Observer.Expect('runmodal ok', 'Yes');
        Observer.Expect('runmodal|text', '');
        Observer.Expect('runmodal|code', '');
        Observer.Expect('runmodal log', 'After(91650,5,xmlLen=0,in=-1);Sub(91650,RunModal,xmlLen=0,in=-1);B-init;B-rp-open;handler-B;B-pre(b1);B-post;');
        Observer.Expect('run var ok', 'Yes');
        Observer.Expect('run var|text', '');
        Observer.Expect('run var|code', '');
        Observer.Expect('run var log', 'A-init;A-pre();A-post;');
        Observer.Verify();
    end;

    [Test]
    procedure Execute_SaveAs_Swap()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'execute xmlA', 'execute static', true, XmlA());
        RunCase(Observer, 'execute xmlB', 'execute static', true, XmlB());
        RunCase(Observer, 'execute noswap xmlA', 'execute static', false, XmlA());
        RunCase(Observer, 'saveas xmlA', 'saveas static', true, XmlA());
        RunCase(Observer, 'saveas xmlB', 'saveas static', true, XmlB());
        Observer.Expect('execute xmlA ok', 'Yes');
        Observer.Expect('execute xmlA|text', '');
        Observer.Expect('execute xmlA|code', '');
        Observer.Expect('execute xmlA log', 'After(91650,2,xmlLen=155,in=-1);Sub(91650,Execute,xmlLen=155,in=-1);B-init;B-rp-open;B-pre();B-post;');
        Observer.Expect('execute xmlB ok', 'Yes');
        Observer.Expect('execute xmlB|text', '');
        Observer.Expect('execute xmlB|code', '');
        Observer.Expect('execute xmlB log', 'After(91650,2,xmlLen=155,in=-1);Sub(91650,Execute,xmlLen=155,in=-1);B-init;B-rp-open;B-pre(b1);B-post;');
        Observer.Expect('execute noswap xmlA ok', 'Yes');
        Observer.Expect('execute noswap xmlA|text', '');
        Observer.Expect('execute noswap xmlA|code', '');
        Observer.Expect('execute noswap xmlA log', 'After(91650,2,xmlLen=155,in=-1);Sub(91650,Execute,xmlLen=155,in=-1);A-init;A-rp-open;A-pre(a1);A-post;');
        Observer.Expect('saveas xmlA ok', 'No');
        Observer.Expect('saveas xmlA|text', 'Report 91651 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('saveas xmlA|code', 'ReportProcessingOnly');
        Observer.Expect('saveas xmlA log', 'After(91650,4,xmlLen=155,in=-1);Sub(91650,SaveAs,xmlLen=155,in=-1);B-init;');
        Observer.Expect('saveas xmlB ok', 'No');
        Observer.Expect('saveas xmlB|text', 'Report 91651 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('saveas xmlB|code', 'ReportProcessingOnly');
        Observer.Expect('saveas xmlB log', 'After(91650,4,xmlLen=155,in=-1);Sub(91650,SaveAs,xmlLen=155,in=-1);B-init;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerA')]
    procedure RunRequestPage_Old_Swap_HandlerA()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'rrp old xmlA', 'rrp old', true, XmlA());
        RunCase(Observer, 'rrp old xmlB', 'rrp old', true, XmlB());
        RunCase(Observer, 'rrp old noswap xmlA', 'rrp old', false, XmlA());
        Observer.Expect('rrp old xmlA ok', 'Yes');
        Observer.Expect('rrp old xmlA|text', '');
        Observer.Expect('rrp old xmlA|code', '');
        Observer.Expect('rrp old xmlA log', 'After(91650,1,xmlLen=0,in=-1);Sub(91650,ParametersOnly,xmlLen=0,in=-1);B-init;B-pre();B-post;');
        Observer.Expect('rrp old xmlB ok', 'Yes');
        Observer.Expect('rrp old xmlB|text', '');
        Observer.Expect('rrp old xmlB|code', '');
        Observer.Expect('rrp old xmlB log', 'After(91650,1,xmlLen=0,in=-1);Sub(91650,ParametersOnly,xmlLen=0,in=-1);B-init;B-pre(b1);B-post;');
        Observer.Expect('rrp old noswap xmlA ok', 'Yes');
        Observer.Expect('rrp old noswap xmlA|text', '');
        Observer.Expect('rrp old noswap xmlA|code', '');
        Observer.Expect('rrp old noswap xmlA log', 'After(91650,1,xmlLen=0,in=-1);Sub(91650,ParametersOnly,xmlLen=0,in=-1);A-init;A-rp-open;handler-A;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerB')]
    procedure RunRequestPage_Old_Swap_HandlerB()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'rrp old xmlA', 'rrp old', true, XmlA());
        RunCase(Observer, 'rrp old xmlB', 'rrp old', true, XmlB());
        Observer.Expect('rrp old xmlA ok', 'Yes');
        Observer.Expect('rrp old xmlA|text', '');
        Observer.Expect('rrp old xmlA|code', '');
        Observer.Expect('rrp old xmlA log', 'After(91650,1,xmlLen=0,in=-1);Sub(91650,ParametersOnly,xmlLen=0,in=-1);B-init;B-rp-open;handler-B;');
        Observer.Expect('rrp old xmlB ok', 'Yes');
        Observer.Expect('rrp old xmlB|text', '');
        Observer.Expect('rrp old xmlB|code', '');
        Observer.Expect('rrp old xmlB log', 'After(91650,1,xmlLen=0,in=-1);Sub(91650,ParametersOnly,xmlLen=0,in=-1);B-init;B-rp-open;handler-B;');
        Observer.Verify();
    end;
}
