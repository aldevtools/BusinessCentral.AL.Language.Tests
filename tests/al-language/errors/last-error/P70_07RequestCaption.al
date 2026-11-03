// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/requestpage/requestpage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own report 72076 with request page
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: RequestOptionsPage.Caption set from report triggers, observed in a RequestPageHandler
// BC versions: 29 (27 and 28 by CI)

report 72076 "LT P70 Caption Rep"
{
    ProcessingOnly = true;
    Caption = 'P70 Static Report Caption';

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(Opt; OptValue) { ApplicationArea = All; }
                }
            }
        }

        trigger OnOpenPage()
        begin
            if SetCaptionOnOpen then
                RequestOptionsPage.Caption := 'P70 Dynamic Caption';
        end;
    }

    var
        OptValue: Text;
        SetCaptionOnOpen: Boolean;
        SetCaptionOnInit: Boolean;

    procedure SetModes(OnOpen: Boolean; OnInit: Boolean)
    begin
        SetCaptionOnOpen := OnOpen;
        SetCaptionOnInit := OnInit;
    end;

    trigger OnInitReport()
    begin
        if SetCaptionOnInit then
            RequestOptionsPage.Caption := 'P70 Init Caption';
    end;
}

codeunit 72078 "LT P70 RequestPage Caption"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mode: Integer;

    [RequestPageHandler]
    procedure CaptionHandler(var Req: TestRequestPage "LT P70 Caption Rep")
    begin
        Observer.Observe('caption', Req.Caption());
        Observer.Observe('opt_visible', Format(Req.Opt.Visible()));
        Req.Cancel().Invoke();
    end;

    [Test]
    procedure Caption_StaticReportCaption()
    var
        Rep: Report "LT P70 Caption Rep";
    begin
        Rep.SetModes(false, false);
        asserterror Rep.Run();
        Observer.ObserveError('af74');
        Observer.Expect('af74|text', 'Unhandled UI: RequestPage 72076');
        Observer.Expect('af74|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    [Test]
    procedure Caption_SetOnOpenPage()
    var
        Rep: Report "LT P70 Caption Rep";
    begin
        Rep.SetModes(true, false);
        asserterror Rep.Run();
        Observer.ObserveError('af85');
        Observer.Expect('af85|text', 'Unhandled UI: RequestPage 72076');
        Observer.Expect('af85|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    [Test]
    procedure Caption_SetOnInitReport()
    var
        Rep: Report "LT P70 Caption Rep";
    begin
        Rep.SetModes(false, true);
        asserterror Rep.Run();
        Observer.ObserveError('af96');
        Observer.Expect('af96|text', 'Unhandled UI: RequestPage 72076');
        Observer.Expect('af96|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    [Test]
    procedure Caption_ReportRunStatic()
    begin
        asserterror Report.Run(Report::"LT P70 Caption Rep");
        Observer.ObserveError('af104');
        Observer.Expect('af104|text', 'Unhandled UI: RequestPage 72076');
        Observer.Expect('af104|code', 'MissingUIHandler');
        Observer.Verify();
    end;
}
