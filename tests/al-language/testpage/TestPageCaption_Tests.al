// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-caption-method
//                    https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-caption-method
// Scope: in-scope
// Fixtures used: TP Caption Row (60992), TP Static Caption Card (60936), TP Dynamic Caption Card (60937),
//                 TP Field Caption Row (60993), TP Field Caption List (60938)
//
// TestPage.Caption() must return the page's real caption: the static Caption property when
// nothing overrides it, and the value assigned via CurrPage.Caption in OnOpenPage when it does.
//
// TestPage.<field>.Caption() must return the control's real caption, resolved in the same order
// the client resolves it: a control-declared Caption wins, then the source field's Caption, then
// (only when neither exists) the field's technical name.

codeunit 60954 "Test Page Caption Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        CaptionRow: Record "TP Caption Row";
        FieldCaptionRow: Record "TP Field Caption Row";
    begin
        CaptionRow.DeleteAll();
        FieldCaptionRow.DeleteAll();
    end;

    local procedure SeedFieldCaptionRow()
    var
        FieldCaptionRow: Record "TP Field Caption Row";
    begin
        FieldCaptionRow.Init();
        FieldCaptionRow.PK := 'ROW1';
        FieldCaptionRow.Klass := 'High';
        FieldCaptionRow.Chosen := true;
        FieldCaptionRow.Insert();
    end;

    [Test]
    procedure StaticCaptionProperty_IsReturned()
    var
        StaticPage: TestPage "TP Static Caption Card";
    begin
        Initialize();

        StaticPage.OpenView();
        if StaticPage.Caption() <> 'Static Caption' then
            Error('Expected the static Caption property, got "%1"', StaticPage.Caption());
        StaticPage.Close();
    end;

    [Test]
    procedure DynamicCaptionSetInOnOpenPage_IsReturned()
    var
        DynamicPage: TestPage "TP Dynamic Caption Card";
    begin
        Initialize();

        // OnOpenPage overwrites the static 'Static Caption' with CurrPage.Caption := 'Dynamic Caption'.
        DynamicPage.OpenView();
        if DynamicPage.Caption() <> 'Dynamic Caption' then
            Error('Expected the runtime CurrPage.Caption value, got "%1"', DynamicPage.Caption());
        DynamicPage.Close();
    end;

    [Test]
    procedure FieldWithNoCaptionAnywhere_FallsBackToFieldName()
    var
        FieldCapList: TestPage "TP Field Caption List";
    begin
        Initialize();
        SeedFieldCaptionRow();

        FieldCapList.OpenView();
        // "PK" has no control Caption and no field Caption -> falls back to the field's name.
        if FieldCapList.PK.Caption() <> 'PK' then
            Error('Expected the fallback field name, got "%1"', FieldCapList.PK.Caption());
        FieldCapList.Close();
    end;

    [Test]
    procedure FieldControlCaptionFallsBackToFieldCaption()
    var
        FieldCapList: TestPage "TP Field Caption List";
    begin
        Initialize();
        SeedFieldCaptionRow();

        FieldCapList.OpenView();
        // "Klass" declares no control Caption; the source field declares Caption = 'Severity'.
        if FieldCapList.Klass.Caption() <> 'Severity' then
            Error('Expected the source field caption, got "%1"', FieldCapList.Klass.Caption());
        FieldCapList.Close();
    end;

    [Test]
    procedure ControlDeclaredCaptionWinsOverFieldCaption()
    var
        FieldCapList: TestPage "TP Field Caption List";
    begin
        Initialize();
        SeedFieldCaptionRow();

        FieldCapList.OpenView();
        // "Chosen" declares control Caption = 'Control Cap'; the field itself declares Caption = 'Accept'.
        // The control wins.
        if FieldCapList.Chosen.Caption() <> 'Control Cap' then
            Error('Expected the control-declared caption, got "%1"', FieldCapList.Chosen.Caption());
        FieldCapList.Close();
    end;
}
