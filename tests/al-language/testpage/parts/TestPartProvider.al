// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-provider-property
// Scope: in-scope
// Fixtures used: PVD Header (69140), PVD Line (69141), PVD Detail (69142), PVD Lines Part (69140),
//                PVD Detail Part (69141), PVD Header Card (69142); shared Assert (60021)
//
// WHEN a part declares Provider = <another part>, whose row do its SubPageLink FIELD entries read?
//
// The shape of Business Central's own document pages: Sales Quote's "Sales Line FactBox" has
// Provider = SalesLines and SubPageLink = "Document No." = field("Document No."), where
// "Document No." is a field of the sales LINES, not of the Sales Header the page is over.
//
// The fixture makes the two readings differ. The host "PVD Header" has a "Line No." field of its
// own (value 1) so a link resolved against the host would read 1; the Provider's table "PVD Line"
// has "Line No." 10 and 20, and "PVD Detail" rows are keyed to 1, 10 and 20.
codeunit 69140 "PVD Provider Tests"
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

        InsertLine('H1', 10);
        InsertLine('H1', 20);
        InsertDetail(1, 10, 'ten');
        InsertDetail(2, 20, 'twenty');
        InsertDetail(3, 1, 'decoy');
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

    // CLAIM: the Provider-linked part shows the rows keyed to the Provider part's first row, and
    // not the row keyed to the host's own field of the same name ('decoy').
    [Test]
    procedure ProviderLinkedPart_ShowsTheRowsOfTheProvidersCurrentRow()
    var
        Card: TestPage "PVD Header Card";
    begin
        Initialize();

        Card.OpenView();
        Card.GoToKey('H1');
        Assert.IsTrue(Card.Lines.First(), 'the Lines part has a first row');
        Assert.AreEqual(10, Card.Lines.LineNo.AsInteger(), 'the Provider is on line 10');

        Assert.IsTrue(Card.Detail.First(), 'the Detail part has a row for line 10');
        Assert.AreEqual('ten', Card.Detail.Info.Value, 'Detail shows line 10''s detail, not the host''s decoy');
        Assert.IsFalse(Card.Detail.Next(), 'exactly one detail row is keyed to line 10');
    end;

    // CLAIM: moving the Provider to its second row re-points the Provider-linked part.
    [Test]
    procedure ProviderLinkedPart_FollowsTheProviderWhenItMoves()
    var
        Card: TestPage "PVD Header Card";
    begin
        Initialize();

        Card.OpenView();
        Card.GoToKey('H1');
        Assert.IsTrue(Card.Lines.First(), 'first line');
        Assert.IsTrue(Card.Lines.Next(), 'second line');
        Assert.AreEqual(20, Card.Lines.LineNo.AsInteger(), 'the Provider is on line 20');

        Assert.IsTrue(Card.Detail.First(), 'the Detail part has a row for line 20');
        Assert.AreEqual('twenty', Card.Detail.Info.Value, 'Detail follows the Provider to line 20');
        Assert.IsFalse(Card.Detail.Next(), 'exactly one detail row is keyed to line 20');
    end;

    // CLAIM: with a Provider that has no row (H2 has no lines), the part does not read the host.
    // The host's own "Line No." = 1 would select the 'decoy' row if the host were read.
    [Test]
    procedure ProviderLinkedPart_WithAnEmptyProvider_DoesNotReadTheHost()
    var
        Card: TestPage "PVD Header Card";
    begin
        Initialize();

        Card.OpenView();
        Card.GoToKey('H2');

        Assert.IsFalse(Card.Lines.First(), 'H2 has no lines');
        Assert.IsFalse(Card.Detail.First(), 'with no provider row the Detail part shows nothing, not the host''s decoy');
    end;

    // CLAIM: the same, after the Provider HAD a row on the previous host row (H1 -> H2): the part
    // does not keep showing the row the Provider stood on before it ran out of rows.
    [Test]
    procedure ProviderLinkedPart_ProviderLosesItsRows_DoesNotKeepTheOldRow()
    var
        Card: TestPage "PVD Header Card";
    begin
        Initialize();

        Card.OpenView();
        Card.GoToKey('H1');
        Assert.IsTrue(Card.Lines.First(), 'H1 has lines');
        Assert.IsTrue(Card.Detail.First(), 'and its first line has a detail');

        Card.GoToKey('H2');
        Assert.IsFalse(Card.Lines.First(), 'H2 has no lines');
        Assert.IsFalse(Card.Detail.First(), 'the Detail part no longer shows the detail of H1''s line 10');
    end;

    // CLAIM: an editable host (the provider offers a draft line) behaves the same way.
    [Test]
    procedure ProviderLinkedPart_EditableHostWithAnEmptyProvider_ShowsNothing()
    var
        Card: TestPage "PVD Header Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.GoToKey('H2');

        Assert.IsFalse(Card.Detail.First(), 'with an empty Provider the Detail part shows nothing, not the host''s decoy');
    end;
}
