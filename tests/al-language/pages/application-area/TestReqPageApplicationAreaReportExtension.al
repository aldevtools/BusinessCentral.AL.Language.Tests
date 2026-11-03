// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-area
// Scope: in-scope
// Fixtures used: Assert (60021), the table, report and reportextension declared below, and Base
//                Application report 5803 "Reset Cost Is Adjusted" with its precompiled
//                reportextension 99000783 "Mfg. Reset Cost Is Adjusted". Codeunit 67544 also runs
//                report 5803; these tests only read its request page.
//
// CLAIM: application-area removal applies to the request-page controls a reportextension adds,
// and to a reportextension's modify() of a request-page control's ApplicationArea. A
// [RequestPageHandler] reports such a control as not found when the session's areas do not
// enable its area, where that area is:
//   * the added control's own (#Service here; #Manufacturing on report 5803's extension);
//   * nothing at all, when the added control states none -- it does not take the report's
//     ApplicationArea (Basic), which only the report's own request-page controls inherit;
//   * the modify()'s value, which REPLACES the base control's area.
// Each negative arm first reads a control on the same request page that IS found under the same
// areas, so a request page that never opened cannot pass as "not found".
//
// A handler can also WRITE an extension field and read it back when the report runs through a
// Report variable rather than Report.RunRequestPage(id) (ReportVariable_ExtField_RoundTrips) --
// the extension is bound to the report however it is constructed. A handler's SetValue on an
// extension field runs that field's OnValidate (ExtField_SetValue_RunsItsOnValidate).
//
// Every test sets the session's application areas itself and restores the previous value BEFORE
// it asserts, as codeunit 67530 does.
//
// Written by agent stma-auto2-1, an automated implementation agent acting on the account holder's
// behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4896.

table 67546 "PAA RExt Record"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

report 67546 "PAA RExt Report"
{
    ApplicationArea = Basic;
    UsageCategory = ReportsAndAnalysis;
    ProcessingOnly = true;

    dataset
    {
        dataitem(RExtItem; "PAA RExt Record") { }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(BaseInheritCtl; BaseInheritValue) { }
                    field(BaseServiceCtl; BaseServiceValue) { ApplicationArea = Service; }
                }
            }
        }
    }

    var
        BaseInheritValue: Text[30];
        BaseServiceValue: Text[30];
}

reportextension 67546 "PAA RExt Report Ext" extends "PAA RExt Report"
{
    requestpage
    {
        layout
        {
            addlast(Options)
            {
                field(ExtServiceCtl; ExtServiceValue) { ApplicationArea = Service; }
                field(ExtNoAreaCtl; ExtNoAreaValue) { }
                field(ExtValidatedCtl; ExtValidatedValue)
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        ExtDerivedValue := 'D-' + ExtValidatedValue;
                    end;
                }
                field(ExtDerivedCtl; ExtDerivedValue) { ApplicationArea = All; }
            }
            modify(BaseServiceCtl)
            {
                ApplicationArea = Suite;
            }
        }
    }

    var
        ExtServiceValue: Text[30];
        ExtNoAreaValue: Text[30];
        ExtValidatedValue: Text[30];
        ExtDerivedValue: Text[30];
}

codeunit 67546 "PAA RExt ReqPage Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        FoundControlRead: Boolean;
        SeenValue: Text;

    local procedure RunUnder(Areas: Text)
    var
        PreviousAreas: Text;
        Parameters: Text;
    begin
        FoundControlRead := false;
        PreviousAreas := ApplicationArea();
        ApplicationArea(Areas);
        asserterror Parameters := Report.RunRequestPage(Report::"PAA RExt Report");
        ApplicationArea(PreviousAreas);
    end;

    [Test]
    [HandlerFunctions('InheritThenExtServiceHandler')]
    procedure ExtOwnArea_NotEnabled_IsNotFound()
    begin
        RunUnder('#Basic,#Suite');
        Assert.ExpectedError('is not found on the page.');
        Assert.IsTrue(FoundControlRead, 'the report-area control must be found under #Basic,#Suite');
    end;

    [Test]
    [HandlerFunctions('InheritThenExtNoAreaHandler')]
    procedure ExtNoArea_DoesNotInheritReportArea_IsNotFound()
    begin
        RunUnder('#Basic');
        Assert.ExpectedError('is not found on the page.');
        Assert.IsTrue(FoundControlRead, 'the report-area control must be found under #Basic');
    end;

    [Test]
    [HandlerFunctions('InheritThenBaseServiceHandler')]
    procedure ModifiedArea_BaseValueNoLongerApplies_IsNotFound()
    begin
        RunUnder('#Basic,#Service');
        Assert.ExpectedError('is not found on the page.');
        Assert.IsTrue(FoundControlRead, 'the report-area control must be found under #Basic,#Service');
    end;

    [Test]
    [HandlerFunctions('ReadBaseServiceHandler')]
    procedure ModifiedArea_ModifyValueEnabled_IsFound()
    var
        PreviousAreas: Text;
        Parameters: Text;
    begin
        FoundControlRead := false;
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');
        Parameters := Report.RunRequestPage(Report::"PAA RExt Report");
        ApplicationArea(PreviousAreas);
        Assert.IsTrue(FoundControlRead, 'the control the modify() moved to #Suite must be found under #Basic,#Suite');
    end;

    [Test]
    [HandlerFunctions('ReadExtServiceHandler')]
    procedure ExtOwnArea_Enabled_IsFound()
    var
        PreviousAreas: Text;
        Parameters: Text;
    begin
        FoundControlRead := false;
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Service');
        Parameters := Report.RunRequestPage(Report::"PAA RExt Report");
        ApplicationArea(PreviousAreas);
        Assert.IsTrue(FoundControlRead, 'the extension''s #Service control must be found with #Service enabled');
    end;

    [Test]
    [HandlerFunctions('SetExtServiceHandler')]
    procedure ReportVariable_ExtField_RoundTrips()
    var
        RExtReport: Report "PAA RExt Report";
        PreviousAreas: Text;
        Parameters: Text;
    begin
        SeenValue := '';
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Service');
        Parameters := RExtReport.RunRequestPage();
        ApplicationArea(PreviousAreas);
        Assert.AreEqual('EXT-SET', SeenValue, 'the handler must read back the value it set on the extension''s field');
    end;

    [Test]
    [HandlerFunctions('ValidateExtFieldHandler')]
    procedure ExtField_SetValue_RunsItsOnValidate()
    var
        PreviousAreas: Text;
        Parameters: Text;
    begin
        SeenValue := '';
        PreviousAreas := ApplicationArea();
        ApplicationArea('');
        Parameters := Report.RunRequestPage(Report::"PAA RExt Report");
        ApplicationArea(PreviousAreas);
        Assert.AreEqual('D-X', SeenValue, 'SetValue on the extension field must run its OnValidate, which derives the second field');
    end;

    [RequestPageHandler]
    procedure ValidateExtFieldHandler(var RequestPage: TestRequestPage "PAA RExt Report")
    begin
        RequestPage.ExtValidatedCtl.SetValue('X');
        SeenValue := RequestPage.ExtDerivedCtl.Value();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure SetExtServiceHandler(var RequestPage: TestRequestPage "PAA RExt Report")
    begin
        RequestPage.ExtServiceCtl.SetValue('EXT-SET');
        SeenValue := RequestPage.ExtServiceCtl.Value();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure InheritThenExtServiceHandler(var RequestPage: TestRequestPage "PAA RExt Report")
    var
        Shown: Text;
    begin
        Shown := RequestPage.BaseInheritCtl.Value();
        FoundControlRead := true;
        Shown := RequestPage.ExtServiceCtl.Value();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure InheritThenExtNoAreaHandler(var RequestPage: TestRequestPage "PAA RExt Report")
    var
        Shown: Text;
    begin
        Shown := RequestPage.BaseInheritCtl.Value();
        FoundControlRead := true;
        Shown := RequestPage.ExtNoAreaCtl.Value();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure InheritThenBaseServiceHandler(var RequestPage: TestRequestPage "PAA RExt Report")
    var
        Shown: Text;
    begin
        Shown := RequestPage.BaseInheritCtl.Value();
        FoundControlRead := true;
        Shown := RequestPage.BaseServiceCtl.Value();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure ReadBaseServiceHandler(var RequestPage: TestRequestPage "PAA RExt Report")
    var
        Shown: Text;
    begin
        Shown := RequestPage.BaseServiceCtl.Value();
        FoundControlRead := true;
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure ReadExtServiceHandler(var RequestPage: TestRequestPage "PAA RExt Report")
    var
        Shown: Text;
    begin
        Shown := RequestPage.ExtServiceCtl.Value();
        FoundControlRead := true;
        RequestPage.Cancel().Invoke();
    end;
}

codeunit 67547 "PAA Precompiled RExt Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        FoundControlRead: Boolean;

    [Test]
    [HandlerFunctions('FromDateThenProdOrderHandler')]
    procedure PrecompiledExtOwnArea_NotEnabled_IsNotFound()
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
    [HandlerFunctions('ReadProdOrderHandler')]
    procedure PrecompiledExtOwnArea_Enabled_IsFound()
    var
        PreviousAreas: Text;
        Parameters: Text;
    begin
        FoundControlRead := false;
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Manufacturing');
        Parameters := Report.RunRequestPage(Report::"Reset Cost Is Adjusted");
        ApplicationArea(PreviousAreas);
        Assert.IsTrue(FoundControlRead, 'the extension''s #Manufacturing control "Prod. Order No." must be found with #Manufacturing enabled');
    end;

    [RequestPageHandler]
    procedure FromDateThenProdOrderHandler(var RequestPage: TestRequestPage "Reset Cost Is Adjusted")
    var
        Shown: Text;
    begin
        Shown := RequestPage."From Date".Value();
        FoundControlRead := true;
        Shown := RequestPage."Prod. Order No.".Value();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure ReadProdOrderHandler(var RequestPage: TestRequestPage "Reset Cost Is Adjusted")
    var
        Shown: Text;
    begin
        Shown := RequestPage."Prod. Order No.".Value();
        FoundControlRead := true;
        RequestPage.Cancel().Invoke();
    end;
}
