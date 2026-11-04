// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpagelink-property
// Scope: in-scope
// Fixtures used: TPRL Head (60462), TPRL Line (60463), TPRL Log (60464),
//                TPRL Line List (60465), TPRL Head Card (60466), TPRL Head List (60467),
//                Assert (60021)
//
// Pins what an action's RunPageLink does to the rowset its RunObject target opens on.
//
// TestPageActionRunObject_Tests already pins that invoking a RunObject action opens its target
// and reaches a handler. It says nothing about RunPageLink, and that is the shape a third of
// the Base Application's RunObject actions actually use: measured on Base Application 28.1's
// SymbolReference, 1,819 of the 5,668 action RunObject declarations carry a RunPageLink, and
// none of them carries RunPageOnRec at the same time.
//
// Four claims, each with something a plausible wrong implementation gets wrong:
//   1. A link FILTERS the target. LinesUnfiltered is the control on the same target from the
//      same host row, so "opened unfiltered" is a visible, different answer rather than an
//      unfalsifiable one.
//   2. The link kind is read, not guessed. const('H1') and filter('H1'|'H3') both select a
//      rowset the host page is NOT sitting on, so an implementation that answered every link
//      with "the host's current row" passes claim 1 and fails these.
//   3. The target opens POSITIONED on the first row of the filtered rowset, not on the table's
//      first row. Every arm records the row the target was already on at handler entry.
//   4. A link that selects nothing opens the target on an EMPTY rowset -- it does not fall back
//      to the unfiltered one, and it does not refuse.
//
// Every assertion names the rowset as a joined list of Descr values ('H2-L1,H2-L2'), not a
// count, so an implementation that filtered to the right NUMBER of wrong rows still fails.
codeunit 60468 "TPRL Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Head: Record "TPRL Head";
        Line: Record "TPRL Line";
        Log: Record "TPRL Log";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Log.DeleteAll();

        InsertHead('H1', 'Head One');
        InsertHead('H2', 'Head Two');
        InsertHead('H3', 'Head Three');
        // No lines at all -- the empty-rowset arm runs from this row.
        InsertHead('H4', 'Head Four');

        InsertLine('H1', 10, 'H1-L1');
        InsertLine('H1', 20, 'H1-L2');
        InsertLine('H2', 10, 'H2-L1');
        InsertLine('H2', 20, 'H2-L2');
        InsertLine('H3', 10, 'H3-L1');
    end;

    local procedure InsertHead(No: Code[20]; Descr: Text[50])
    var
        Head: Record "TPRL Head";
    begin
        Head.Init();
        Head."No." := No;
        Head.Descr := Descr;
        Head.Insert();
    end;

    local procedure InsertLine(HeadNo: Code[20]; LineNo: Integer; Descr: Text[50])
    var
        Line: Record "TPRL Line";
    begin
        Line.Init();
        Line."Head No." := HeadNo;
        Line."Line No." := LineNo;
        Line.Descr := Descr;
        Line.Insert();
    end;

    local procedure OpenHeadCardOn(No: Code[20]; var Host: TestPage "TPRL Head Card")
    var
        Head: Record "TPRL Head";
    begin
        Head.Get(No);
        Host.OpenEdit();
        Host.GotoRecord(Head);
    end;

    // CONTROL, and the arm that decides how to read every other failure here. The same target,
    // opened from the same host row by an action that differs ONLY in having no RunPageLink.
    // If this fails, the handler binding and the Log table are the problem and the arms below
    // say nothing about RunPageLink. If it passes and LinesByField fails, the difference is the
    // link alone.
    [Test]
    [HandlerFunctions('LineListPageHandler')]
    procedure ActionRunObject_NoRunPageLink_OpensTheWholeTable()
    var
        Log: Record "TPRL Log";
        Host: TestPage "TPRL Head Card";
    begin
        Initialize();

        OpenHeadCardOn('H2', Host);
        Host.LinesUnfiltered.Invoke();
        Host.Close();

        Assert.IsTrue(Log.Get('LINES'), 'the RunObject action must have opened its target page');
        Assert.AreEqual('H1-L1,H1-L2,H2-L1,H2-L2,H3-L1', Log.Detail,
            'an action with no RunPageLink must open its target on the whole table');
        Assert.AreEqual(5, Log."Row Count", 'the unfiltered target must show every line');
    end;

    // Claim 1 + 3: a field(...) link filters the target to the HOST's current row, and the
    // target is already positioned on the first row of that filtered rowset when the handler is
    // entered. The host sits on H2, so an implementation that opened the target unfiltered
    // reports the control's five rows and an implementation that filtered on the table's first
    // row reports H1's.
    [Test]
    [HandlerFunctions('LineListPageHandler')]
    procedure ActionRunPageLink_Field_FiltersTargetToTheHostsCurrentRow()
    var
        Log: Record "TPRL Log";
        Host: TestPage "TPRL Head Card";
    begin
        Initialize();

        OpenHeadCardOn('H2', Host);
        Host.LinesByField.Invoke();
        Host.Close();

        Assert.IsTrue(Log.Get('LINES'), 'the RunObject action must have opened its target page');
        Assert.AreEqual('H2-L1,H2-L2', Log.Detail,
            'RunPageLink = field("No.") must filter the target to the host page''s current row');
        Assert.AreEqual(2, Log."Row Count", 'only H2''s two lines are in the linked rowset');
        Assert.AreEqual('H2-L1', Log."Initial Row",
            'the target must open positioned on the first row of the LINKED rowset');
    end;

    // Claim 2: the SAME host row, the SAME target, a link that names a constant instead of a
    // host field. The host is on H2 and the link says H1, so this fails for any implementation
    // that reads "there is a link" and answers it with the host's row.
    [Test]
    [HandlerFunctions('LineListPageHandler')]
    procedure ActionRunPageLink_Const_FiltersTargetToTheLiteralNotTheHostsRow()
    var
        Log: Record "TPRL Log";
        Host: TestPage "TPRL Head Card";
    begin
        Initialize();

        OpenHeadCardOn('H2', Host);
        Host.LinesByConst.Invoke();
        Host.Close();

        Assert.IsTrue(Log.Get('LINES'), 'the RunObject action must have opened its target page');
        Assert.AreEqual('H1-L1,H1-L2', Log.Detail,
            'RunPageLink = const(''H1'') must filter to H1 even though the host sits on H2');
        Assert.AreEqual(2, Log."Row Count", 'only H1''s two lines are in the linked rowset');
        Assert.AreEqual('H1-L1', Log."Initial Row",
            'the target must open positioned on the first row of the const-linked rowset');
    end;

    // Claim 2, second kind: a filter(...) link is a filter EXPRESSION, not a single value, so it
    // selects two heads' lines at once. An implementation that treated every link as an equality
    // on the first alternative reports H1's two rows and misses H3-L1.
    [Test]
    [HandlerFunctions('LineListPageHandler')]
    procedure ActionRunPageLink_Filter_AppliesTheFilterExpression()
    var
        Log: Record "TPRL Log";
        Host: TestPage "TPRL Head Card";
    begin
        Initialize();

        OpenHeadCardOn('H2', Host);
        Host.LinesByFilter.Invoke();
        Host.Close();

        Assert.IsTrue(Log.Get('LINES'), 'the RunObject action must have opened its target page');
        Assert.AreEqual('H1-L1,H1-L2,H3-L1', Log.Detail,
            'RunPageLink = filter(''H1''|''H3'') must select both heads'' lines and nothing else');
        Assert.AreEqual(3, Log."Row Count", 'H2''s lines are excluded by the filter expression');
    end;

    // Claim 4, the negative direction: a link that matches nothing must open the target on an
    // EMPTY rowset. The two ways to get this wrong both produce a visibly different answer --
    // falling back to the unfiltered rowset reports 5, and refusing to open reports no Log row
    // at all.
    [Test]
    [HandlerFunctions('EmptyLineListPageHandler')]
    procedure ActionRunPageLink_Field_SelectingNothing_OpensAnEmptyTarget()
    var
        Log: Record "TPRL Log";
        Host: TestPage "TPRL Head Card";
    begin
        Initialize();

        OpenHeadCardOn('H4', Host);
        Host.LinesByField.Invoke();
        Host.Close();

        Assert.IsTrue(Log.Get('LINES'),
            'a RunPageLink that selects nothing must still open the target page');
        Assert.AreEqual(0, Log."Row Count", 'H4 has no lines, so the linked rowset is empty');
        Assert.AreEqual('', Log.Detail, 'an empty linked rowset must not fall back to the whole table');
    end;

    // The one shape that declares RunPageLink and RunPageOnRec together. Zero of Base
    // Application 28.1's 5,668 RunObject actions do, so this arm exists to say what the
    // combination means at all rather than to mirror a common pattern: the link and the record
    // agree here, and the target shows exactly the host's row.
    [Test]
    [HandlerFunctions('HeadListPageHandler')]
    procedure ActionRunPageLink_WithRunPageOnRec_OpensTheHostsRowOnly()
    var
        Log: Record "TPRL Log";
        Host: TestPage "TPRL Head Card";
    begin
        Initialize();

        OpenHeadCardOn('H3', Host);
        Host.HeadsByFieldOnRec.Invoke();
        Host.Close();

        Assert.IsTrue(Log.Get('HEADS'), 'the RunObject action must have opened its target page');
        Assert.AreEqual('Head Three', Log.Detail,
            'RunPageLink and RunPageOnRec together must show the host''s current row alone');
        Assert.AreEqual(1, Log."Row Count",
            'the link restricts the target to one row, so the other three heads are excluded');
    end;

    // Used by every arm whose linked rowset is NON-EMPTY, because its first statement reads the
    // target's current row before moving anything -- which is only meaningful, and only legal,
    // when there is a row to read. The empty arm uses EmptyLineListPageHandler instead.
    [PageHandler]
    procedure LineListPageHandler(var Target: TestPage "TPRL Line List")
    var
        Log: Record "TPRL Log";
        RowCount: Integer;
        Joined: Text;
        InitialRow: Text;
    begin
        // Read BEFORE any First()/Next(): this is the row the platform positioned the target on
        // when it opened it, which is a separate claim from which rows the link selected.
        InitialRow := Target.Descr.Value();

        if Target.First() then
            repeat
                RowCount += 1;
                if Joined <> '' then
                    Joined += ',';
                Joined += Target.Descr.Value();
            until not Target.Next();

        Log.Init();
        Log.Entry := 'LINES';
        Log."Row Count" := RowCount;
        Log.Detail := CopyStr(Joined, 1, MaxStrLen(Log.Detail));
        Log."Initial Row" := CopyStr(InitialRow, 1, MaxStrLen(Log."Initial Row"));
        if not Log.Insert() then
            Log.Modify();
    end;

    // The empty-rowset arm's handler. Separate from LineListPageHandler because that one reads
    // the current row before moving, and an empty page has none to read.
    [PageHandler]
    procedure EmptyLineListPageHandler(var Target: TestPage "TPRL Line List")
    var
        Log: Record "TPRL Log";
        RowCount: Integer;
        Joined: Text;
    begin
        if Target.First() then
            repeat
                RowCount += 1;
                if Joined <> '' then
                    Joined += ',';
                Joined += Target.Descr.Value();
            until not Target.Next();

        Log.Init();
        Log.Entry := 'LINES';
        Log."Row Count" := RowCount;
        Log.Detail := CopyStr(Joined, 1, MaxStrLen(Log.Detail));
        if not Log.Insert() then
            Log.Modify();
    end;

    [PageHandler]
    procedure HeadListPageHandler(var Target: TestPage "TPRL Head List")
    var
        Log: Record "TPRL Log";
        RowCount: Integer;
        Joined: Text;
    begin
        if Target.First() then
            repeat
                RowCount += 1;
                if Joined <> '' then
                    Joined += ',';
                Joined += Target.Descr.Value();
            until not Target.Next();

        Log.Init();
        Log.Entry := 'HEADS';
        Log."Row Count" := RowCount;
        Log.Detail := CopyStr(Joined, 1, MaxStrLen(Log.Detail));
        if not Log.Insert() then
            Log.Modify();
    end;
}
