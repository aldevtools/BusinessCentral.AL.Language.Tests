// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-area
// Scope: in-scope
// Fixtures used: Assert (60021), and Base Application report 5803 "Reset Cost Is Adjusted", which
//                ships PRECOMPILED and which no other corpus test runs.
//
// CLAIM: application-area removal applies to the request-page controls of a report that ships
// precompiled, as it does to a report compiled here (codeunit 67533). The report states
// ApplicationArea = Basic,Suite. A [RequestPageHandler] reports a request-page control as not
// found when the session's areas do not enable:
//   * the control's own area ("Assembly Order No.", #Assembly);
//   * the REPORT's area, when the control states none ("From Date").
// Each negative arm pairs with a control on the same request page that IS found under the same
// areas; the handler reads it first, so a request page that never opened cannot pass.
//
// Every test sets the session's application areas itself and restores the previous value BEFORE
// it asserts, as codeunit 67530 does.
//
// Written by agent stma-auto2-1, an automated implementation agent acting on the account holder's
// behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4863.

codeunit 67544 "PAA Precompiled ReqPage Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        FoundControlRead: Boolean;

    [Test]
    [HandlerFunctions('ReadFromDateThenAssemblyNoHandler')]
    procedure OwnAreaNotEnabled_RequestPageControlIsNotFound()
    var
        PreviousAreas: Text;
        Parameters: Text;
    begin
        FoundControlRead := false;
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        asserterror Parameters := Report.RunRequestPage(Report::"Reset Cost Is Adjusted");
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
        Assert.IsTrue(FoundControlRead, 'the report-area control "From Date" must be found under #Basic,#Suite');
    end;

    [Test]
    [HandlerFunctions('ReadAssemblyNoThenFromDateHandler')]
    procedure ReportAreaNotEnabled_RequestPageControlIsNotFound()
    var
        PreviousAreas: Text;
        Parameters: Text;
    begin
        FoundControlRead := false;
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Assembly');

        asserterror Parameters := Report.RunRequestPage(Report::"Reset Cost Is Adjusted");
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
        Assert.IsTrue(FoundControlRead, 'the #Assembly control "Assembly Order No." must be found under #Assembly');
    end;

    [RequestPageHandler]
    procedure ReadFromDateThenAssemblyNoHandler(var RequestPage: TestRequestPage "Reset Cost Is Adjusted")
    var
        Shown: Text;
    begin
        Shown := RequestPage."From Date".Value();
        FoundControlRead := true;
        Shown := RequestPage."Assembly Order No.".Value();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure ReadAssemblyNoThenFromDateHandler(var RequestPage: TestRequestPage "Reset Cost Is Adjusted")
    var
        Shown: Text;
    begin
        Shown := RequestPage."Assembly Order No.".Value();
        FoundControlRead := true;
        Shown := RequestPage."From Date".Value();
        RequestPage.Cancel().Invoke();
    end;
}
