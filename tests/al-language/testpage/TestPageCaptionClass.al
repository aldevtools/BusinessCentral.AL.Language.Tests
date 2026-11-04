// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-caption-method
//                    https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: in-scope
// Fixtures used: TPCC Row (60981), TPCC Card (60981)
//
// TestPage.<field>.Caption() on a control that declares CaptionClass returns the CaptionClass
// expression as the caption-class resolver translates it -- not the control's source expression,
// not the source field's Caption, and not the control's own declared Caption. Area '3' returns the
// text after the first comma; an expression no resolver claims comes back unchanged. The expression
// is evaluated from page state, so a CaptionClass built from a page global reflects the value
// OnOpenPage gave it. Base Application matrix pages (CaptionClass = '3,' + MATRIX_ColumnCaption[N])
// depend on exactly this.

codeunit 60930 "TPCC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TPCC Row";
    begin
        Row.DeleteAll();
    end;

    local procedure OpenCard(var Card: TestPage "TPCC Card")
    var
        Row: Record "TPCC Row";
    begin
        Row."No." := 'ROW1';
        Row.Insert();
        Card.OpenView();
    end;

    [Test]
    procedure TestPageField_Caption_CaptionClassFromPageGlobal_ReturnsResolvedText()
    var
        Card: TestPage "TPCC Card";
    begin
        Initialize();
        OpenCard(Card);
        Assert.AreEqual('Sep 2026', Card.Column1.Caption(), 'Column1 caption from CaptionClass ''3,'' + ColumnCaption[1]');
        Assert.AreEqual('Oct 2026', Card.Column2.Caption(), 'Column2 caption from CaptionClass ''3,'' + ColumnCaption[2]');
        Card.Close();
    end;

    [Test]
    procedure TestPageField_Caption_ConstantCaptionClass_WinsOverFieldCaption()
    var
        Card: TestPage "TPCC Card";
    begin
        Initialize();
        OpenCard(Card);
        Assert.AreEqual('Fixed Text', Card.ConstantClass.Caption(), 'CaptionClass ''3,Fixed Text'' on a Rec-bound control');
        Card.Close();
    end;

    [Test]
    procedure TestPageField_Caption_NoCaptionClass_ReturnsFieldCaption()
    var
        Card: TestPage "TPCC Card";
    begin
        Initialize();
        OpenCard(Card);
        Assert.AreEqual('Quantity Field Caption', Card.NoClass.Caption(), 'a control without CaptionClass');
        Card.Close();
    end;

    [Test]
    procedure TestPageField_Caption_CaptionClass_WinsOverDeclaredCaption()
    var
        Card: TestPage "TPCC Card";
    begin
        Initialize();
        OpenCard(Card);
        Assert.AreEqual('Class Caption', Card.CaptionAndClass.Caption(), 'a control declaring both Caption and CaptionClass');
        Card.Close();
    end;

    [Test]
    procedure TestPageField_Caption_UnresolvedCaptionClass_ReturnsExpressionUnchanged()
    var
        Card: TestPage "TPCC Card";
    begin
        Initialize();
        OpenCard(Card);
        Assert.AreEqual('ZZ,Unknown Area', Card.UnknownArea.Caption(), 'a CaptionClass area no resolver claims');
        Assert.AreEqual('No Comma Here', Card.NoComma.Caption(), 'a CaptionClass with no area at all');
        Card.Close();
    end;

    [Test]
    procedure TestPageField_Caption_CaptionClass_IsNotTheSourceExpression()
    var
        Card: TestPage "TPCC Card";
    begin
        Initialize();
        OpenCard(Card);
        asserterror Assert.AreEqual('CellData[1]', Card.Column1.Caption(), 'source expression');
        Assert.ExpectedError('Sep 2026');
        Card.Close();
    end;

    // ── Added by writer bs (corpus issue #668, item 99): tableextension 83160 and pageextension 83162 in
    //    tableextension/lt-bs-tableext-leads/BsObjects.al ──

    [Test]
    procedure TestPageField_Caption_TableExtensionFieldCaptionClass()
    // CLAIM (issue #668 item 99): a field that a tableextension ADDS declares CaptionClass = '3,LT BS Added Field Class' (and a Caption).
    // A page extension control on it without its own CaptionClass: does the table field's CaptionClass apply? A second control on the same
    // field with CaptionClass = '3,LT BS Page Class': which wins? What do FieldCaption and FieldRef.Caption give?
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "TPCC Card";
        Row: Record "TPCC Row";
        RecRef: RecordRef;
    begin
        Initialize();
        OpenCard(Card);
        Observer.Observe('page_control_no_class', Card.BsCapNew.Caption());
        Observer.Observe('page_control_with_class', Card.BsCapNewPageClass.Caption());
        Card.Close();
        Observer.Observe('field_caption', Row.FieldCaption(BsCapNew));
        RecRef.Open(Database::"TPCC Row");
        Observer.Observe('fieldref_caption', RecRef.Field(83180).Caption());
        RecRef.Close();
        Observer.Expect('page_control_no_class', 'LT BS Added Field Class');
        Observer.Expect('page_control_with_class', 'LT BS Page Class');
        Observer.Expect('field_caption', 'LT BS Added Field Class');
        Observer.Expect('fieldref_caption', 'LT BS Added Field Class');
        Observer.Verify();
    end;

    [Test]
    procedure TestPageField_Caption_TableExtensionModifiedFieldCaptionClass_QB()
    // CLAIM (issue #668 item 99, writer QB): a tableextension sets CaptionClass with modify() on a base field that has only a Caption
    // (Remark) and on one that already has a CaptionClass (Amount). What do the page controls, FieldCaption and FieldRef.Caption give?
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QB Cc Card";
        Row: Record "LT QB Cc Row";
        RecRef: RecordRef;
    begin
        Row.DeleteAll();
        Row."No." := 'QB1';
        Row.Insert();
        Card.OpenView();
        Observer.Observe('remark control', Card.RemarkCtl.Caption());
        Observer.Observe('remark control with class', Card.RemarkPageClass.Caption());
        Observer.Observe('amount control', Card.AmountCtl.Caption());
        Observer.Observe('plain control', Card.PlainCtl.Caption());
        Card.Close();
        Observer.Observe('remark FieldCaption', Row.FieldCaption(Remark));
        Observer.Observe('amount FieldCaption', Row.FieldCaption(Amount));
        Observer.Observe('plain FieldCaption', Row.FieldCaption(Plain));
        RecRef.Open(Database::"LT QB Cc Row");
        Observer.Observe('remark FieldRef.Caption', RecRef.Field(2).Caption());
        Observer.Observe('amount FieldRef.Caption', RecRef.Field(3).Caption());
        RecRef.Close();
        Observer.Expect('remark control', 'QB Modified Class');
        Observer.Expect('remark control with class', 'QB Page Class');
        Observer.Expect('amount control', 'QB Modified Over Base');
        Observer.Expect('plain control', 'QB Plain Caption');
        Observer.Expect('remark FieldCaption', 'QB Modified Class');
        Observer.Expect('amount FieldCaption', 'QB Modified Over Base');
        Observer.Expect('plain FieldCaption', 'QB Plain Caption');
        Observer.Expect('remark FieldRef.Caption', 'QB Modified Class');
        Observer.Expect('amount FieldRef.Caption', 'QB Modified Over Base');
        Observer.Verify();
    end;
}
