// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onqueryclosepage-page-trigger
// Scope: in-scope
// Fixtures used: Opc Head (60421), Opc Result (60422), Opc Close Card (60423),
//                Opf Line (60637), Opf Lines Part (60639), Assert (60021)
//
// WHEN a test closes a page with TestPage.Close(), is a row it typed into a PART already saved
// by the time OnQueryClosePage runs?
//
// Codeunit 60663 "Opf Ok Part Flush Tests" pins the same question for the OTHER close route --
// a [ModalPageHandler] pressing the built-in OK -- and BC saves the row there. This suite asks
// it of the route a test drives itself, which reaches BC's close handler from a different
// direction: no client action is pressed, the test simply closes the page. A page that
// materialises its part contents in OnQueryClosePage behaves the same way in both cases only if
// the platform sends the edited row before it drives the close on this route too, so the two
// routes are worth pinning separately rather than assuming one from the other.
//
// The assertions are read AFTER Close() has returned, from a table the trigger wrote, and they
// are concrete values: an implementation that ran the trigger against an empty part, and one
// that never ran the trigger at all, fail different assertions here rather than both passing.
//
// The CloseAction the platform passes on this route is recorded by the fixture but deliberately
// not asserted -- that is a separate question, and pinning a guess at it here would make an
// ordering arm red on an unrelated axis.
//
// Filed from AlRunner#3708, out of AlRunner#3701.
codeunit 60438 "Opc Close Part Flush Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Result: Record "Opc Result";
        Head: Record "Opc Head";
    begin
        Result.DeleteAll();
        Head.DeleteAll();

        Head.Init();
        Head."No." := 'H1';
        Head.Descr := 'Host';
        Head.Insert();
    end;

    // CLAIM: the part row the test typed is visible to OnQueryClosePage on the Close() route.
    [Test]
    procedure CloseFlush_PartRowIsVisibleToQueryClosePage()
    var
        Result: Record "Opc Result";
        Card: TestPage "Opc Close Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.Lines.New();
        Card.Lines."Value".SetValue('Alpha');
        Card.Close();

        Assert.IsTrue(Result.Get('CLOSE'),
            'OnQueryClosePage must have run on the TestPage.Close() route and written its witness row.');
        Assert.AreEqual(1, Result."Line Count",
            'OnQueryClosePage must see the row typed into the part -- closing the page sends the edited row before the close runs.');
        Assert.AreEqual('Alpha', Result."Value Seen",
            'The part row OnQueryClosePage sees must carry the value that was typed, not a blank row.');
    end;

    // NEGATIVE CONTROL: no typed row, same close. Nothing may appear in the part, so a platform
    // (or a runner) that satisfies the arm above by inventing a row fails here.
    [Test]
    procedure CloseFlush_NothingTypedLeavesThePartEmpty()
    var
        Result: Record "Opc Result";
        Card: TestPage "Opc Close Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.Close();

        Assert.IsTrue(Result.Get('CLOSE'),
            'OnQueryClosePage must have run on the TestPage.Close() route even when nothing was typed.');
        Assert.AreEqual(0, Result."Line Count",
            'A test that typed no row must leave the part empty at OnQueryClosePage time.');
        Assert.AreEqual('', Result."Value Seen",
            'With no row in the part there is no value to read.');
    end;

    // Two typed rows, so the count assertion above cannot be satisfied by a fixed 1, and the
    // order the part hands rows back is pinned to the order they were typed in.
    [Test]
    procedure CloseFlush_EveryTypedPartRowIsVisibleInOrder()
    var
        Result: Record "Opc Result";
        Card: TestPage "Opc Close Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.Lines.New();
        Card.Lines."Value".SetValue('First');
        Card.Lines.New();
        Card.Lines."Value".SetValue('Second');
        Card.Close();

        Assert.IsTrue(Result.Get('CLOSE'),
            'OnQueryClosePage must have run on the TestPage.Close() route and written its witness row.');
        Assert.AreEqual(2, Result."Line Count",
            'Both typed rows must be in the part when OnQueryClosePage reads it, including the one still being edited when Close() was called.');
        Assert.AreEqual('First', Result."Value Seen",
            'The part must hand its rows back in the order they were typed.');
    end;
}
