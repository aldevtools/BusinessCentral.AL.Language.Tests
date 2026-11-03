// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-caption-method
// Scope: in-scope
// Fixtures used: the pages, reports and extensions in TestPageExtensionModifyCaption_Page.al, and
//   the dependency app's page 61020 / pageextension 61021 / report 61022 / reportextension 61023
//   (tests/al-language-internals-fixture/ALTModifyCaption.al).
//
// CLAIM: an extension's modify() of a control's Caption is what TestPage.<field>.Caption() and
// TestRequestPage.<field>.Caption() answer, and a modify() of its OptionCaption is what the
// control's SetValue/Value read, for
//   * a control of a page in this app, modified by a pageextension in this app;
//   * a control of a page in a dependency app, modified by a pageextension in this app;
//   * a control of a Base Application page, modified by a pageextension in this app;
//   * a control of a page in a dependency app, modified by a pageextension in that same app;
//   * a request-page control of a report in this app, modified by a reportextension in this app;
//   * a request-page control of a report in a dependency app, modified by a reportextension in
//     that same app;
// and when a dependency app's pageextension and this app's pageextension both modify one control's
// Caption, the caption the control answers is this app's (FxBothCtl); when two pageextensions of
// this app both modify it, the one with the higher object id is the one answered (TwiceCtl), whatever
// the declaration and name order (Twice2Ctl); and this app's value wins over its dependency's even
// when this app's extension has the lower object id (FxBoth2Ctl).
// An Option control's refusal of a value names the modified Caption.
//
// Written by agent stma-auto-6 (Claude agent), an automated implementation agent acting on the
// account holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4928.

codeunit 67670 "TP Ext Modify Caption"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        SeenCaption: Text;
        SeenOptionCaption: Text;
        SeenValue: Text;
        SeenError: Text;
        HandlerRan: Boolean;

    local procedure Initialize()
    begin
        SeenCaption := '';
        SeenOptionCaption := '';
        SeenValue := '';
        SeenError := '';
        HandlerRan := false;
    end;

    [Test]
    procedure SamePage_ModifiedCaption_OnRecordControl_WinsOverFieldCaption()
    var
        TP: TestPage "TP Modify Caption Host";
    begin
        TP.OpenEdit();
        Assert.AreEqual('Modified Ren', TP.RenCtl.Caption(),
            'a modify() Caption on a control bound to Rec.Klass answers that Caption, not the field Caption Severity');
        TP.Close();
    end;

    [Test]
    procedure SamePage_ModifiedCaption_ReplacesTheControlCaption()
    var
        TP: TestPage "TP Modify Caption Host";
    begin
        TP.OpenEdit();
        Assert.AreEqual('Modified Var', TP.VarCtl.Caption(),
            'a modify() Caption replaces the control''s own Caption Host Var');
        Assert.AreEqual('Host Plain', TP.PlainCtl.Caption(),
            'a control no extension modifies keeps its own Caption');
        TP.Close();
    end;

    [Test]
    procedure SamePage_ModifiedOptionCaption_IsWhatSetValueAndValueRead()
    var
        TP: TestPage "TP Modify Caption Host";
    begin
        TP.OpenEdit();
        Assert.AreEqual('Modified Option', TP.OptCtl.Caption(),
            'a modify() Caption on an Option control answers that Caption');
        TP.OptCtl.SetValue('Beta Mod');
        Assert.AreEqual('Beta Mod', TP.OptCtl.Value(),
            'an Option control reads back the OptionCaption its modify() states');
        asserterror TP.OptCtl.SetValue('Gamma Mod');
        Assert.IsTrue(StrPos(GetLastErrorText(), 'Your entry of ''Gamma Mod'' is not an acceptable value for ''Modified Option''.') > 0,
            'the refusal must name the modified Caption; got: ' + GetLastErrorText());
        TP.Close();
    end;

    [Test]
    procedure SamePage_TwoExtensionsOfOneApp_HigherIdCaptionWins()
    var
        TP: TestPage "TP Modify Caption Host";
    begin
        TP.OpenEdit();
        Assert.AreEqual('Second Ext Twice', TP.TwiceCtl.Caption(),
            'pageextensions 67670 and 67673 of one app both modify the Caption; the answer is 67673''s');
        TP.Close();
    end;

    [Test]
    procedure SamePage_TwoExtensionsOfOneApp_HigherIdWins_WhateverTheOrder()
    var
        TP: TestPage "TP Modify Caption Host";
    begin
        TP.OpenEdit();
        Assert.AreEqual('High Id Twice2', TP.Twice2Ctl.Caption(),
            'pageextension 67676, declared before 67675 and named before it, still answers over 67675');
        TP.Close();
    end;

    [Test]
    procedure BaseAppPage_ModifiedCaption_FromThisApp()
    var
        WRC: TestPage "Warehouse Reason Codes";
        PreviousAreas: Text;
        SeenDescriptionCaption: Text;
        SeenCodeCaption: Text;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Warehouse');
        WRC.OpenView();
        SeenDescriptionCaption := WRC.Description.Caption();
        SeenCodeCaption := WRC.Code.Caption();
        WRC.Close();
        ApplicationArea(PreviousAreas);

        Assert.AreEqual('WRC Modified Description', SeenDescriptionCaption,
            'this app''s modify() Caption on a Base Application page''s control replaces the field Caption Description');
        Assert.AreEqual('Code', SeenCodeCaption,
            'a control of that page no extension modifies keeps the field Caption');
    end;

    [Test]
    procedure DependencyPage_ModifiedCaption_FromThisApp()
    var
        TP: TestPage "ALT Modify Caption Page";
    begin
        TP.OpenEdit();
        Assert.AreEqual('Main Ext Text', TP.FxTextCtl.Caption(),
            'this app''s modify() Caption on a dependency page''s control replaces its Caption Fixture Text');
        TP.Close();
    end;

    [Test]
    procedure DependencyPage_ModifiedOptionCaption_FromThisApp()
    var
        TP: TestPage "ALT Modify Caption Page";
    begin
        TP.OpenEdit();
        Assert.AreEqual('Main Ext Option', TP.FxOptCtl.Caption(),
            'this app''s modify() Caption on a dependency page''s Option control answers that Caption');
        TP.FxOptCtl.SetValue('Green Mod');
        Assert.AreEqual('Green Mod', TP.FxOptCtl.Value(),
            'the dependency page''s Option control reads back the OptionCaption this app''s modify() states');
        TP.Close();
    end;

    [Test]
    procedure DependencyPage_ModifiedCaption_FromItsOwnApp()
    var
        TP: TestPage "ALT Modify Caption Page";
    begin
        TP.OpenEdit();
        Assert.AreEqual('Fixture Ext Own', TP.FxOwnCtl.Caption(),
            'the dependency app''s own pageextension modify() Caption replaces the control Caption Fixture Own');
        TP.Close();
    end;

    [Test]
    procedure DependencyPage_ModifiedByBothApps_ThisAppsCaptionWins()
    var
        TP: TestPage "ALT Modify Caption Page";
    begin
        TP.OpenEdit();
        Assert.AreEqual('Main Ext Both', TP.FxBothCtl.Caption(),
            'when the dependency app and this app both modify the Caption, the dependent (this) app''s value is applied');
        TP.Close();
    end;

    [Test]
    procedure DependencyPage_ModifiedByBothApps_ThisAppWins_EvenWithTheLowerId()
    var
        TP: TestPage "ALT Modify Caption Page";
    begin
        TP.OpenEdit();
        Assert.AreEqual('Main Low Ext Both2', TP.FxBoth2Ctl.Caption(),
            'this app''s pageextension 60941 answers over the dependency''s 61021 although its object id is lower');
        TP.Close();
    end;

    [Test]
    [HandlerFunctions('ReadSameAppRequestPageHandler')]
    procedure SameAppReport_ModifiedRequestPageCaptions()
    var
        Parameters: Text;
    begin
        Initialize();
        Parameters := Report.RunRequestPage(Report::"TP Modify Caption Report");

        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        Assert.AreEqual('Ext Request Text', SeenCaption,
            'a reportextension modify() Caption replaces the request-page control Caption Request Text');
        Assert.AreEqual('Ext Request Option', SeenOptionCaption,
            'a reportextension modify() Caption on an Option request-page control answers that Caption');
        Assert.AreEqual('Larger', SeenValue,
            'the Option request-page control reads back the OptionCaption the modify() states');
    end;

    [Test]
    [HandlerFunctions('ReadDependencyRequestPageHandler')]
    procedure DependencyReport_ModifiedRequestPageCaptions()
    var
        Parameters: Text;
    begin
        Initialize();
        Parameters := Report.RunRequestPage(Report::"ALT Modify Caption Report");

        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        Assert.AreEqual('Fixture Ext Request Text', SeenCaption,
            'the dependency app''s reportextension modify() Caption replaces the request-page control Caption');
        Assert.AreEqual('Fixture Ext Request Option', SeenOptionCaption,
            'the dependency app''s reportextension modify() Caption on an Option control answers that Caption');
        Assert.AreEqual('Higher', SeenValue,
            'the Option request-page control reads back the OptionCaption the modify() states');
        Assert.IsTrue(StrPos(SeenError, 'Your entry of ''Highest'' is not an acceptable value for ''Fixture Ext Request Option''.') > 0,
            'the refusal must name the modified Caption; got: ' + SeenError);
    end;

    [RequestPageHandler]
    procedure ReadSameAppRequestPageHandler(var RequestPage: TestRequestPage "TP Modify Caption Report")
    begin
        HandlerRan := true;
        SeenCaption := RequestPage.ReqTextCtl.Caption();
        SeenOptionCaption := RequestPage.ReqOptCtl.Caption();
        RequestPage.ReqOptCtl.SetValue('Larger');
        SeenValue := RequestPage.ReqOptCtl.Value();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure ReadDependencyRequestPageHandler(var RequestPage: TestRequestPage "ALT Modify Caption Report")
    begin
        HandlerRan := true;
        SeenCaption := RequestPage.FxReqTextCtl.Caption();
        SeenOptionCaption := RequestPage.FxReqOptCtl.Caption();
        RequestPage.FxReqOptCtl.SetValue('Higher');
        SeenValue := RequestPage.FxReqOptCtl.Value();
        asserterror RequestPage.FxReqOptCtl.SetValue('Highest');
        SeenError := GetLastErrorText();
        RequestPage.Cancel().Invoke();
    end;
}
