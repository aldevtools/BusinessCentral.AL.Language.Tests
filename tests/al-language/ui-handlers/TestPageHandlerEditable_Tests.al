// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-editable-method
// Scope: in-scope
// Fixtures used: Test Page Hdlr Editable RO (60745), Test Page Hdlr Editable RW (60746)
//
// Page-level TestPage.Editable() on a page the TEST NEVER OPENED.
//
// Every existing Editable() test in this corpus opens the page itself (OpenEdit / OpenView), so
// the open mode is always available to answer from. A page reached through a [ModalPageHandler]
// has no open mode: BC opened it, the test only receives it. What the page's own declared
// Editable contributes on THAT path is untested here, and it is the half a runner is most
// likely to get wrong — the cheap implementation is a constant true, which no existing test
// can fail.
//
// The two arms differ only in the declared property, so a constant answer in either direction
// fails exactly one of them.

codeunit 60747 "Test Page Hdlr Editable Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    [HandlerFunctions('ReadOnlyCardHandler')]
    procedure EditableFalsePage_ReachedThroughAHandler_IsNotEditable()
    var
        Card: Page "Test Page Hdlr Editable RO";
    begin
        Card.RunModal();
    end;

    [ModalPageHandler]
    procedure ReadOnlyCardHandler(var Card: TestPage "Test Page Hdlr Editable RO")
    begin
        Assert.IsFalse(Card.Editable(),
            'a page declaring Editable = false must report Editable() = false even though the test never opened it');
    end;

    [Test]
    [HandlerFunctions('WritableCardHandler')]
    procedure EditableDefaultPage_ReachedThroughAHandler_IsEditable()
    var
        Card: Page "Test Page Hdlr Editable RW";
    begin
        Card.RunModal();
    end;

    [ModalPageHandler]
    procedure WritableCardHandler(var Card: TestPage "Test Page Hdlr Editable RW")
    begin
        Assert.IsTrue(Card.Editable(),
            'a page declaring no Editable property defaults to editable, and a handler must see that');
    end;
}
