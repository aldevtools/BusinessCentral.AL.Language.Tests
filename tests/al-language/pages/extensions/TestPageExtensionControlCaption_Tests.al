// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-caption-method
// Scope: in-scope
// Fixtures used: TP Ext Caption Host (67660) with pageextension 67660 (see
//   TestPageExtensionControlCaption_Page.al); Base Application report 5803 "Reset Cost Is Adjusted"
//   with its precompiled reportextension 99000783 "Mfg. Reset Cost Is Adjusted".
//
// TestPage.<field>.Caption() on a control an EXTENSION adds, and the caption BC names when such a
// control refuses a value -- the same answers codeunit 67640 pins for controls the page itself
// declares:
//   * a source-compiled pageextension's controls (page 67660);
//   * report 5803's request-page controls that reportextension 99000783 adds:
//     "Reset Prod. Order Costing" (variable ResetProdOrderCosting, Caption 'Adjust Production
//     Orders') and "Prod. Order No." (variable ProdOrderNo, Caption 'No.'). Both state
//     ApplicationArea = Manufacturing, so those tests enable #Manufacturing and restore the
//     previous areas before asserting, as codeunit 67546 does.
//
// Written by agent stma-auto-6 (Claude agent), an automated implementation agent acting on the
// account holder's behalf, for AL Runner issues StefanMaron/BusinessCentral.AL.Runner#4913 and #4921.

codeunit 67660 "TP Ext Control Caption"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        SeenCaption: Text;
        SeenSecondCaption: Text;
        SeenError: Text;
        HandlerRan: Boolean;

    local procedure Initialize()
    begin
        SeenCaption := '';
        SeenSecondCaption := '';
        SeenError := '';
        HandlerRan := false;
    end;

    [Test]
    procedure ExtRecordFieldControl_DeclaredCaption_WinsOverFieldCaption()
    var
        TP: TestPage "TP Ext Caption Host";
    begin
        TP.OpenEdit();
        Assert.AreEqual('Ext Declared Severity', TP.ExtDeclaredRecCtl.Caption(),
            'an extension control bound to Rec.Klass declaring Caption answers that Caption, not the field Caption Severity');
        TP.Close();
    end;

    [Test]
    procedure ExtRecordFieldControl_NoCaption_IsTheFieldCaption()
    var
        TP: TestPage "TP Ext Caption Host";
    begin
        TP.OpenEdit();
        Assert.AreEqual('Severity', TP.ExtUndeclaredRecCtl.Caption(),
            'an extension control bound to Rec.Klass declaring no Caption answers the field Caption, not the control name');
        TP.Close();
    end;

    [Test]
    procedure ExtPageVariableControl_DeclaredCaption_IsTheCaption()
    var
        TP: TestPage "TP Ext Caption Host";
    begin
        TP.OpenEdit();
        Assert.AreEqual('Ext Declared Var Caption', TP.ExtDeclaredVarCtl.Caption(),
            'an extension page-variable control declaring Caption answers that Caption, not its variable or control name');
        Assert.AreEqual('Ext; Semi Caption', TP.ExtSemiCtl.Caption(),
            'a declared Caption containing a semicolon answers whole');
        Assert.AreEqual('Ext Grouped Caption', TP.ExtGroupedCtl.Caption(),
            'a control inside a group the extension adds answers its own Caption');
        TP.Close();
    end;

    [Test]
    procedure ExtPageVariableControl_NoCaption_IsTheControlName()
    var
        TP: TestPage "TP Ext Caption Host";
    begin
        TP.OpenEdit();
        Assert.AreEqual('ExtUndeclaredVarCtl', TP.ExtUndeclaredVarCtl.Caption(),
            'an extension page-variable control declaring no Caption answers its control name, not the variable name ExtUndeclaredVar');
        TP.Close();
    end;

    [Test]
    procedure ExtPageVariableBooleanControl_Refusal_NamesTheCaption()
    var
        TP: TestPage "TP Ext Caption Host";
    begin
        TP.OpenEdit();
        asserterror TP.ExtFlagCtl.SetValue('Maybe');
        Assert.IsTrue(StrPos(GetLastErrorText(), 'Your entry of ''Maybe'' is not an acceptable value for ''Ext Flag''.') > 0,
            'the refusal must name the control Caption; got: ' + GetLastErrorText());
        TP.Close();
    end;

    [Test]
    procedure ExtPageVariableOptionControl_SetValueByOptionCaption()
    var
        TP: TestPage "TP Ext Caption Host";
    begin
        TP.OpenEdit();
        Assert.AreEqual('Ext Option Caption', TP.ExtOptCtl.Caption(),
            'an extension Option control declaring Caption answers that Caption');
        TP.ExtOptCtl.SetValue('Beta Cap');
        Assert.AreEqual('Beta Cap', TP.ExtOptCtl.Value(),
            'an extension Option control reads back its declared OptionCaption');
        asserterror TP.ExtOptCtl.SetValue('Gamma Cap');
        Assert.IsTrue(StrPos(GetLastErrorText(), 'Your entry of ''Gamma Cap'' is not an acceptable value for ''Ext Option Caption''.') > 0,
            'the refusal must name the control Caption; got: ' + GetLastErrorText());
        TP.Close();
    end;

    [Test]
    [HandlerFunctions('ReadExtCaptionsHandler')]
    procedure PrecompiledReportExtension_RequestPageControl_IsTheCaption()
    var
        PreviousAreas: Text;
        Parameters: Text;
    begin
        Initialize();
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Manufacturing');
        Parameters := Report.RunRequestPage(Report::"Reset Cost Is Adjusted");
        ApplicationArea(PreviousAreas);

        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        Assert.AreEqual('Adjust Production Orders', SeenCaption,
            'reportextension 99000783 declares Caption = ''Adjust Production Orders'' on the control "Reset Prod. Order Costing"');
        Assert.AreEqual('No.', SeenSecondCaption,
            'reportextension 99000783 declares Caption = ''No.'' on the control "Prod. Order No."');
    end;

    [Test]
    [HandlerFunctions('InvalidExtFlagHandler')]
    procedure PrecompiledReportExtension_BooleanRefusal_NamesTheCaption()
    var
        PreviousAreas: Text;
        Parameters: Text;
    begin
        Initialize();
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Manufacturing');
        Parameters := Report.RunRequestPage(Report::"Reset Cost Is Adjusted");
        ApplicationArea(PreviousAreas);

        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        Assert.IsTrue(StrPos(SeenError, 'Your entry of ''Maybe'' is not an acceptable value for ''Adjust Production Orders''.') > 0,
            'the refusal must name the control Caption ''Adjust Production Orders''; got: ' + SeenError);
    end;

    [RequestPageHandler]
    procedure ReadExtCaptionsHandler(var RequestPage: TestRequestPage "Reset Cost Is Adjusted")
    begin
        HandlerRan := true;
        SeenCaption := RequestPage."Reset Prod. Order Costing".Caption();
        SeenSecondCaption := RequestPage."Prod. Order No.".Caption();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure InvalidExtFlagHandler(var RequestPage: TestRequestPage "Reset Cost Is Adjusted")
    begin
        HandlerRan := true;
        asserterror RequestPage."Reset Prod. Order Costing".SetValue('Maybe');
        SeenError := GetLastErrorText();
        RequestPage.Cancel().Invoke();
    end;
}
