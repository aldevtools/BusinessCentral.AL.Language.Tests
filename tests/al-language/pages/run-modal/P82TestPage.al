// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P82 List (71188), LT P82 Card (71187), LT P82 Tree (71189), LT P82 Host (71191), LT P82 Sub (71190), LT P82 Item (71184), LT P82 Group (71192), LT P82 Log (71186) from P82Fixtures.al
// Probe: written against BC 29 (runtime 16); the facts are measured later
// Facts: TestPage navigation (First / Next / Previous / Last / GoToKey / GoToRecord with misses and several key values), Filter.SetFilter on fields and views, Caption, Expand / IsExpanded on a tree, TestPart Visible / Enabled / Editable and rows
// BC versions: 29

codeunit 71204 "LT P82 TestPage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Item: Record "LT P82 Item";
        Grp: Record "LT P82 Group";
        Log: Codeunit "LT P82 Log";
        I: Integer;
    begin
        Item.DeleteAll();
        Grp.DeleteAll();
        Log.Reset();
        Grp.Code := 'G1';
        Grp.Descr := 'Group one';
        Grp.Insert();
        Grp.Code := 'G2';
        Grp.Descr := 'Group two';
        Grp.Insert();
        for I := 1 to 5 do begin
            Item."No." := 'N' + Format(I);
            Item.Name := 'Name ' + Format(I);
            Item.Qty := I * 10;
            Item.Amount := I / 4;
            Item.Grp := 'G' + Format((I mod 2) + 1);
            Item.Indent := 0;
            Item.Insert();
        end;
    end;

    [Test]
    procedure Navigation_FirstNextPreviousLast()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P82 List";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('first', Format(List.First()));
        Observer.Observe('first-no', List.NoCtl.Value());
        Observer.Observe('previous-at-first', Format(List.Previous()));
        Observer.Observe('no-after-failed-previous', List.NoCtl.Value());
        Observer.Observe('next', Format(List.Next()));
        Observer.Observe('next-no', List.NoCtl.Value());
        Observer.Observe('last', Format(List.Last()));
        Observer.Observe('last-no', List.NoCtl.Value());
        Observer.Observe('next-at-last', Format(List.Next()));
        Observer.Observe('no-after-failed-next', List.NoCtl.Value());
        Observer.Observe('previous', Format(List.Previous()));
        Observer.Observe('previous-no', List.NoCtl.Value());
        List.Close();
        Observer.Expect('first', 'Yes');
        Observer.Expect('first-no', 'N1');
        Observer.Expect('previous-at-first', 'No');
        Observer.Expect('no-after-failed-previous', 'N1');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next-no', 'N2');
        Observer.Expect('last', 'Yes');
        Observer.Expect('last-no', 'N5');
        Observer.Expect('next-at-last', 'No');
        Observer.Expect('no-after-failed-next', 'N5');
        Observer.Expect('previous', 'Yes');
        Observer.Expect('previous-no', 'N4');
        Observer.Verify();
    end;

    [Test]
    procedure Navigation_GoToKey()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P82 List";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('hit', Format(List.GoToKey('N3')));
        Observer.Observe('hit-no', List.NoCtl.Value());
        Observer.Observe('miss', Format(List.GoToKey('ZZ')));
        Observer.Observe('no-after-miss', List.NoCtl.Value());
        Observer.Observe('empty-key', Format(List.GoToKey('')));
        Observer.Observe('no-after-empty', List.NoCtl.Value());
        Observer.Observe('lowercase', Format(List.GoToKey('n2')));
        Observer.Observe('lowercase-no', List.NoCtl.Value());
        Observer.Observe('backwards', Format(List.GoToKey('N1')));
        Observer.Observe('backwards-no', List.NoCtl.Value());
        asserterror List.GoToKey('N1', 'extra');
        Observer.ObserveError('too-many-key-values');
        asserterror List.GoToKey(1);
        Observer.ObserveError('wrong-type');
        List.Close();
        Observer.Expect('hit', 'Yes');
        Observer.Expect('hit-no', 'N3');
        Observer.Expect('miss', 'No');
        Observer.Expect('no-after-miss', 'N3');
        Observer.Expect('empty-key', 'No');
        Observer.Expect('no-after-empty', 'N3');
        Observer.Expect('lowercase', 'No');
        Observer.Expect('lowercase-no', 'N3');
        Observer.Expect('backwards', 'Yes');
        Observer.Expect('backwards-no', 'N1');
        Observer.Expect('too-many-key-values|text', 'The number of arguments does not match the number of primary key fields.');
        Observer.Expect('too-many-key-values|code', 'TestInvalidNumberOfKeyFieldValues');
        Observer.Expect('wrong-type|text', 'The row does not exist on the TestPage.');
        Observer.Expect('wrong-type|code', 'TestRowNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Navigation_GoToRecord()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P82 Item";
        List: TestPage "LT P82 List";
    begin
        Seed();
        List.OpenView();
        Item.Get('N4');
        Observer.Observe('hit', Format(List.GoToRecord(Item)));
        Observer.Observe('hit-no', List.NoCtl.Value());
        Item."No." := 'NOPE';
        Observer.Observe('miss', Format(List.GoToRecord(Item)));
        Observer.Observe('no-after-miss', List.NoCtl.Value());
        Clear(Item);
        Observer.Observe('cleared-record', Format(List.GoToRecord(Item)));
        Item.Get('N2');
        Item.Name := 'Different name';
        Observer.Observe('key-only-match', Format(List.GoToRecord(Item)));
        Observer.Observe('key-only-no', List.NoCtl.Value());
        List.Close();
        Observer.Expect('hit', 'Yes');
        Observer.Expect('hit-no', 'N4');
        Observer.Expect('miss', 'No');
        Observer.Expect('no-after-miss', 'N4');
        Observer.Expect('cleared-record', 'No');
        Observer.Expect('key-only-match', 'Yes');
        Observer.Expect('key-only-no', 'N2');
        Observer.Verify();
    end;

    [Test]
    procedure Filter_SetFilter_Fields()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P82 List";
        N: Integer;
    begin
        Seed();
        List.OpenView();
        List.Filter.SetFilter(Qty, '20..40');
        if List.First() then
            repeat
                N += 1;
                Observer.Observe('range-row' + Format(N), List.NoCtl.Value());
            until not List.Next();
        List.Filter.SetFilter(Qty, '');
        Observer.Observe('count-after-clear', Format(CountRows(List)));
        List.Filter.SetFilter(Name, '*3|*5');
        Observer.Observe('count-name-or', Format(CountRows(List)));
        List.Filter.SetFilter(Name, 'Name 1');
        Observer.Observe('count-name-exact', Format(CountRows(List)));
        List.Filter.SetFilter(Qty, '>1000');
        Observer.Observe('count-none', Format(CountRows(List)));
        Observer.Observe('first-none', Format(List.First()));
        asserterror List.Filter.SetFilter(Qty, 'abc');
        Observer.ObserveError('invalid-integer-filter');
        List.Close();
        Observer.Expect('range-row1', 'N2');
        Observer.Expect('range-row2', 'N3');
        Observer.Expect('range-row3', 'N4');
        Observer.Expect('count-after-clear', '5');
        Observer.Expect('count-name-or', '2');
        Observer.Expect('count-name-exact', '1');
        Observer.Expect('count-none', '0');
        Observer.Expect('first-none', 'No');
        Observer.Expect('invalid-integer-filter|text', 'The filter "abc" is not valid for the Qty field on the LT P82 Item table. The value "abc" can''t be evaluated into type Integer.');
        Observer.Expect('invalid-integer-filter|code', 'Filter:CSide');
        Observer.Verify();
    end;

    local procedure CountRows(var List: TestPage "LT P82 List"): Integer
    var
        N: Integer;
    begin
        if List.First() then
            repeat
                N += 1;
            until not List.Next();
        exit(N);
    end;

    [Test]
    procedure Filter_CurrentKey_And_Ascending()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P82 List";
        N: Integer;
    begin
        Seed();
        List.OpenView();
        List.Filter.SetCurrentKey(Qty);
        List.Filter.Ascending(false);
        if List.First() then
            repeat
                N += 1;
                Observer.Observe('desc-row' + Format(N), List.NoCtl.Value());
            until not List.Next();
        Observer.Observe('ascending', Format(List.Filter.Ascending()));
        List.Close();
        Observer.Expect('desc-row1', 'N5');
        Observer.Expect('desc-row2', 'N4');
        Observer.Expect('desc-row3', 'N3');
        Observer.Expect('desc-row4', 'N2');
        Observer.Expect('desc-row5', 'N1');
        Observer.Expect('ascending', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_FilterBeforeOpen()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P82 List";
    begin
        Seed();
        List.Trap();
        Page.Run(Page::"LT P82 List");
        Observer.Observe('count-after-trap', Format(CountRows(List)));
        List.Close();
        Observer.Expect('count-after-trap', '6');
        Observer.Verify();
    end;

    [Test]
    procedure Caption_List_And_Host()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT P82 Host";
        Group: TestPage "LT P82 Group List";
    begin
        Seed();
        Group.OpenView();
        Observer.Observe('group-caption', Group.Caption());
        Observer.Observe('code-caption', Group.CodeCtl.Caption());
        Group.Close();
        Host.OpenView();
        Observer.Observe('host-caption', Host.Caption());
        Host.Close();
        Observer.Expect('group-caption', 'LT P82 Group List Caption');
        Observer.Expect('code-caption', 'Code');
        Observer.Expect('host-caption', 'LT P82 Host - G1');
        Observer.Verify();
    end;

    [Test]
    procedure Tree_Expand_IsExpanded()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P82 Item";
        Tree: TestPage "LT P82 Tree";
        N: Integer;
    begin
        Seed();
        Item.Get('N2');
        Item.Indent := 1;
        Item.Modify();
        Item.Get('N3');
        Item.Indent := 2;
        Item.Modify();
        Item.Get('N4');
        Item.Indent := 1;
        Item.Modify();
        Tree.OpenView();
        Tree.GoToKey('N1');
        Observer.Observe('n1-expanded-initial', Format(Tree.IsExpanded()));
        Tree.Expand(true);
        Observer.Observe('n1-expanded-after-true', Format(Tree.IsExpanded()));
        Tree.Expand(true);
        Observer.Observe('n1-expanded-after-second-true', Format(Tree.IsExpanded()));
        Tree.Expand(false);
        Observer.Observe('n1-expanded-after-false', Format(Tree.IsExpanded()));
        Tree.Expand(false);
        Observer.Observe('n1-expanded-after-second-false', Format(Tree.IsExpanded()));
        asserterror Tree.GoToKey('N2');
        Observer.ObserveError('af238');
        Observer.Observe('n2-expanded-initial', Format(Tree.IsExpanded()));
        Tree.Expand(true);
        Observer.Observe('n2-expanded-after-true', Format(Tree.IsExpanded()));
        asserterror Tree.GoToKey('N3');
        Observer.ObserveError('af243');
        Observer.Observe('n3-expanded-leaf', Format(Tree.IsExpanded()));
        Tree.Expand(true);
        Observer.Observe('n3-expanded-leaf-after-true', Format(Tree.IsExpanded()));
        Tree.GoToKey('N5');
        Observer.Observe('n5-expanded-leaf', Format(Tree.IsExpanded()));
        Tree.Close();
        Observer.Expect('n1-expanded-initial', 'No');
        Observer.Expect('n1-expanded-after-true', 'Yes');
        Observer.Expect('n1-expanded-after-second-true', 'Yes');
        Observer.Expect('n1-expanded-after-false', 'No');
        Observer.Expect('n1-expanded-after-second-false', 'No');
        Observer.Expect('af238|text', 'The row does not exist on the TestPage.');
        Observer.Expect('af238|code', 'TestRowNotFound');
        Observer.Expect('n2-expanded-initial', 'No');
        Observer.Expect('n2-expanded-after-true', 'Yes');
        Observer.Expect('af243|text', 'The row does not exist on the TestPage.');
        Observer.Expect('af243|code', 'TestRowNotFound');
        Observer.Expect('n3-expanded-leaf', 'Yes');
        Observer.Expect('n3-expanded-leaf-after-true', 'Yes');
        Observer.Expect('n5-expanded-leaf', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Tree_Rows_WhileCollapsed()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P82 Item";
        Tree: TestPage "LT P82 Tree";
        N: Integer;
    begin
        Seed();
        Item.Get('N2');
        Item.Indent := 1;
        Item.Modify();
        Item.Get('N3');
        Item.Indent := 1;
        Item.Modify();
        Tree.OpenView();
        Tree.GoToKey('N1');
        Tree.Expand(false);
        if Tree.First() then
            repeat
                N += 1;
                Observer.Observe('collapsed-row' + Format(N), Tree.NoCtl.Value());
            until not Tree.Next();
        Observer.Observe('goto-child-collapsed', Format(Tree.GoToKey('N2')));
        Tree.GoToKey('N1');
        Tree.Expand(true);
        N := 0;
        if Tree.First() then
            repeat
                N += 1;
                Observer.Observe('expanded-row' + Format(N), Tree.NoCtl.Value());
            until not Tree.Next();
        Tree.Close();
        Observer.Expect('collapsed-row1', 'N1');
        Observer.Expect('collapsed-row2', 'N4');
        Observer.Expect('collapsed-row3', 'N5');
        Observer.Expect('goto-child-collapsed', 'No');
        Observer.Expect('expanded-row1', 'N1');
        Observer.Expect('expanded-row2', 'N2');
        Observer.Expect('expanded-row3', 'N3');
        Observer.Expect('expanded-row4', 'N4');
        Observer.Expect('expanded-row5', 'N5');
        Observer.Verify();
    end;

    [Test]
    procedure Part_Hidden_And_Disabled_Access()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT P82 Host";
    begin
        Seed();
        Host.OpenView();
        Host.GoToKey('G1');
        asserterror Observer.Observe('hidden-first', Format(Host.HiddenPart.First()));
        Observer.ObserveError('hidden-first');
        Observer.Observe('disabled-first', Format(Host.DisabledPart.First()));
        Observer.Observe('disabled-first', 'no error');
        Host.Close();
        Observer.Expect('hidden-first|text', 'The part with ID = n was not found on the page.');
        Observer.Expect('hidden-first|code', 'TestPartNotFound');
        Observer.Expect('disabled-first', 'Yes');
        Observer.Expect('disabled-first', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Page_Editable_And_Close_Twice()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('view-editable', Format(Card.Editable()));
        Card.Close();
        Card.OpenEdit();
        Observer.Observe('edit-editable', Format(Card.Editable()));
        Card.Close();
        asserterror Card.Close();
        Observer.ObserveError('close-twice');
        asserterror Observer.Observe('editable-closed', Format(Card.Editable()));
        Observer.ObserveError('editable-closed');
        asserterror Observer.Observe('caption-closed', Card.Caption());
        Observer.ObserveError('caption-closed');
        Observer.Expect('view-editable', 'No');
        Observer.Expect('edit-editable', 'Yes');
        Observer.Expect('close-twice|text', 'The TestPage is not open.');
        Observer.Expect('close-twice|code', 'TestPageNotOpened');
        Observer.Expect('editable-closed|text', 'The TestPage is not open.');
        Observer.Expect('editable-closed|code', 'TestPageNotOpened');
        Observer.Expect('caption-closed|text', 'The TestPage is not open.');
        Observer.Expect('caption-closed|code', 'TestPageNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure OpenNew_Then_GoToKey()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenNew();
        Observer.Observe('new-no', Card.NoCtl.Value());
        Observer.Observe('goto-existing', Format(Card.GoToKey('N2')));
        Observer.Observe('goto-existing-name', Card.NameCtl.Value());
        Card.Close();
        Observer.Expect('new-no', '');
        Observer.Expect('goto-existing', 'Yes');
        Observer.Expect('goto-existing-name', 'Name 2');
        Observer.Verify();
    end;
}
