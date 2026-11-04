// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-assertequals-method
// Scope: in-scope
// Fixtures used: Assert (60021), the report and reportextensions declared below, Base Application
//   report 91 "Export Consolidation" and report 5803 "Reset Cost Is Adjusted" with its precompiled
//   reportextension 99000783 "Mfg. Reset Cost Is Adjusted".
//
// CLAIM: a failed AssertEquals or SetValue on a TestRequestPage control names the control -- the AL
// identifier in field(<Name>; ...) -- and not the report global it shows. "AssertEquals for Field:
// <control> Expected = '<expected>', Actual = '<actual>'", and "Validation error for Field:
// <control>,  Message = 'Your entry of ...'". A matching value raises nothing. The four ways a
// request-page control reaches a handler answer alike:
//   * a request page this app compiles (report 68660; control RpnTextCtl shows the variable
//     RpnText) and a reportextension of it;
//   * a PRECOMPILED report's own control (report 91's ClientFileNameControl shows the variable
//     ClientFileName), where the control and the variable are spelled differently;
//   * a control a reportextension compiled in THIS app adds to a precompiled report;
//   * a control a PRECOMPILED reportextension adds (report 5803's "Reset Prod. Order Costing"
//     shows ResetProdOrderCosting). Its ApplicationArea is Manufacturing, so those tests enable
//     #Manufacturing and restore the previous areas before asserting, as codeunit 67660 does.
//
// Measured on every required cloud leg (27.0 to 28.5) and by the Windows nightly (BC 28.4) before
// these assertions were written (probe: corpus PR #552, AlRunner#4919).
//
// Written by agent stma-auto-8 (Claude agent), an automated implementation agent acting on the
// account holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4919.

report 68660 "RPN Report"
{
    Caption = 'RPN Report';
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(RpnTextCtl; RpnText)
                {
                    ApplicationArea = All;
                    Caption = 'Rpn Text Caption';
                }
                field(RpnFlagCtl; RpnFlag)
                {
                    ApplicationArea = All;
                    Caption = 'Rpn Flag Caption';
                }
            }
        }
    }

    trigger OnInitReport()
    begin
        RpnText := 'Delta';
        RpnFlag := false;
    end;

    var
        RpnText: Text[30];
        RpnFlag: Boolean;
}

reportextension 68660 "RPN Report Ext" extends "RPN Report"
{
    requestpage
    {
        layout
        {
            addlast(Content)
            {
                field(RpnExtCtl; RpnExtVar)
                {
                    ApplicationArea = All;
                    Caption = 'Rpn Ext Caption';
                }
            }
        }
    }

    var
        RpnExtVar: Text[30];
}

reportextension 68661 "RPN Export Ext" extends "Export Consolidation"
{
    requestpage
    {
        layout
        {
            addlast(Content)
            {
                field(RpnExportExtCtl; RpnExportExtVar)
                {
                    ApplicationArea = All;
                    Caption = 'Rpn Export Ext Caption';
                }
            }
        }
    }

    var
        RpnExportExtVar: Text[30];
}

codeunit 68660 "RPN Request Page Control Name"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        SeenError: Text;
        SeenValue: Text;
        HandlerRan: Boolean;
        CaseNo: Integer;

    local procedure Reset(No: Integer)
    begin
        CaseNo := No;
        SeenError := '';
        SeenValue := '';
        HandlerRan := false;
    end;

    local procedure RunSource(No: Integer)
    begin
        Reset(No);
        Report.Run(Report::"RPN Report");
        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
    end;

    local procedure RunExport(No: Integer)
    begin
        Reset(No);
        Report.Run(Report::"Export Consolidation");
        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
    end;

    local procedure RunExt5803(No: Integer)
    var
        PreviousAreas: Text;
        Parameters: Text;
    begin
        Reset(No);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Manufacturing');
        Parameters := Report.RunRequestPage(Report::"Reset Cost Is Adjusted");
        ApplicationArea(PreviousAreas);
        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
    end;

    [Test]
    [HandlerFunctions('SourceHandler')]
    procedure SourceReport_AssertEquals_Mismatch_NamesTheControl()
    begin
        RunSource(1);
        Assert.AreEqual('AssertEquals for Field: RpnTextCtl Expected = ''Wrong'', Actual = ''Delta''', SeenError,
            'a mismatch on a request-page control of a report this app compiles names the control, not the variable RpnText');
    end;

    [Test]
    [HandlerFunctions('SourceHandler')]
    procedure SourceReport_AssertEquals_Match_RaisesNothing()
    begin
        RunSource(2);
        Assert.AreEqual('', SeenError, 'a matching AssertEquals must raise nothing');
        Assert.AreEqual('Delta', SeenValue, 'the control reads the value OnInitReport gave the variable');
    end;

    [Test]
    [HandlerFunctions('SourceHandler')]
    procedure SourceReport_BooleanControl_AssertEquals_Mismatch_NamesTheControl()
    begin
        RunSource(3);
        Assert.AreEqual('AssertEquals for Field: RpnFlagCtl Expected = ''Yes'', Actual = ''No''', SeenError,
            'a Boolean control names the control, not the variable RpnFlag');
    end;

    [Test]
    [HandlerFunctions('SourceHandler')]
    procedure SourceReport_BooleanControl_SetValue_Refusal_NamesTheControlAndTheCaption()
    begin
        RunSource(4);
        Assert.AreEqual(
            'Validation error for Field: RpnFlagCtl,  Message = ''Your entry of ''Maybe'' is not an acceptable value for ''Rpn Flag Caption''.''',
            SeenError, 'the prefix names the control; the message names the control Caption');
    end;

    [Test]
    [HandlerFunctions('SourceHandler')]
    procedure SourceReportExtension_Control_AssertEquals_Mismatch_NamesTheControl()
    begin
        RunSource(5);
        Assert.AreEqual('AssertEquals for Field: RpnExtCtl Expected = ''Wrong'', Actual = ''''', SeenError,
            'a control a reportextension of this app adds to a report of this app names the control');
    end;

    [Test]
    [HandlerFunctions('SourceHandler')]
    procedure SourceReportExtension_Control_AssertEquals_Match_RaisesNothing()
    begin
        RunSource(6);
        Assert.AreEqual('', SeenError, 'a matching AssertEquals must raise nothing');
        Assert.AreEqual('Eps', SeenValue, 'the control reads back what SetValue wrote');
    end;

    [Test]
    [HandlerFunctions('ExportHandler')]
    procedure PrecompiledReport_AssertEquals_Mismatch_NamesTheControl()
    begin
        RunExport(11);
        Assert.AreEqual('AssertEquals for Field: ClientFileNameControl Expected = ''Wrong'', Actual = ''''', SeenError,
            'report 91 shows the variable ClientFileName on the control ClientFileNameControl; the error names the control');
    end;

    [Test]
    [HandlerFunctions('ExportHandler')]
    procedure PrecompiledReport_OptionControl_AssertEquals_Mismatch_NamesTheControl()
    begin
        RunExport(12);
        Assert.AreEqual(
            'AssertEquals for Field: FileFormat Expected = ''Wrong'', Actual = ''Version 4.00 or Later (.xml)''', SeenError,
            'report 91''s FileFormat control and its variable are spelled alike, so the control name is the same either way');
    end;

    [Test]
    [HandlerFunctions('ExportHandler')]
    procedure PrecompiledReport_OptionControl_SetValue_Refusal_NamesTheControlAndTheCaption()
    begin
        RunExport(13);
        Assert.AreEqual(
            'Validation error for Field: FileFormat,  Message = ''Your entry of ''Not A Format'' is not an acceptable value for ''File Format''.''',
            SeenError, 'the prefix names the control; the message names the control Caption');
    end;

    [Test]
    [HandlerFunctions('ExportHandler')]
    procedure PrecompiledReport_AssertEquals_Match_RaisesNothing()
    begin
        RunExport(14);
        Assert.AreEqual('', SeenError, 'a matching AssertEquals must raise nothing');
        Assert.AreEqual('Version 4.00 or Later (.xml)', SeenValue, 'report 91 defaults FileFormat to its first option');
    end;

    [Test]
    [HandlerFunctions('ExportHandler')]
    procedure SourceReportExtensionOfPrecompiledReport_Control_AssertEquals_Mismatch_NamesTheControl()
    begin
        RunExport(15);
        Assert.AreEqual('AssertEquals for Field: RpnExportExtCtl Expected = ''Wrong'', Actual = ''''', SeenError,
            'a control a reportextension of this app adds to report 91 names the control');
    end;

    [Test]
    [HandlerFunctions('ExportHandler')]
    procedure SourceReportExtensionOfPrecompiledReport_Control_AssertEquals_Match_RaisesNothing()
    begin
        RunExport(16);
        Assert.AreEqual('', SeenError, 'a matching AssertEquals must raise nothing');
        Assert.AreEqual('Zeta', SeenValue, 'the control reads back what SetValue wrote');
    end;

    [Test]
    [HandlerFunctions('Ext5803Handler')]
    procedure PrecompiledReportExtension_BooleanControl_AssertEquals_Mismatch_NamesTheControl()
    begin
        RunExt5803(21);
        Assert.AreEqual('AssertEquals for Field: Reset Prod. Order Costing Expected = ''Wrong'', Actual = ''No''', SeenError,
            'a control a precompiled reportextension adds names the control "Reset Prod. Order Costing", not the variable ResetProdOrderCosting');
    end;

    [Test]
    [HandlerFunctions('Ext5803Handler')]
    procedure PrecompiledReportExtension_TextControl_AssertEquals_Mismatch_NamesTheControl()
    begin
        RunExt5803(22);
        Assert.AreEqual('AssertEquals for Field: Prod. Order No. Expected = ''Wrong'', Actual = ''''', SeenError,
            'a control a precompiled reportextension adds names the control "Prod. Order No.", not the variable ProdOrderNo');
    end;

    [Test]
    [HandlerFunctions('Ext5803Handler')]
    procedure PrecompiledReportExtension_BooleanControl_SetValue_Refusal_NamesTheControlAndTheCaption()
    begin
        RunExt5803(23);
        Assert.AreEqual(
            'Validation error for Field: Reset Prod. Order Costing,  Message = ''Your entry of ''Maybe'' is not an acceptable value for ''Adjust Production Orders''.''',
            SeenError, 'the prefix names the control; the message names the control Caption');
    end;

    [Test]
    [HandlerFunctions('Ext5803Handler')]
    procedure PrecompiledReportExtension_AssertEquals_Match_RaisesNothing()
    begin
        RunExt5803(24);
        Assert.AreEqual('', SeenError, 'a matching AssertEquals must raise nothing');
    end;

    [RequestPageHandler]
    procedure SourceHandler(var RequestPage: TestRequestPage "RPN Report")
    begin
        HandlerRan := true;
        case CaseNo of
            1:
                begin
                    asserterror RequestPage.RpnTextCtl.AssertEquals('Wrong');
                    SeenError := GetLastErrorText();
                end;
            2:
                begin
                    RequestPage.RpnTextCtl.AssertEquals('Delta');
                    SeenValue := RequestPage.RpnTextCtl.Value();
                end;
            3:
                begin
                    asserterror RequestPage.RpnFlagCtl.AssertEquals('Yes');
                    SeenError := GetLastErrorText();
                end;
            4:
                begin
                    asserterror RequestPage.RpnFlagCtl.SetValue('Maybe');
                    SeenError := GetLastErrorText();
                end;
            5:
                begin
                    asserterror RequestPage.RpnExtCtl.AssertEquals('Wrong');
                    SeenError := GetLastErrorText();
                end;
            6:
                begin
                    RequestPage.RpnExtCtl.SetValue('Eps');
                    RequestPage.RpnExtCtl.AssertEquals('Eps');
                    SeenValue := RequestPage.RpnExtCtl.Value();
                end;
        end;
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure ExportHandler(var RequestPage: TestRequestPage "Export Consolidation")
    begin
        HandlerRan := true;
        case CaseNo of
            11:
                begin
                    asserterror RequestPage.ClientFileNameControl.AssertEquals('Wrong');
                    SeenError := GetLastErrorText();
                end;
            12:
                begin
                    asserterror RequestPage.FileFormat.AssertEquals('Wrong');
                    SeenError := GetLastErrorText();
                end;
            13:
                begin
                    asserterror RequestPage.FileFormat.SetValue('Not A Format');
                    SeenError := GetLastErrorText();
                end;
            14:
                begin
                    RequestPage.ClientFileNameControl.AssertEquals('');
                    RequestPage.FileFormat.AssertEquals('Version 4.00 or Later (.xml)');
                    SeenValue := RequestPage.FileFormat.Value();
                end;
            15:
                begin
                    asserterror RequestPage.RpnExportExtCtl.AssertEquals('Wrong');
                    SeenError := GetLastErrorText();
                end;
            16:
                begin
                    RequestPage.RpnExportExtCtl.SetValue('Zeta');
                    RequestPage.RpnExportExtCtl.AssertEquals('Zeta');
                    SeenValue := RequestPage.RpnExportExtCtl.Value();
                end;
        end;
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure Ext5803Handler(var RequestPage: TestRequestPage "Reset Cost Is Adjusted")
    begin
        HandlerRan := true;
        case CaseNo of
            21:
                begin
                    asserterror RequestPage."Reset Prod. Order Costing".AssertEquals('Wrong');
                    SeenError := GetLastErrorText();
                end;
            22:
                begin
                    asserterror RequestPage."Prod. Order No.".AssertEquals('Wrong');
                    SeenError := GetLastErrorText();
                end;
            23:
                begin
                    asserterror RequestPage."Reset Prod. Order Costing".SetValue('Maybe');
                    SeenError := GetLastErrorText();
                end;
            24:
                begin
                    RequestPage."Reset Prod. Order Costing".AssertEquals('No');
                    RequestPage."Prod. Order No.".AssertEquals('');
                end;
        end;
        RequestPage.Cancel().Invoke();
    end;
}
