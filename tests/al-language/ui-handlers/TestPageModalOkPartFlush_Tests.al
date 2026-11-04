// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onqueryclosepage-page-trigger
// Scope: in-scope
// Fixtures used: Opf Line (60637), Opf Result (60638), Opf Lines Part (60639),
//                Opf Outer Card (60659), Assert (60021)
//
// WHEN a [ModalPageHandler] presses the built-in OK, is a row it typed into a PART already saved
// by the time OnQueryClosePage runs?
//
// Pressing OK is a client action: the client sends the row being edited to the server and only
// then drives the close, so a page that materialises its part contents in OnQueryClosePage --
// the ordinary "write what the user entered when they press OK" shape -- must see the row. The
// alternative, that the close runs first and the part row is saved afterwards, would make that
// whole shape silently save nothing, so this is worth pinning rather than assuming.
//
// The assertions are read AFTER the round trip, from a table the trigger wrote, and they are
// concrete values: an implementation that ran the trigger against an empty part, and one that
// never ran the trigger at all, fail different assertions here rather than both passing.
//
// Filed from AlRunner#3701.
codeunit 60663 "Opf Ok Part Flush Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Result: Record "Opf Result";
    begin
        Result.DeleteAll();
    end;

    // CLAIM: the part row the handler typed is visible to OnQueryClosePage.
    [Test]
    [HandlerFunctions('OpfTypeALineThenOkHandler')]
    procedure OkInvokeSavesThePartRowBeforeQueryClosePageRuns()
    var
        Result: Record "Opf Result";
        Card: Page "Opf Outer Card";
        ModalResult: Action;
    begin
        Initialize();

        ModalResult := Card.RunModal();

        Assert.AreEqual(Format(Action::OK), Format(ModalResult),
            'A modal the handler closes with the built-in OK must report OK.');
        Assert.IsTrue(Result.Get('CLOSE'),
            'OnQueryClosePage must have run on the OK close and written its witness row.');
        Assert.AreEqual(1, Result."Line Count",
            'OnQueryClosePage must see the row the handler typed into the part -- pressing OK saves the edited row before the close runs.');
        Assert.AreEqual('Alpha', Result."Value Seen",
            'The part row OnQueryClosePage sees must carry the value the handler typed, not a blank row.');
    end;

    [ModalPageHandler]
    procedure OpfTypeALineThenOkHandler(var Card: TestPage "Opf Outer Card")
    begin
        Card.Lines.New();
        Card.Lines."Value".SetValue('Alpha');
        Card.OK().Invoke();
    end;

    // NEGATIVE CONTROL: no typed row, same close. Nothing may appear in the part, so a platform
    // (or a runner) that satisfies the arm above by inventing a row fails here.
    [Test]
    [HandlerFunctions('OpfTypeNothingThenOkHandler')]
    procedure OkInvokeWithNothingTypedLeavesThePartEmpty()
    var
        Result: Record "Opf Result";
        Card: Page "Opf Outer Card";
    begin
        Initialize();

        Card.RunModal();

        Assert.IsTrue(Result.Get('CLOSE'),
            'OnQueryClosePage must have run on the OK close even when the handler typed nothing.');
        Assert.AreEqual(0, Result."Line Count",
            'A handler that typed no row must leave the part empty at OnQueryClosePage time.');
        Assert.AreEqual('', Result."Value Seen",
            'With no row in the part there is no value to read.');
    end;

    [ModalPageHandler]
    procedure OpfTypeNothingThenOkHandler(var Card: TestPage "Opf Outer Card")
    begin
        Card.OK().Invoke();
    end;

    // Two typed rows, so the count assertion above cannot be satisfied by a fixed 1, and the
    // order the part hands rows back is pinned to the order they were typed in.
    [Test]
    [HandlerFunctions('OpfTypeTwoLinesThenOkHandler')]
    procedure OkInvokeSavesEveryTypedPartRowInOrder()
    var
        Result: Record "Opf Result";
        Card: Page "Opf Outer Card";
    begin
        Initialize();

        Card.RunModal();

        Assert.IsTrue(Result.Get('CLOSE'),
            'OnQueryClosePage must have run on the OK close and written its witness row.');
        Assert.AreEqual(2, Result."Line Count",
            'Both typed rows must be in the part when OnQueryClosePage reads it, including the one still being edited when OK was pressed.');
        Assert.AreEqual('First', Result."Value Seen",
            'The part must hand its rows back in the order they were typed.');
    end;

    [ModalPageHandler]
    procedure OpfTypeTwoLinesThenOkHandler(var Card: TestPage "Opf Outer Card")
    begin
        Card.Lines.New();
        Card.Lines."Value".SetValue('First');
        Card.Lines.New();
        Card.Lines."Value".SetValue('Second');
        Card.OK().Invoke();
    end;
}
