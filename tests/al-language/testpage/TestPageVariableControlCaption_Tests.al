// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-caption-method
// Scope: in-scope
// Fixtures used: TP Var Control Caption (67640), TP Rec Control Caption (67641); Base Application report 91 "Export Consolidation",
//   page 6520 "Item Tracing", page 3731 "Product Video Topics" and page 16 "Chart of Accounts"
//
// TestPage.<field>.Caption() on a control bound to a page VARIABLE, not to a source-table
// field, and the caption BC names when such a control refuses a value. Each control's caption
// differs from its bound variable's name, and from its control name wherever it declares one, so
// an answer taken from the wrong one of the three cannot pass.
//   * source pages 67640 and 67641 (see TestPageVariableControlCaption_Page.al);
//   * report 91's request-page control FileFormat (variable FileFormat, Caption 'File Format')
//     and ClientFileNameControl (variable ClientFileName, Caption 'File Name');
//   * page 6520's TraceMethod (variable TraceMethod, Caption 'Trace Method');
//   * page 3731's Name (variable TopicName, no Caption);
//   * and, for contrast, page 16's Rec-bound "Default Deferral Template Code", whose control
//     Caption 'Default Deferral Template' differs from its field's.

codeunit 67640 "TP Var Control Caption"
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
    procedure PageVariableControl_DeclaredCaption_IsTheCaption()
    var
        TP: TestPage "TP Var Control Caption";
    begin
        TP.OpenEdit();
        Assert.AreEqual('Declared Var Caption', TP.DeclaredCtl.Caption(),
            'a page-variable control declaring Caption must answer that Caption, not its variable or control name');
        TP.Close();
    end;

    [Test]
    procedure PageVariableControl_NoCaption_IsTheControlName()
    var
        TP: TestPage "TP Var Control Caption";
    begin
        TP.OpenEdit();
        Assert.AreEqual('UndeclaredCtl', TP.UndeclaredCtl.Caption(),
            'a page-variable control declaring no Caption answers its control name, not the variable name UndeclaredVar');
        TP.Close();
    end;

    [Test]
    procedure PageVariableOptionControl_DeclaredCaption_IsTheCaption()
    var
        TP: TestPage "TP Var Control Caption";
    begin
        TP.OpenEdit();
        Assert.AreEqual('My Option Caption', TP.OptCtl.Caption(),
            'an Option page-variable control declaring Caption must answer that Caption');
        TP.Close();
    end;

    [Test]
    procedure RecordFieldControl_NoCaption_IsTheFieldCaption()
    var
        TP: TestPage "TP Rec Control Caption";
    begin
        TP.OpenEdit();
        Assert.AreEqual('Severity', TP.RenamedKlass.Caption(),
            'a control bound to Rec.Klass declaring no Caption answers the field Caption, not the control name');
        Assert.AreEqual('PK', TP.RenamedPK.Caption(),
            'a control bound to Rec.PK, where neither declares a Caption, answers the field name, not the control name');
        TP.Close();
    end;

    [Test]
    procedure PageVariableBooleanControl_Refusal_NamesTheCaption()
    var
        TP: TestPage "TP Var Control Caption";
    begin
        TP.OpenEdit();
        asserterror TP.FlagCtl.SetValue('Maybe');
        Assert.IsTrue(StrPos(GetLastErrorText(), 'Your entry of ''Maybe'' is not an acceptable value for ''Declared Flag''.') > 0,
            'the refusal must name the control Caption; got: ' + GetLastErrorText());
        TP.Close();
    end;

    [Test]
    procedure PageVariableOptionControl_Refusal_NamesTheCaption()
    var
        TP: TestPage "TP Var Control Caption";
    begin
        TP.OpenEdit();
        asserterror TP.OptCtl.SetValue('Gamma Cap');
        Assert.IsTrue(StrPos(GetLastErrorText(), 'Your entry of ''Gamma Cap'' is not an acceptable value for ''My Option Caption''.') > 0,
            'the refusal must name the control Caption; got: ' + GetLastErrorText());
        TP.Close();
    end;

    [Test]
    procedure PrecompiledPage_PageVariableControl_IsTheCaption()
    var
        ItemTracing: TestPage "Item Tracing";
    begin
        ItemTracing.OpenEdit();
        Assert.AreEqual('Trace Method', ItemTracing.TraceMethod.Caption(),
            'page 6520 declares Caption = ''Trace Method'' on control TraceMethod');
        ItemTracing.Close();
    end;

    [Test]
    procedure PrecompiledPage_PageVariableControl_NoCaption_IsTheControlName()
    var
        ProductVideoTopics: TestPage "Product Video Topics";
    begin
        ProductVideoTopics.OpenView();
        Assert.AreEqual('Name', ProductVideoTopics.Name.Caption(),
            'page 3731 declares field(Name; TopicName) with no Caption; the control name answers, not the variable name TopicName');
        ProductVideoTopics.Close();
    end;

    [Test]
    procedure PrecompiledPage_RecordFieldControl_DeclaredCaption_WinsOverFieldCaption()
    var
        ChartOfAccounts: TestPage "Chart of Accounts";
    begin
        ChartOfAccounts.OpenView();
        Assert.AreEqual('Default Deferral Template', ChartOfAccounts."Default Deferral Template Code".Caption(),
            'page 16 declares Caption = ''Default Deferral Template'' on the control bound to Rec."Default Deferral Template Code", whose field Caption is ''Default Deferral Template Code''');
        ChartOfAccounts.Close();
    end;

    [Test]
    [HandlerFunctions('ReadCaptionsHandler')]
    procedure PrecompiledRequestPage_PageVariableControl_IsTheCaption()
    begin
        Initialize();

        Report.Run(Report::"Export Consolidation");

        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        Assert.AreEqual('File Format', SeenCaption,
            'report 91 declares Caption = ''File Format'' on request-page control FileFormat');
        Assert.AreEqual('File Name', SeenSecondCaption,
            'report 91 declares Caption = ''File Name'' on request-page control ClientFileNameControl');
    end;

    [Test]
    [HandlerFunctions('InvalidFileFormatHandler')]
    procedure PrecompiledRequestPage_OptionRefusal_NamesTheCaption()
    begin
        Initialize();

        Report.Run(Report::"Export Consolidation");

        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        Assert.IsTrue(StrPos(SeenError, 'Your entry of ''Not A Format'' is not an acceptable value for ''File Format''.') > 0,
            'the refusal must name the control Caption ''File Format''; got: ' + SeenError);
    end;

    [RequestPageHandler]
    procedure ReadCaptionsHandler(var RequestPage: TestRequestPage "Export Consolidation")
    begin
        HandlerRan := true;
        SeenCaption := RequestPage.FileFormat.Caption();
        SeenSecondCaption := RequestPage.ClientFileNameControl.Caption();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure InvalidFileFormatHandler(var RequestPage: TestRequestPage "Export Consolidation")
    begin
        HandlerRan := true;
        asserterror RequestPage.FileFormat.SetValue('Not A Format');
        SeenError := GetLastErrorText();
        RequestPage.Cancel().Invoke();
    end;
}
