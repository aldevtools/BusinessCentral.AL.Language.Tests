// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-showastree-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y28CollapsedTreeObjects.al (table 92270, log codeunit 92271, pages 92272 - 92274)
// Probe: al-runner issue 6523. What the AL code of a collapsed tree page (ShowAsTree, TreeInitialState = CollapseAll) sees of Rec, and
//   which rows the TestPage shows after that code resets, walks, filters or moves Rec. Each walk lists Id:Name of First/Next.
// Neighbours: PageTree.al (the plain collapsed walk), pages/lt-ah-pages/AhPageTests.al (Expand, IsExpanded and GoToKey of a child on a
//   collapsed tree), pages/lt-page-runtime/TwTreeExpandTriggers.al (Expand with row triggers on an ExpandAll tree).
// BC versions: 27, 28, 29

codeunit 92279 "LT Y28 Collapsed Tree Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y28 Tree Log";

    [Test]
    procedure Y28_CollapsedOpenAndWalk()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT Y28 Collapsed Tree";
    begin
        Start('');
        P.OpenView();
        Observer.Observe('open-log', Log.Take());
        Observer.Observe('current', P.IdCtl.Value());
        Observer.Observe('testpage-filter-indent', P.Filter.GetFilter(Indent));
        Observer.Observe('walk', Walk(P));
        Observer.Observe('walk-log', Log.Take());
        Observer.Observe('last', Format(P.Last()) + '/' + P.IdCtl.Value());
        Observer.Observe('previous', Format(P.Previous()) + '/' + P.IdCtl.Value());
        Observer.Observe('previous-2', Format(P.Previous()) + '/' + P.IdCtl.Value());
        Observer.Expect('open-log', 'open count=5 filters= fg0[] copy=5/1,2,3,4,5,;open-end count=5 filters=;agr1;agr2;agr3;agr4;agr5;agr1;agr1;agcr1 n=5;');
        Observer.Expect('current', '1');
        Observer.Expect('testpage-filter-indent', '');
        Observer.Expect('walk', '1:Root 1,4:Root 2,');
        Observer.Expect('walk-log', 'agr4;agr4;agcr4 n=5;');
        Observer.Expect('last', 'Yes/4');
        Observer.Expect('previous', 'Yes/1');
        Observer.Expect('previous-2', 'No/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y28_ResetInOnOpenPage()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT Y28 Collapsed Tree";
    begin
        Start('reset');
        P.OpenView();
        Observer.Observe('open-log', Log.Take());
        Observer.Observe('current', P.IdCtl.Value());
        Observer.Observe('walk', Walk(P));
        Observer.Expect('open-log', 'open count=5 filters= fg0[] copy=5/1,2,3,4,5,;open-end count=5 filters=;agr1;agr2;agr3;agr4;agr5;agr1;agr1;agcr1 n=5;');
        Observer.Expect('current', '1');
        Observer.Expect('walk', '1:Root 1,4:Root 2,');
        Observer.Verify();
    end;

    [Test]
    procedure Y28_FindSetInOnOpenPage()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT Y28 Collapsed Tree";
    begin
        Start('findset');
        P.OpenView();
        Observer.Observe('open-log', Log.Take());
        Observer.Observe('current', P.IdCtl.Value());
        Observer.Observe('walk', Walk(P));
        Observer.Expect('open-log', 'open count=5 filters= fg0[] copy=5/1,2,3,4,5,;fs1;fs2;fs3;fs4;fs5;open-end count=5 filters=;agr5;agr4;agr3;agr2;agr1;agr5;agr5;agcr5 n=5;');
        Observer.Expect('current', '5');
        Observer.Expect('walk', '1:Root 1,4:Root 2,5:Child 2A,');
        Observer.Verify();
    end;

    [Test]
    procedure Y28_SetRangeChildrenInOnOpenPage()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT Y28 Collapsed Tree";
    begin
        Start('setrange1');
        P.OpenView();
        Observer.Observe('open-log', Log.Take());
        Observer.Observe('current', P.IdCtl.Value());
        Observer.Observe('walk', Walk(P));
        Observer.Expect('open-log', 'open count=5 filters= fg0[] copy=5/1,2,3,4,5,;open-end count=3 filters=Indent: 1;agr2;agr3;agr5;agr2;agr2;agcr2 n=3;');
        Observer.Expect('current', '2');
        Observer.Expect('walk', '2:Child 1A,3:Child 1B,5:Child 2A,');
        Observer.Verify();
    end;

    [Test]
    procedure Y28_GetChildInOnOpenPage()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT Y28 Collapsed Tree";
    begin
        Start('get2');
        P.OpenView();
        Observer.Observe('open-log', Log.Take());
        Observer.Observe('current', P.IdCtl.Value());
        Observer.Observe('walk', Walk(P));
        Observer.Expect('open-log', 'open count=5 filters= fg0[] copy=5/1,2,3,4,5,;get2=Yes;open-end count=5 filters=;agr2;agr3;agr4;agr5;agr2;agr1;agr2;agr2;agcr2 n=5;');
        Observer.Expect('current', '2');
        Observer.Expect('walk', '1:Root 1,2:Child 1A,3:Child 1B,4:Root 2,');
        Observer.Verify();
    end;

    [Test]
    procedure Y28_ActionCountOnRoot()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT Y28 Collapsed Tree";
    begin
        Start('');
        P.OpenView();
        P.Last();
        Log.Take();
        P.CountAct.Invoke();
        Observer.Observe('action-log', Log.Take());
        Observer.Observe('current', P.IdCtl.Value());
        Observer.Expect('action-log', 'agr4;act cur=4 count=5 filters= fg0[] copy=5/1,2,3,4,5,;sel count=1 filters=Id: 4 fg0[0:Id: 4|] copy=1/4,;agr4;agr4;agr5;agr4;agr3;agr2;agr1;agr4;agr4;agcr4 n=5;');
        Observer.Expect('current', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Y28_ActionCountOnExpandedChild()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT Y28 Collapsed Tree";
    begin
        Start('');
        P.OpenView();
        P.First();
        P.Expand(true);
        Observer.Observe('next', Format(P.Next()) + '/' + P.IdCtl.Value());
        Log.Take();
        P.CountAct.Invoke();
        Observer.Observe('action-log', Log.Take());
        Observer.Observe('walk', Walk(P));
        Observer.Expect('next', 'Yes/2');
        Observer.Expect('action-log', 'agr2;act cur=2 count=5 filters= fg0[] copy=5/1,2,3,4,5,;sel count=1 filters=Id: 2 fg0[0:Id: 2|] copy=1/2,;agr2;agr2;agr3;agr4;agr5;agr2;agr1;agr2;agr2;agcr2 n=5;');
        Observer.Expect('walk', '1:Root 1,2:Child 1A,3:Child 1B,4:Root 2,');
        Observer.Verify();
    end;

    [Test]
    procedure Y28_ActionResetAndUpdate()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT Y28 Collapsed Tree";
    begin
        Start('');
        P.OpenView();
        P.First();
        Log.Take();
        P.ResetAct.Invoke();
        Observer.Observe('action-log', Log.Take());
        Observer.Observe('current', P.IdCtl.Value());
        Observer.Observe('walk', Walk(P));
        Observer.Expect('action-log', 'agr1;reset count=5;agr1;agr1;agr2;agr3;agr4;agr5;agr1;agr1;agcr1 n=5;');
        Observer.Expect('current', '1');
        Observer.Expect('walk', '1:Root 1,4:Root 2,');
        Observer.Verify();
    end;

    [Test]
    procedure Y28_ActionGetChildAndUpdate()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT Y28 Collapsed Tree";
    begin
        Start('');
        P.OpenView();
        P.First();
        Log.Take();
        P.GoChildAct.Invoke();
        Observer.Observe('action-log', Log.Take());
        Observer.Observe('current', P.IdCtl.Value());
        Observer.Observe('walk', Walk(P));
        Observer.Expect('action-log', 'agr1;get2=Yes;agr2;agr2;agr3;agr4;agr5;agr2;agr1;agr2;agr2;agcr2 n=5;');
        Observer.Expect('current', '2');
        Observer.Expect('walk', '1:Root 1,2:Child 1A,3:Child 1B,4:Root 2,');
        Observer.Verify();
    end;

    [Test]
    procedure Y28_GoToRecordChild()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y28 Tree Row";
        P: TestPage "LT Y28 Collapsed Tree";
        Found: Boolean;
    begin
        Start('');
        P.OpenView();
        P.Last();
        Row.Get(2);
        if TryGoToRecord(P, Row, Found) then
            Observer.Observe('goto-child', Format(Found))
        else
            Observer.ObserveError('goto-child-error');
        Observer.Observe('current-after-child', P.IdCtl.Value());
        Row.Get(1);
        if TryGoToRecord(P, Row, Found) then
            Observer.Observe('goto-root', Format(Found))
        else
            Observer.ObserveError('goto-root-error');
        Observer.Observe('current-after-root', P.IdCtl.Value());
        Observer.Expect('goto-child', 'No');
        Observer.Expect('current-after-child', '4');
        Observer.Expect('goto-root', 'Yes');
        Observer.Expect('current-after-root', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y28_FindFirstFieldChild()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT Y28 Collapsed Tree";
    begin
        Start('');
        P.OpenView();
        P.Last();
        Observer.Observe('find-child', Format(P.FindFirstField(NameCtl, 'Child 1A')));
        Observer.Observe('current-after-child', P.IdCtl.Value());
        Observer.Observe('find-root', Format(P.FindFirstField(NameCtl, 'Root 1')));
        Observer.Observe('current-after-root', P.IdCtl.Value());
        Observer.Expect('find-child', 'No');
        Observer.Expect('current-after-child', '4');
        Observer.Expect('find-root', 'Yes');
        Observer.Expect('current-after-root', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y28_TestPageFilterOnChildren()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT Y28 Collapsed Tree";
    begin
        Start('');
        P.OpenView();
        Log.Take();
        P.Filter.SetFilter(Indent, '1');
        Observer.Observe('filter-log', Log.Take());
        Observer.Observe('walk-indent-1', Walk(P));
        P.Filter.SetFilter(Indent, '');
        P.Filter.SetFilter(Id, '2..4');
        Observer.Observe('walk-id-2-4', Walk(P));
        Observer.Expect('filter-log', 'agr2;agr3;agr5;agr2;agr2;agcr2 n=3;');
        Observer.Expect('walk-indent-1', '2:Child 1A,3:Child 1B,5:Child 2A,');
        Observer.Expect('walk-id-2-4', '2:Child 1A,3:Child 1B,4:Root 2,');
        Observer.Verify();
    end;

    [Test]
    procedure Y28_ExpandAllOpenAndWalk()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT Y28 Expanded Tree";
        Names: Text;
    begin
        Start('');
        P.OpenView();
        Observer.Observe('open-log', Log.Take());
        Observer.Observe('current', P.IdCtl.Value());
        if P.First() then
            repeat
                Names += P.IdCtl.Value() + ':' + P.NameCtl.Value() + ',';
            until not P.Next();
        Observer.Observe('walk', Names);
        P.First();
        Observer.Observe('first-expanded', Format(P.IsExpanded()));
        Observer.Expect('open-log', 'open count=5 filters= fg0[];');
        Observer.Expect('current', '1');
        Observer.Expect('walk', '1:Root 1,4:Root 2,');
        Observer.Expect('first-expanded', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Y28_VariableIndentationColumn()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT Y28 Var Indent Tree";
        Names: Text;
    begin
        Start('');
        P.OpenView();
        Observer.Observe('open-log', Log.Take());
        Observer.Observe('current', P.IdCtl.Value());
        if P.First() then
            repeat
                Names += P.IdCtl.Value() + ':' + P.NameCtl.Value() + ',';
            until not P.Next();
        Observer.Observe('walk', Names);
        P.First();
        Observer.Observe('first-expanded', Format(P.IsExpanded()));
        Observer.Expect('open-log', 'open count=5;agr1;agr2;agr3;agr4;agr5;agr1;');
        Observer.Expect('current', '1');
        Observer.Expect('walk', '1:Root 1,4:Root 2,');
        Observer.Expect('first-expanded', 'No');
        Observer.Verify();
    end;

    local procedure Start(Mode: Text)
    var
        Row: Record "LT Y28 Tree Row";
    begin
        Log.SetMode(Mode);
        Log.Take();
        Row.DeleteAll();
        AddRow(1, 'Root 1', 0);
        AddRow(2, 'Child 1A', 1);
        AddRow(3, 'Child 1B', 1);
        AddRow(4, 'Root 2', 0);
        AddRow(5, 'Child 2A', 1);
    end;

    local procedure AddRow(NewId: Integer; NewName: Text[30]; NewIndent: Integer)
    var
        Row: Record "LT Y28 Tree Row";
    begin
        Row.Init();
        Row.Id := NewId;
        Row.Name := NewName;
        Row.Indent := NewIndent;
        Row.Insert();
    end;

    local procedure Walk(var P: TestPage "LT Y28 Collapsed Tree") Result: Text
    begin
        if P.First() then
            repeat
                Result += P.IdCtl.Value() + ':' + P.NameCtl.Value() + ',';
            until not P.Next();
    end;

    [TryFunction]
    local procedure TryGoToRecord(var P: TestPage "LT Y28 Collapsed Tree"; Row: Record "LT Y28 Tree Row"; var Found: Boolean)
    begin
        Found := P.GoToRecord(Row);
    end;
}
