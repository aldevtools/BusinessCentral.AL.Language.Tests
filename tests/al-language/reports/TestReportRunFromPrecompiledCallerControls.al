// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-test-requestpage
// Scope: in-scope
// Fixtures used: none — Base Application page "Cost Accounting Setup" and report
//                "Update Cost Acctg. Dimensions"
//
// When Base Application code runs a report, the request page the [RequestPageHandler] receives
// still exposes its controls, bound to the report's globals.
//
// TestReportRequestPageControl.al pins request-page controls for a report the test runs itself.
// TestReportRunFromPrecompiledCaller.al pins that a report run from Base Application code hands
// the handler its request page at all, but that report's request page has no controls. This file
// joins the two: the "Cost Accounting Setup" page's action UpdateCostAcctgDimensions runs
// `REPORT.RunModal(REPORT::"Update Cost Acctg. Dimensions")` from Base Application code, and
// that report's request page has two controls, CostCenterDimension and CostObjectDimension,
// bound to the report globals NewCCDimension and NewCODimension. Its OnOpenPage copies them from
// the Cost Accounting Setup record.
//
// Every handler cancels, so the report body never runs and nothing is written.
//
// Three claims:
//   1. read   -> a control shows the value the request page's OnOpenPage put in the report
//               global, taken from the setup record the test wrote.
//   2. write  -> SetValue with a different, valid dimension is what the control then shows.
//   3. reject -> SetValue with the value of the OTHER control runs the control's OnValidate,
//               which compares the two report globals and raises its own error.
codeunit 60042 "Rpt Precompiled Caller Ctrls"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        // A [RequestPageHandler] runs in a read-only context, so what it sees is kept here and
        // asserted by the test after the action returns.
        HandlerCalls: Integer;
        ObservedCostCenter: Text;
        ObservedCostObject: Text;
        ObservedError: Text;
        CostCenterDimTxt: Label 'RPCC-CC', Locked = true;
        CostObjectDimTxt: Label 'RPCC-CO', Locked = true;
        OtherDimTxt: Label 'RPCC-OTHER', Locked = true;
        DimensionsSameErr: Label 'The dimension values for cost center and cost object cannot be same.', Locked = true;

    local procedure Initialize()
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        HandlerCalls := 0;
        ObservedCostCenter := '';
        ObservedCostObject := '';
        ObservedError := '';
        EnsureDimension(CostCenterDimTxt);
        EnsureDimension(CostObjectDimTxt);
        EnsureDimension(OtherDimTxt);
        if not CostAccountingSetup.Get() then begin
            CostAccountingSetup.Init();
            CostAccountingSetup.Insert();
        end;
        CostAccountingSetup."Cost Center Dimension" := CostCenterDimTxt;
        CostAccountingSetup."Cost Object Dimension" := CostObjectDimTxt;
        CostAccountingSetup.Modify();
        // REPORT.RunModal refuses to start inside a write transaction.
        Commit();
    end;

    local procedure EnsureDimension(DimensionCode: Code[20])
    var
        Dimension: Record Dimension;
    begin
        if Dimension.Get(DimensionCode) then
            exit;
        Dimension.Init();
        Dimension.Code := DimensionCode;
        Dimension.Name := DimensionCode;
        Dimension.Insert();
    end;

    local procedure RunUpdateCostAcctgDimensions()
    var
        CostAccountingSetup: TestPage "Cost Accounting Setup";
    begin
        CostAccountingSetup.OpenEdit();
        CostAccountingSetup.UpdateCostAcctgDimensions.Invoke();
        CostAccountingSetup.Close();
    end;

    [Test]
    [HandlerFunctions('ReadControls')]
    procedure RequestPageFromBaseAppAction_ControlsShowTheGlobalsOnOpenPageSet()
    begin
        Initialize();

        RunUpdateCostAcctgDimensions();

        Assert.AreEqual(1, HandlerCalls, 'the [RequestPageHandler] runs once');
        Assert.AreEqual(CostCenterDimTxt, ObservedCostCenter, 'CostCenterDimension shows NewCCDimension');
        Assert.AreEqual(CostObjectDimTxt, ObservedCostObject, 'CostObjectDimension shows NewCODimension');
    end;

    [Test]
    [HandlerFunctions('SetOtherCostCenter')]
    procedure RequestPageFromBaseAppAction_SetValueIsWhatTheControlShows()
    begin
        Initialize();

        RunUpdateCostAcctgDimensions();

        Assert.AreEqual(1, HandlerCalls, 'the [RequestPageHandler] runs once');
        Assert.AreEqual(OtherDimTxt, ObservedCostCenter, 'CostCenterDimension shows the value the handler set');
        Assert.AreEqual(CostObjectDimTxt, ObservedCostObject, 'CostObjectDimension is unchanged');
    end;

    [Test]
    [HandlerFunctions('SetCostCenterToCostObject')]
    procedure RequestPageFromBaseAppAction_SetValueRunsOnValidateAgainstTheOtherGlobal()
    begin
        Initialize();

        RunUpdateCostAcctgDimensions();

        Assert.AreEqual(1, HandlerCalls, 'the [RequestPageHandler] runs once');
        Assert.IsTrue(StrPos(ObservedError, DimensionsSameErr) > 0,
            'OnValidate compares NewCCDimension with NewCODimension and refuses, got: ' + ObservedError);
    end;

    [RequestPageHandler]
    procedure ReadControls(var RequestPage: TestRequestPage "Update Cost Acctg. Dimensions")
    begin
        HandlerCalls += 1;
        ObservedCostCenter := RequestPage.CostCenterDimension.Value();
        ObservedCostObject := RequestPage.CostObjectDimension.Value();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure SetOtherCostCenter(var RequestPage: TestRequestPage "Update Cost Acctg. Dimensions")
    begin
        HandlerCalls += 1;
        RequestPage.CostCenterDimension.SetValue(OtherDimTxt);
        ObservedCostCenter := RequestPage.CostCenterDimension.Value();
        ObservedCostObject := RequestPage.CostObjectDimension.Value();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure SetCostCenterToCostObject(var RequestPage: TestRequestPage "Update Cost Acctg. Dimensions")
    begin
        HandlerCalls += 1;
        asserterror RequestPage.CostCenterDimension.SetValue(CostObjectDimTxt);
        ObservedError := GetLastErrorText();
        RequestPage.Cancel().Invoke();
    end;
}
