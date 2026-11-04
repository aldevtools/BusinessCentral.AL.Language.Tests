// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-modal-page-handler
// Scope: in-scope
// Fixtures used: Test Page Enum Var Row (60717), Test Page Enum Var Kind (60718),
//   Test Page Enum Var Modal (60719), Assert (60021)
//
// Page.RunModal() on a page whose layout binds a control to a page GLOBAL VARIABLE of type
// Enum. This is distinct from TestPageEnumField_Tests.al (an Enum-typed RECORD FIELD control),
// and from TestPageModalHandler_ModalVarsPage.al / TestPageVariableControl_Page.al (page-global
// variable controls, but typed Text / Option, not Enum) — the combination of "page-global
// variable" AND "Enum" is what this suite pins.

codeunit 60720 "Test Page Enum Var Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "Test Page Enum Var Row";
    begin
        Row.DeleteAll();
    end;

    // Positive: RunModal materialises the page at all (an enum-bound page-global control must
    // not block form construction), the [ModalPageHandler] runs, and the handler's SetValue
    // reaches the page's own OnValidate trigger.
    [Test]
    [HandlerFunctions('KindHandler')]
    procedure RunModal_EnumGlobalControl_HandlerSetsValueAndOnValidateSeesIt()
    var
        Echo: Record "Test Page Enum Var Row";
        Modal: Page "Test Page Enum Var Modal";
    begin
        Initialize();

        Modal.RunModal();

        Assert.IsTrue(Echo.Get('KIND'),
            'the [ModalPageHandler] must have run and OnValidate must have fired');
    end;

    // Positive, concrete value: after RunModal returns, the page variable itself holds the
    // SPECIFIC member the handler chose BY CAPTION ('Blocks', ordinal 1) — not the field's zero
    // default, and not some other member. Proves the control's real current value (not a
    // stashed/default one) round-trips through the page.
    //
    // SetValue is driven by the enum's declared Caption ('Blocks'), not by the member name
    // ('Block') — verified against a real BC service tier: SetValue('Block') throws "Your entry
    // of 'Block' is not an acceptable value for 'Kind'." (see
    // RunModal_EnumGlobalControl_SetValueRejectsTheBareMemberName below). An Enum-typed
    // TestPage control resolves by Caption only, the same as the control-level OptionCaption an
    // Option-typed control declares — it does NOT fall back to the member name the way this
    // suite originally (incorrectly) assumed.
    [Test]
    [HandlerFunctions('KindHandler')]
    procedure RunModal_EnumGlobalControl_ProcedureReadsBackTheHandlerChosenValue()
    var
        Modal: Page "Test Page Enum Var Modal";
    begin
        Initialize();

        Modal.RunModal();

        Assert.AreEqual(1, Modal.GetSelectedKindOrdinal(),
            'the page variable must hold the handler-set member (Blocks = 1), not the default (Fields = 0)');
    end;

    // Negative / control: WITHOUT RunModal, the same page variable's procedure still works and
    // reads the declared default. This is the exact split the original report described — the
    // enum itself is always compiled and reachable; only FORM MATERIALISATION can regress. If
    // this test fails too, the defect is unrelated to page materialisation.
    [Test]
    procedure GetSelectedKindOrdinal_WithoutRunModal_ReadsTheDeclaredDefault()
    var
        Modal: Page "Test Page Enum Var Modal";
    begin
        Initialize();

        Assert.AreEqual(0, Modal.GetSelectedKindOrdinal(),
            'without RunModal the page variable never left its declared default (Field = 0)');
    end;

    // Negative: the bare member name is NOT an acceptable TestPage.SetValue spelling for an
    // Enum-typed control. BC's error names the rejected value and the field it was rejected on,
    // so this also pins the message shape, not just "some error happened".
    [Test]
    [HandlerFunctions('KindHandlerRejectsMemberName')]
    procedure RunModal_EnumGlobalControl_SetValueRejectsTheBareMemberName()
    var
        Echo: Record "Test Page Enum Var Row";
        Modal: Page "Test Page Enum Var Modal";
    begin
        Initialize();

        Modal.RunModal();

        Assert.IsFalse(Echo.Get('KIND'),
            'OnValidate must not have fired — the rejected SetValue never reached the control''s bound value');
    end;

    // Positive, read-side complement of RunModal_EnumGlobalControl_ProcedureReadsBackTheHandler-
    // ChosenValue above: TestPage.Value() on an enum-bound page-global control must answer the
    // member's CAPTION ('Blocks'), not the raw ordinal ('1') it stores underneath. The value is
    // seeded to a NON-DEFAULT member before RunModal so the assertion cannot be satisfied by
    // the default member's caption coincidentally matching.
    [Test]
    [HandlerFunctions('KindHandlerReadsBackTheCaption')]
    procedure RunModal_EnumGlobalControl_ValueReturnsTheCaptionNotTheOrdinal()
    var
        Modal: Page "Test Page Enum Var Modal";
    begin
        Initialize();

        Modal.SeedKind(Enum::"Test Page Enum Var Kind"::Block);
        Modal.RunModal();
    end;

    [ModalPageHandler]
    procedure KindHandler(var Modal: TestPage "Test Page Enum Var Modal")
    begin
        Modal.KindSelector.SetValue('Blocks');
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure KindHandlerReadsBackTheCaption(var Modal: TestPage "Test Page Enum Var Modal")
    begin
        Assert.AreEqual('Blocks', Format(Modal.KindSelector.Value()),
            'the enum-bound page-global control must read back its CAPTION, not the raw ordinal it stores');
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure KindHandlerRejectsMemberName(var Modal: TestPage "Test Page Enum Var Modal")
    begin
        asserterror Modal.KindSelector.SetValue('Block');
        Assert.ExpectedError('not an acceptable value');
        Modal.OK().Invoke();
    end;
}
