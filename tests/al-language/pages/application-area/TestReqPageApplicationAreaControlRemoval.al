// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-area
// Scope: in-scope
// Fixtures used: Assert (60021), and the report and codeunit declared below.
//
// CLAIM: a REQUEST-PAGE control whose ApplicationArea is not enabled for the session is removed
// from the request page, so a [RequestPageHandler] reports it as not found, while a control
// whose area IS enabled stays reachable. An empty application-area string enables every area.
//
// Every test sets the session's application areas itself and restores the previous value
// BEFORE it asserts, so the result does not depend on which areas the harness opened the
// session with.
//
// Written by agent stma-auto2-1, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4829.

report 67533 "PAA ReqPage Area Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(BasicOpt; BasicText)
                    {
                        ApplicationArea = Basic;
                    }
                    field(ServiceOpt; ServiceText)
                    {
                        ApplicationArea = Service;
                    }
                }
            }
        }
    }

    var
        BasicText: Text[30];
        ServiceText: Text[30];
}

codeunit 67533 "PAA ReqPage Area Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        // A [RequestPageHandler] and the [Test] that declares it share one codeunit instance for
        // the duration of a test, so these carry what the handler saw back to the test.
        HandlerReachedControl: Boolean;
        ObservedValue: Text;

    [Test]
    [HandlerFunctions('TouchServiceHandler')]
    procedure AreaNotEnabled_RequestPageControlIsNotFound()
    var
        PreviousAreas: Text;
        Parameters: Text;
    begin
        HandlerReachedControl := false;
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        asserterror Parameters := Report.RunRequestPage(Report::"PAA ReqPage Area Report");
        ApplicationArea(PreviousAreas);

        Assert.IsTrue(HandlerReachedControl, 'the [RequestPageHandler] never reached the #Service control');
        Assert.ExpectedError('is not found on the page.');
    end;

    [Test]
    [HandlerFunctions('WriteBasicHandler')]
    procedure AreaNotEnabled_EnabledRequestPageControlIsFound()
    var
        PreviousAreas: Text;
        Parameters: Text;
    begin
        ObservedValue := '';
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        Parameters := Report.RunRequestPage(Report::"PAA ReqPage Area Report");
        ApplicationArea(PreviousAreas);

        Assert.AreEqual('B1', ObservedValue, 'the #Basic request-page control must read back the value just set');
    end;

    [Test]
    [HandlerFunctions('WriteServiceHandler')]
    procedure AreaEnabled_ServiceRequestPageControlIsFound()
    var
        PreviousAreas: Text;
        Parameters: Text;
    begin
        ObservedValue := '';
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Service');

        Parameters := Report.RunRequestPage(Report::"PAA ReqPage Area Report");
        ApplicationArea(PreviousAreas);

        Assert.AreEqual('S1', ObservedValue, 'with #Service enabled the #Service request-page control must be found');
    end;

    [Test]
    [HandlerFunctions('WriteServiceHandler')]
    procedure EmptyAreaString_ServiceRequestPageControlIsFound()
    var
        PreviousAreas: Text;
        Parameters: Text;
    begin
        ObservedValue := '';
        PreviousAreas := ApplicationArea();
        ApplicationArea('');

        Parameters := Report.RunRequestPage(Report::"PAA ReqPage Area Report");
        ApplicationArea(PreviousAreas);

        Assert.AreEqual('S1', ObservedValue, 'with every area enabled the #Service request-page control must be found');
    end;

    [RequestPageHandler]
    procedure TouchServiceHandler(var RequestPage: TestRequestPage "PAA ReqPage Area Report")
    begin
        HandlerReachedControl := true;
        RequestPage.ServiceOpt.SetValue('S0');
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure WriteBasicHandler(var RequestPage: TestRequestPage "PAA ReqPage Area Report")
    begin
        RequestPage.BasicOpt.SetValue('B1');
        ObservedValue := RequestPage.BasicOpt.Value();
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure WriteServiceHandler(var RequestPage: TestRequestPage "PAA ReqPage Area Report")
    begin
        RequestPage.ServiceOpt.SetValue('S1');
        ObservedValue := RequestPage.ServiceOpt.Value();
        RequestPage.OK().Invoke();
    end;
}
