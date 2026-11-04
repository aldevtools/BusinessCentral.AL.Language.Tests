// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpagelink-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-filtergroup-method
// Scope: in-scope
// Fixtures used: ARLG Row (60978), ARLG Host (60984), ARLG Target (60985),
//                ARLG Probe (60939), Assert (60021)
//
/// <summary>
/// Pins WHICH filter group an ACTION's RunPageLink filters land in on the opened page's Rec.
///
/// This is the sibling of TestPagePartLinkFilterGroup.al, which pins the same question for a
/// part's SubPageLink (group 4, "Link"). Nothing upstream covers the action/RunPageLink side:
/// no corpus file mentions RunPageLink and FilterGroup together.
///
/// MEASURED, and it is NOT the same group as SubPageLink. Real BC puts the filter in
/// FilterGroup(0):
///
///     g0=AAA|g2=|g4=          (8 cloud legs, corpus run 34930362542)
///
/// That is worth pinning precisely because the analogy tempts the other answer. A part's
/// SubPageLink lands in group 4 ("Link") and Base Application reads it back with
/// Rec.FilterGroup(4) -- see TestPagePartLinkFilterGroup.al. An action's RunPageLink does not
/// follow that pattern, so code that assumes symmetry between the two is wrong about one of
/// them.
///
/// Written for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4160, which predicted
/// group 4 by that analogy and said plainly it had not checked which group the compiler writes
/// on RunFormLink.TableFilters. It had not, and the prediction was wrong: the runner's existing
/// behaviour (filters in the current group, 0) already matches BC.
///
/// THE PROBE READS THREE GROUPS and both arms assert all three in ONE string, so a failure
/// names the group that actually holds the filter rather than only reporting that the expected
/// one does not. The first version of these arms asserted each group separately, which stopped
/// at the first failure and could not say where the filter had gone -- the question the test
/// exists to answer.
/// </summary>

table 60978 "ARLG Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Payload; Text[20]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

codeunit 60939 "ARLG Probe"
{
    SingleInstance = true;

    var
        G0: Text;
        G2: Text;
        G4: Text;
        Opened: Boolean;

    procedure Reset()
    begin
        G0 := '';
        G2 := '';
        G4 := '';
        Opened := false;
    end;

    procedure Record(NewG0: Text; NewG2: Text; NewG4: Text)
    begin
        G0 := NewG0;
        G2 := NewG2;
        G4 := NewG4;
        Opened := true;
    end;

    procedure WasOpened(): Boolean
    begin
        exit(Opened);
    end;

    procedure Group0(): Text
    begin
        exit(G0);
    end;

    procedure Group2(): Text
    begin
        exit(G2);
    end;

    procedure Group4(): Text
    begin
        exit(G4);
    end;
}

page 60985 "ARLG Target"
{
    PageType = List;
    SourceTable = "ARLG Row";
    ApplicationArea = All;
    Caption = 'ARLG Target';

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
            }
        }
    }

    // Read the filter the action's RunPageLink left, in each candidate group, and hand all
    // three to the probe. Reading them here rather than asserting here keeps the page a
    // fixture: the arms decide what the values mean.
    trigger OnOpenPage()
    var
        Probe: Codeunit "ARLG Probe";
        F0: Text;
        F2: Text;
        F4: Text;
    begin
        Rec.FilterGroup(0);
        F0 := Rec.GetFilter("Code");
        Rec.FilterGroup(2);
        F2 := Rec.GetFilter("Code");
        Rec.FilterGroup(4);
        F4 := Rec.GetFilter("Code");
        Rec.FilterGroup(0);
        Probe.Record(F0, F2, F4);
    end;
}

page 60984 "ARLG Host"
{
    PageType = Card;
    SourceTable = "ARLG Row";
    ApplicationArea = All;
    Caption = 'ARLG Host';

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenTarget)
            {
                ApplicationArea = All;
                Caption = 'Open Target';
                RunObject = page "ARLG Target";
                RunPageLink = "Code" = field("Code");
            }
        }
    }
}

codeunit 60941 "ARLG Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Seed()
    var
        Row: Record "ARLG Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."Code" := 'AAA';
        Row.Payload := 'first';
        Row.Insert();
        Row.Init();
        Row."Code" := 'BBB';
        Row.Payload := 'second';
        Row.Insert();
    end;

    local procedure InvokeTheAction(HostCode: Code[20])
    var
        Probe: Codeunit "ARLG Probe";
        Host: TestPage "ARLG Host";
    begin
        Seed();
        Probe.Reset();

        Host.OpenEdit();
        Host.GoToKey(HostCode);
        Host.OpenTarget.Invoke();
        Host.Close();
    end;

    [Test]
    [HandlerFunctions('ArlgTargetHandler')]
    procedure RunPageLink_FilterLandsInGroup0_NotTheLinkGroup()
    // THE SUBJECT. The three groups are read in one open, so this arm says not just "is it in
    // 4" but "which of the three has it" -- and the two companion assertions are what rule out
    // the runner's current answer (group 0) and the remaining candidate (group 2).
    var
        Probe: Codeunit "ARLG Probe";
    begin
        InvokeTheAction('AAA');

        Assert.IsTrue(Probe.WasOpened(), 'The action must have opened the target page, or the filter assertions below mean nothing.');

        // ONE assertion carrying ALL THREE groups, deliberately. Asserting them separately
        // stops at the first failure and reports only that one group was wrong -- which is
        // precisely the question this test exists to answer, so the message has to survive it.
        // The expected string names the group BC is claimed to use; the actual string says
        // where the filter really is.
        Assert.AreEqual(
            'g0=AAA|g2=|g4=',
            'g0=' + Probe.Group0() + '|g2=' + Probe.Group2() + '|g4=' + Probe.Group4(),
            'An action''s RunPageLink filter lands in FilterGroup(0), NOT the Link group a part''s SubPageLink uses.');
    end;

    [Test]
    [HandlerFunctions('ArlgTargetHandler')]
    procedure RunPageLink_FilterFollowsTheHostRow()
    // The link is a FIELD reference, so a different host row must produce a different filter.
    // Without this, the arm above would also pass against an implementation that hardcoded the
    // first row's value, or that applied a constant.
    var
        Probe: Codeunit "ARLG Probe";
    begin
        InvokeTheAction('BBB');

        Assert.IsTrue(Probe.WasOpened(), 'The action must have opened the target page.');
        Assert.AreEqual(
            'g0=BBB|g2=|g4=',
            'g0=' + Probe.Group0() + '|g2=' + Probe.Group2() + '|g4=' + Probe.Group4(),
            'The RunPageLink filter carries the host row''s own Code, in FilterGroup(0).');
    end;

    [PageHandler]
    procedure ArlgTargetHandler(var TargetPage: TestPage "ARLG Target")
    begin
        // The page's own OnOpenPage has already recorded the three filters by the time this
        // runs. Closing is all this handler needs to do.
        TargetPage.Close();
    end;

    // Writer QZ: Rec of the target page during OnOpenPage after an action's RunPageLink (fixtures in QzRunPageLinkOnOpen.al).
    // P1/7 has child lines 1 and 2; P2/1 has no child line; a line of P1/8 exists to show the second link field filters.
    local procedure QzSeed(var Card: TestPage "LT QZ RL Parent Card"; ParentCode: Code[20]; ParentNumber: Integer)
    var
        Parent: Record "LT QZ RL Parent";
        Child: Record "LT QZ RL Child";
        Log: Codeunit "LT QZ RL Log";
    begin
        Parent.DeleteAll();
        Child.DeleteAll();
        Parent.Code := 'P1';
        Parent.Number := 7;
        Parent.Insert();
        Parent.Code := 'P2';
        Parent.Number := 1;
        Parent.Insert();
        QzChild('P1', 7, 1, 'one');
        QzChild('P1', 7, 2, 'two');
        QzChild('P1', 8, 1, 'other number');
        Card.OpenEdit();
        Parent.Get(ParentCode, ParentNumber);
        Card.GoToRecord(Parent);
        Log.Clear();
    end;

    local procedure QzChild(ParentCode: Code[20]; ParentNumber: Integer; LineNo: Integer; Note: Text[30])
    var
        Child: Record "LT QZ RL Child";
    begin
        Child.ParentCode := ParentCode;
        Child.ParentNumber := ParentNumber;
        Child.LineNo := LineNo;
        Child.Note := Note;
        Child.Insert();
    end;

    [Test]
    [HandlerFunctions('QzChildListHandler')]
    procedure QZ_RunPageLink_RecInOnOpenPage_List_Handler()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QZ RL Log";
        Card: TestPage "LT QZ RL Parent Card";
    begin
        QzSeed(Card, 'P1', 7);
        Card.ChildList.Invoke();
        Observer.Observe('rows', Log.Get());
        Log.Clear();
        Card.Close();
        QzSeed(Card, 'P2', 1);
        Card.ChildList.Invoke();
        Observer.Observe('no rows', Log.Get());
        Card.Close();
        Observer.Expect('rows', 'list open code=P1 number=7 line=0 note= filters=;list agcr code=P1 number=7 line=1 note=one filters=;handler line=1 note=one;');
        Observer.Expect('no rows', 'list open code=P2 number=1 line=0 note= filters=;list agcr code=P2 number=1 line=0 note= filters=;list agcr code=P2 number=1 line=0 note= filters=;handler line=0 note=;');
        Observer.Verify();
    end;

    [Test]
    procedure QZ_RunPageLink_RecInOnOpenPage_List_Trap()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QZ RL Log";
        Card: TestPage "LT QZ RL Parent Card";
        List: TestPage "LT QZ RL Child List";
    begin
        QzSeed(Card, 'P1', 7);
        List.Trap();
        Card.ChildList.Invoke();
        Observer.Observe('log', Log.Get());
        Observer.Observe('trapped line', List.LineNo.Value() + '|' + List.Note.Value());
        List.Close();
        Card.Close();
        Observer.Expect('log', 'list open code=P1 number=7 line=0 note= filters=;list agcr code=P1 number=7 line=1 note=one filters=;');
        Observer.Expect('trapped line', '1|one');
        Observer.Verify();
    end;

    [Test]
    procedure QZ_RunPageLink_RecInOnOpenPage_Card_Trap()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QZ RL Log";
        Card: TestPage "LT QZ RL Parent Card";
        ChildCard: TestPage "LT QZ RL Child Card";
    begin
        QzSeed(Card, 'P1', 7);
        ChildCard.Trap();
        Card.ChildCard.Invoke();
        Observer.Observe('log', Log.Get());
        Observer.Observe('trapped line', ChildCard.LineNo.Value() + '|' + ChildCard.Note.Value());
        ChildCard.Close();
        Card.Close();
        Observer.Expect('log', 'card open code=P1 number=7 line=0 note= filters=;card agcr code=P1 number=7 line=1 note=one filters=;');
        Observer.Expect('trapped line', '1|one');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QzChildListHandler')]
    procedure QZ_RunPageLink_RecInOnOpenPage_Const()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QZ RL Log";
        Card: TestPage "LT QZ RL Parent Card";
    begin
        QzSeed(Card, 'P2', 1);
        Card.ChildListConst.Invoke();
        Observer.Observe('log', Log.Get());
        Card.Close();
        Observer.Expect('log', 'list open code=P1 number=7 line=0 note= filters=;list agcr code=P1 number=7 line=1 note=one filters=;handler line=1 note=one;');
        Observer.Verify();
    end;

    [Test]
    procedure QZ_RunPageLink_RecInOnOpenPage_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QZ RL Log";
        Card: TestPage "LT QZ RL Parent Card";
    begin
        QzSeed(Card, 'P1', 7);
        ClearLastError();
        asserterror begin
            Card.ChildList.Invoke();
            Error('no error');
        end;
        Observer.ObserveError('invoke');
        Observer.Observe('log', Log.Get());
        Observer.Expect('invoke|text', 'no error');
        Observer.Expect('invoke|code', 'Dialog');
        Observer.Expect('log', 'list open code=P1 number=7 line=0 note= filters=;');
        Observer.Verify();
    end;

    [PageHandler]
    procedure QzChildListHandler(var ChildList: TestPage "LT QZ RL Child List")
    var
        Log: Codeunit "LT QZ RL Log";
    begin
        Log.Add('handler line=' + ChildList.LineNo.Value() + ' note=' + ChildList.Note.Value());
        ChildList.Close();
    end;
}
