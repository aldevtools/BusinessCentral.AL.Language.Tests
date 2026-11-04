// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-provider-property
// Scope: in-scope
// Fixtures used: PVD Header (69140), PVD Line (69141), PVD Detail (69142), PVD Lines Part (69140),
//                PVD Detail Part (69141), PVD Header Card (69142), PVD Plain Card (69143);
//                shared Assert (60021)
//
// WHAT does a part read after the part it takes its link from has moved, and the part itself has not?
// Codeunit 69140 "PVD Provider Tests" pins which row a Provider-linked part's rowset follows, and
// always moves the part (Detail.First()) before reading it. These arms read WITHOUT that move: the
// part's own current row is what is measured.
//
// Measured on real BC (the first revisions of this file recorded each reading instead of asserting
// it): a Provider-linked part follows its Provider on its own, and a part whose link matches no
// row reads blank.
//
// NOT pinned here, on purpose: which row an UNPOSITIONED part stands on when the host returns to a
// row it left. After the host went H1 -> elsewhere -> H1 BC answered the SECOND row (line 20) on
// every cloud leg, where it answers the FIRST row of the other headers it was probed with. The
// reading is reproducible and unexplained, so no arm asserts it; the arms below read only after
// the part was positioned or on a first arrival.
codeunit 69143 "PVD Provider Move Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Header: Record "PVD Header";
        Line: Record "PVD Line";
        Detail: Record "PVD Detail";
    begin
        Detail.DeleteAll();
        Line.DeleteAll();
        Header.DeleteAll();

        Header.Init();
        Header."No." := 'H1';
        Header."Line No." := 1;
        Header.Insert();
        Header.Init();
        Header."No." := 'H2';
        Header."Line No." := 1;
        Header.Insert();

        Header.Init();
        Header."No." := 'H3';
        Header."Line No." := 1;
        Header.Insert();
        Header.Init();
        Header."No." := 'H4';
        Header."Line No." := 1;
        Header.Insert();

        InsertLine('H1', 10);
        InsertLine('H1', 20);
        InsertLine('H3', 30);
        InsertLine('H3', 40);
        InsertLine('H3', 50);
        InsertLine('H4', 60);
        InsertDetail(1, 10, 'ten');
        InsertDetail(2, 20, 'twenty');
        InsertDetail(3, 1, 'decoy');
        InsertDetail(4, 30, 'thirty');
        InsertDetail(5, 40, 'forty');
        InsertDetail(6, 50, 'fifty');
        InsertDetail(7, 60, 'sixty');
    end;

    local procedure InsertLine(HeaderNo: Code[20]; LineNo: Integer)
    var
        Line: Record "PVD Line";
    begin
        Line.Init();
        Line."Header No." := HeaderNo;
        Line."Line No." := LineNo;
        Line.Insert();
    end;

    local procedure InsertDetail(EntryNo: Integer; LineRef: Integer; Info: Text[30])
    var
        Detail: Record "PVD Detail";
    begin
        Detail.Init();
        Detail."Entry No." := EntryNo;
        Detail."Line Ref" := LineRef;
        Detail.Info := Info;
        Detail.Insert();
    end;

    // A TryFunction, not asserterror: an error caught by asserterror rolls the test's writes back.
    local procedure Open(var Card: TestPage "PVD Header Card")
    begin
        Initialize();
        Card.OpenView();
    end;

    // CLAIM: the Provider-linked part follows the Provider's own moves, without being moved itself.
    [Test]
    procedure ProviderLinkedPart_FollowsTheProviderWhenOnlyTheProviderMoves()
    var
        Card: TestPage "PVD Header Card";
    begin
        Open(Card);
        Card.GoToKey('H1');
        Card.Lines.First();
        Assert.AreEqual('ten', Card.Detail.Info.Value, 'the Provider is on line 10');

        Card.Lines.Next();
        Assert.AreEqual(20, Card.Lines.LineNo.AsInteger(), 'the Provider moved to line 20');
        Assert.AreEqual('twenty', Card.Detail.Info.Value, 'Detail follows without a move of its own');

        Card.Lines.Previous();
        Assert.AreEqual('ten', Card.Detail.Info.Value, 'and follows the Provider back');
    end;

    // CLAIM: the same when the Provider has not been positioned explicitly first.
    [Test]
    procedure ProviderLinkedPart_FollowsTheProviderWhenItStepsWithoutFirst()
    var
        Card: TestPage "PVD Header Card";
    begin
        Open(Card);
        Card.GoToKey('H1');
        Assert.AreEqual('ten', Card.Detail.Info.Value, 'before the Provider moves');

        Card.Lines.Next();
        Assert.AreEqual('twenty', Card.Detail.Info.Value, 'after the Provider stepped to line 20');
    end;

    // CLAIM: the part's own cursor is on the row the Provider selected, so stepping it past the one
    // row there is none, and First() lands on the row it already shows.
    [Test]
    procedure ProviderLinkedPart_AfterTheProviderMoved_ItsOwnCursorIsOnTheProvidersRow()
    var
        Card: TestPage "PVD Header Card";
    begin
        Open(Card);
        Card.GoToKey('H3');
        Card.Lines.First();
        Card.Lines.Next();
        Assert.AreEqual('forty', Card.Detail.Info.Value, 'the Provider is on line 40');

        Assert.IsFalse(Card.Detail.Next(), 'exactly one detail row is keyed to line 40');
        Assert.AreEqual('forty', Card.Detail.Info.Value, 'a failed Next() stays on the row');
        Assert.IsTrue(Card.Detail.First(), 'First() finds that row');
        Assert.AreEqual('forty', Card.Detail.Info.Value, 'and reads it');
    end;

    // CLAIM: the host moves to a row whose Provider has no rows: the part reads blank, and does not
    // keep the row it showed for the previous host row.
    [Test]
    procedure ProviderLinkedPart_HostMovesToAnEmptyProvider_ReadsBlank()
    var
        Card: TestPage "PVD Header Card";
    begin
        Open(Card);
        Card.GoToKey('H1');
        Assert.AreEqual('ten', Card.Detail.Info.Value, 'H1 shows its first line''s detail');

        Card.GoToKey('H2');
        Assert.AreEqual('', Card.Detail.Info.Value, 'H2 has no lines, so nothing is shown');
        Assert.IsFalse(Card.Detail.First(), 'and the part has no row to go to');
        Assert.AreEqual('', Card.Detail.Info.Value, 'still blank after that First()');
        Assert.IsFalse(Card.Lines.First(), 'the Provider has no row either');
    end;

    // CLAIM: from a host row with no lines the part follows the Provider onto the next host row.
    [Test]
    procedure ProviderLinkedPart_HostMovesFromAnEmptyProvider_ReadsTheNextProvidersRow()
    var
        Card: TestPage "PVD Header Card";
    begin
        Open(Card);
        Card.GoToKey('H2');
        Assert.AreEqual('', Card.Detail.Info.Value, 'H2 has no lines');

        Card.GoToKey('H3');
        Assert.AreEqual('thirty', Card.Detail.Info.Value, 'H3''s first line is 30');

        Card.GoToKey('H2');
        Assert.AreEqual('', Card.Detail.Info.Value, 'back to a host row without lines');

        Card.GoToKey('H4');
        Assert.AreEqual('sixty', Card.Detail.Info.Value, 'H4''s only line is 60');
    end;

    // CLAIM: the host moves between rows that each have lines: the part reads each Provider's
    // first row, not the previous host row's.
    [Test]
    procedure ProviderLinkedPart_HostMovesBetweenNonEmptyProviders_ReadsTheNewProvidersFirstRow()
    var
        Card: TestPage "PVD Header Card";
    begin
        Open(Card);
        Card.GoToKey('H1');
        Assert.AreEqual('ten', Card.Detail.Info.Value, 'H1');

        Card.GoToKey('H3');
        Assert.AreEqual('thirty', Card.Detail.Info.Value, 'H3');

        Card.GoToKey('H4');
        Assert.AreEqual('sixty', Card.Detail.Info.Value, 'H4');
    end;

    // CLAIM: a part read straight after the host opens, with nothing navigated, shows the Provider's
    // first row's detail.
    [Test]
    procedure ProviderLinkedPart_ReadRightAfterOpen_ReadsTheFirstProvidersRow()
    var
        Card: TestPage "PVD Header Card";
    begin
        Open(Card);
        Assert.AreEqual('ten', Card.Detail.Info.Value, 'the host opens on H1');
    end;

    // CONTRAST: a part with a SubPageLink and no Provider (nothing names it either) reads blank
    // when the host moves to a row with no matching rows, the same as the Provider-linked one.
    [Test]
    procedure PlainLinkedPart_HostMovesToARowWithNoChildren_ReadsBlank()
    var
        Card: TestPage "PVD Plain Card";
    begin
        Initialize();
        Card.OpenView();
        Card.GoToKey('H1');
        Assert.AreEqual('H1', Card.Lines.HeaderNo.Value, 'H1 shows its lines');

        Card.GoToKey('H2');
        Assert.AreEqual('', Card.Lines.HeaderNo.Value, 'H2 has no lines, so the part shows nothing');

        Card.GoToKey('H3');
        Assert.AreEqual('H3', Card.Lines.HeaderNo.Value, 'H3 shows its lines again');
    end;
}
