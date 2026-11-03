// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-filtergroup-method
// Scope: in-scope
// Fixtures used: SPLG Header (60231), SPLG Line (60232), SPLG Card (60231),
//                SPLG Link Part (60232), SPLG Own Filter Part (60233), SPLG Probe (60231),
//                Assert (60021)
//
/// <summary>
/// Pins WHICH filter group a part's SubPageLink filters land in on the part's own Rec.
///
/// The compiled page metadata carries FilterGroup="4" on every SubFormLink entry, and the
/// platform's PredefinedFilterGroupNo names 4 "Link". Base Application relies on it: page 1286
/// "Payment Rec Match Details" and page "Payment-to-Entry Match" read their link with
/// Rec.FilterGroup(4); Rec.GetFilter(...) and Evaluate the result into an Integer.
///
/// The claims, each in its own test:
///   - under FilterGroup(4) the part's GetFilter answers the link value, for both linked fields;
///   - under FilterGroup(0) it answers '' -- the link is not a group-0 filter;
///   - the link still restricts the rows the part shows;
///   - a part that sets its OWN group-0 filter in OnOpenPage shows only rows that satisfy
///     both, and each group still answers only its own filter;
///   - the same holds for a part on a page opened by Page.RunModal and handed to a
///     [ModalPageHandler].
///
/// The negatives are in the data: header H1 has lines 10000, 20000 and 30000, and header H2
/// has 10000 and 20000. A part that ignored the link, or lost the own filter, shows a row the
/// assertions reject.
/// </summary>
codeunit 60232 "SPLG Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Header: Record "SPLG Header";
        Line: Record "SPLG Line";
        Probe: Codeunit "SPLG Probe";
    begin
        Line.DeleteAll();
        Header.DeleteAll();
        Probe.Reset();
        AddHeader('H1', 10000);
        AddHeader('H2', 20000);
        AddLine('H1', 10000);
        AddLine('H1', 20000);
        AddLine('H1', 30000);
        AddLine('H2', 10000);
        AddLine('H2', 20000);
    end;

    local procedure AddHeader(HeaderCode: Code[20]; SelLineNo: Integer)
    var
        Header: Record "SPLG Header";
    begin
        Header.Init();
        Header."Code" := HeaderCode;
        Header."Sel Line No." := SelLineNo;
        Header.Insert();
    end;

    local procedure AddLine(HeaderCode: Code[20]; LineNo: Integer)
    var
        Line: Record "SPLG Line";
    begin
        Line.Init();
        Line."Header Code" := HeaderCode;
        Line."Line No." := LineNo;
        Line.Insert();
    end;

    local procedure OpenCardOn(var Card: TestPage "SPLG Card"; HeaderCode: Code[20])
    var
        Header: Record "SPLG Header";
    begin
        Header.Get(HeaderCode);
        Card.OpenView();
        Card.GoToRecord(Header);
    end;

    [Test]
    procedure LinkFilter_UnderFilterGroup4_AnswersTheLinkValues()
    var
        Probe: Codeunit "SPLG Probe";
        Card: TestPage "SPLG Card";
    begin
        Initialize();
        OpenCardOn(Card, 'H1');

        Assert.AreNotEqual(0, Probe.LinkFiredCount(), 'the link part''s OnAfterGetCurrRecord never ran');
        Assert.AreEqual('10000', Probe.LinkG4Line(), 'FilterGroup(4) GetFilter("Line No.") on the link part');
        Assert.AreEqual('H1', Probe.LinkG4Header(), 'FilterGroup(4) GetFilter("Header Code") on the link part');
        Card.Close();
    end;

    [Test]
    procedure LinkFilter_UnderFilterGroup0_AnswersNothing()
    var
        Probe: Codeunit "SPLG Probe";
        Card: TestPage "SPLG Card";
    begin
        Initialize();
        OpenCardOn(Card, 'H1');

        Assert.AreNotEqual(0, Probe.LinkFiredCount(), 'the link part''s OnAfterGetCurrRecord never ran');
        Assert.AreEqual('', Probe.LinkG0Line(), 'FilterGroup(0) GetFilter("Line No.") on the link part');
        Assert.AreEqual('', Probe.LinkG0Header(), 'FilterGroup(0) GetFilter("Header Code") on the link part');
        Card.Close();
    end;

    [Test]
    procedure LinkFilter_StillRestrictsThePartRows()
    var
        Probe: Codeunit "SPLG Probe";
        Card: TestPage "SPLG Card";
    begin
        Initialize();
        OpenCardOn(Card, 'H2');

        Assert.AreEqual(20000, Card.LinkPart."Line No.".AsInteger(), 'the link part shows H2''s selected line');
        Assert.AreEqual('20000', Probe.LinkG4Line(), 'FilterGroup(4) GetFilter("Line No.") follows the host row');
        Assert.AreEqual('H2', Probe.LinkG4Header(), 'FilterGroup(4) GetFilter("Header Code") follows the host row');
        Card.Close();
    end;

    [Test]
    procedure OwnGroup0Filter_CombinesWithTheLink()
    var
        Probe: Codeunit "SPLG Probe";
        Card: TestPage "SPLG Card";
    begin
        Initialize();
        OpenCardOn(Card, 'H1');

        Assert.IsTrue(Card.OwnPart.First(), 'the own-filter part has a first row');
        Assert.AreEqual(20000, Card.OwnPart."Line No.".AsInteger(), 'first row: H1 lines from 20000 on');
        Assert.IsTrue(Card.OwnPart.Next(), 'the own-filter part has a second row');
        Assert.AreEqual(30000, Card.OwnPart."Line No.".AsInteger(), 'second row: H1 30000');
        Assert.IsFalse(Card.OwnPart.Next(), 'no third row: H1 10000 fails the own filter, H2 rows fail the link');

        Assert.AreNotEqual(0, Probe.OwnFiredCount(), 'the own-filter part''s OnAfterGetCurrRecord never ran');
        Assert.AreEqual('>=20000', Probe.OwnG0Line(), 'FilterGroup(0) holds the part''s own filter');
        Assert.AreEqual('H1', Probe.OwnG4Header(), 'FilterGroup(4) holds the link');
        Assert.AreEqual('', Probe.OwnG4Line(), 'FilterGroup(4) holds no own filter');
        Card.Close();
    end;

    [Test]
    [HandlerFunctions('SplgCardModalHandler')]
    procedure LinkFilter_InAModalPageHandler_UnderFilterGroup4()
    var
        Header: Record "SPLG Header";
        Probe: Codeunit "SPLG Probe";
    begin
        Initialize();
        Header.Get('H1');
        Page.RunModal(Page::"SPLG Card", Header);

        Assert.AreNotEqual(0, Probe.LinkFiredCount(), 'the link part''s OnAfterGetCurrRecord never ran');
        Assert.AreEqual('10000', Probe.LinkG4Line(), 'FilterGroup(4) GetFilter("Line No.") on the modal page''s part');
        Assert.AreEqual('H1', Probe.LinkG4Header(), 'FilterGroup(4) GetFilter("Header Code") on the modal page''s part');
        Assert.AreEqual('', Probe.LinkG0Line(), 'FilterGroup(0) GetFilter("Line No.") on the modal page''s part');
    end;

    [ModalPageHandler]
    procedure SplgCardModalHandler(var Card: TestPage "SPLG Card")
    begin
        Assert.AreEqual(10000, Card.LinkPart."Line No.".AsInteger(), 'the modal page''s link part shows H1''s selected line');
    end;
}
