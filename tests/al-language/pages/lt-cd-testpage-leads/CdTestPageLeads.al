// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); the CD objects of CdObjects.al and CdConst0D.al
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: the TestPage leads of corpus issue #667, items 49-64 (Microsoft AL issues and docs): CurrPage.Editable(false) in OnOpenPage per launch route,
//   the card caption without DataCaptionFields, Visible over page variables changed after open, Validate of an Editable = false field,
//   area(Prompting) actions without RunObject, Editable after an action, a page-variable control on a view card, ValuesAllowed with '',
//   NavigatePage label Visible, SourceTableView const(0D), enum SubPageLink and RunPageLink, SetSelectionFilter on a descending list,
//   OnOpenPage filters in filter groups 2, 4 and -1, the filter groups a part sees in OnOpenPage, and SetAscending in OnOpenPage.
// BC versions: all (CI)

codeunit 84282 "LT CD TestPage Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT CD Log";

    local procedure Seed()
    var
        Row: Record "LT CD Row";
    begin
        Row.DeleteAll();
        AddRow(1, 'n1', 'A', 0D);
        AddRow(2, 'n3', 'B', 0D);
        AddRow(3, 'n2', 'A', DMY2Date(1, 2, 2024));
        AddRow(4, 'n4', 'C', DMY2Date(1, 3, 2024));
        Log.Clear();
    end;

    local procedure AddRow(NewId: Integer; NewName: Text[30]; NewGrp: Code[10]; NewD: Date)
    var
        Row: Record "LT CD Row";
    begin
        Row.Init();
        Row.Id := NewId;
        Row.Name := NewName;
        Row.Grp := NewGrp;
        Row.D := NewD;
        Row.Insert();
    end;

    local procedure Rows(): Text
    var
        Row: Record "LT CD Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ':' + Row.Name + ':' + Row.Locked + ':' + Row.C1 + ',';
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure LineRows(): Text
    var
        Line: Record "LT CD Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                Result += Format(Line.Kind) + '/' + Format(Line.No) + '/' + Line.Descr + ',';
            until Line.Next() = 0;
        exit(Result);
    end;

    // ---- Item 49: CurrPage.Editable(false) in OnOpenPage, by launch route ------------------------------------------------------

    local procedure ObserveLockCard(Prefix: Text; var Card: TestPage "LT CD Lock Card")
    begin
        Observer.Observe(Prefix + '-pageEd', Format(Card.Editable()));
        Observer.Observe(Prefix + '-nameEd', Format(Card.NameCtl.Editable()));
        Observer.Observe(Prefix + '-noteEd', Format(Card.NoteCtl.Editable()));
        ClearLastError();
        Card.NameCtl.SetValue('typed');
        Observer.Observe(Prefix + '-setvalue-err', GetLastErrorText());
        Observer.Observe(Prefix + '-shown', Card.NameCtl.Value());
    end;

    // CurrPage.Editable(false) in OnOpenPage: the page and Rec controls read not editable, yet SetValue raises nothing and the value is saved.
    [Test]
    procedure Item49_LockCard_OpenView()
    var
        Card: TestPage "LT CD Lock Card";
    begin
        Seed();
        Card.OpenView();
        ObserveLockCard('view', Card);
        Card.Close();
        Observer.Observe('rows', Rows());
        Observer.Expect('view-pageEd', 'No');
        Observer.Expect('view-nameEd', 'No');
        Observer.Expect('view-noteEd', 'Yes');
        Observer.Expect('view-setvalue-err', '');
        Observer.Expect('view-shown', 'typed');
        Observer.Expect('rows', '1:typed::,2:n3::,3:n2::,4:n4::,');
        Observer.Verify();
    end;

    [Test]
    procedure Item49_LockCard_OpenNew()
    var
        Card: TestPage "LT CD Lock Card";
    begin
        Seed();
        Card.OpenNew();
        Observer.Observe('new-pageEd', Format(Card.Editable()));
        Observer.Observe('new-idEd', Format(Card.IdCtl.Editable()));
        ClearLastError();
        Card.IdCtl.SetValue(9);
        Observer.Observe('new-setid-err', GetLastErrorText());
        ClearLastError();
        Card.NameCtl.SetValue('typed');
        Observer.Observe('new-setname-err', GetLastErrorText());
        Card.Close();
        Observer.Observe('rows', Rows());
        Observer.Expect('new-pageEd', 'Yes');
        Observer.Expect('new-idEd', 'No');
        Observer.Expect('new-setid-err', '');
        Observer.Expect('new-setname-err', '');
        Observer.Expect('rows', '1:n1::,2:n3::,3:n2::,4:n4::,9:typed::,');
        Observer.Verify();
    end;

    [Test]
    procedure Item49_LockCard_OpenEdit_New()
    var
        Card: TestPage "LT CD Lock Card";
    begin
        Seed();
        Card.OpenEdit();
        ClearLastError();
        Card.New();
        Observer.Observe('new-err', GetLastErrorText());
        Observer.Observe('new-idEd', Format(Card.IdCtl.Editable()));
        Card.IdCtl.SetValue(8);
        Card.NameCtl.SetValue('typed');
        Card.Close();
        Observer.Observe('rows', Rows());
        Observer.Expect('new-err', '');
        Observer.Expect('new-idEd', 'No');
        Observer.Expect('rows', '1:n1::,2:n3::,3:n2::,4:n4::,8:typed::,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LockCardPageHandler')]
    procedure Item49_LockCard_PageRun()
    var
        Row: Record "LT CD Row";
    begin
        Seed();
        Row.Get(1);
        Page.Run(Page::"LT CD Lock Card", Row);
        Observer.Observe('rows', Rows());
        Observer.Expect('run-pageEd', 'No');
        Observer.Expect('run-nameEd', 'No');
        Observer.Expect('run-noteEd', 'No');
        Observer.Expect('run-setvalue-err', '');
        Observer.Expect('run-shown', 'typed');
        Observer.Expect('rows', '1:typed::,2:n3::,3:n2::,4:n4::,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LockCardModalHandler')]
    procedure Item49_LockCard_PageRunModal()
    var
        Row: Record "LT CD Row";
    begin
        Seed();
        Row.Get(1);
        Page.RunModal(Page::"LT CD Lock Card", Row);
        Observer.Observe('rows', Rows());
        Observer.Expect('runmodal-pageEd', 'No');
        Observer.Expect('runmodal-nameEd', 'No');
        Observer.Expect('runmodal-noteEd', 'No');
        Observer.Expect('runmodal-setvalue-err', '');
        Observer.Expect('runmodal-shown', 'typed');
        Observer.Expect('rows', '1:typed::,2:n3::,3:n2::,4:n4::,');
        Observer.Verify();
    end;

    [PageHandler]
    procedure LockCardPageHandler(var Card: TestPage "LT CD Lock Card")
    begin
        ObserveLockCard('run', Card);
        Card.Close();
    end;

    [ModalPageHandler]
    procedure LockCardModalHandler(var Card: TestPage "LT CD Lock Card")
    begin
        ObserveLockCard('runmodal', Card);
        Card.OK().Invoke();
    end;

    // ---- Item 50: a card over a table without DataCaptionFields ---------------------------------------------------------------

    [Test]
    procedure Item50_NoDataCaptionFields_CardCaption()
    var
        NoCap: Record "LT CD NoCap";
        Card: TestPage "LT CD NoCap Card";
    begin
        NoCap.DeleteAll();
        NoCap."Code" := 'C1';
        NoCap.Name := 'Alpha';
        NoCap.Insert();
        NoCap."Code" := 'C2';
        NoCap.Name := 'Beta';
        NoCap.Insert();
        Card.OpenView();
        Observer.Observe('first', Card.Caption());
        Card.Next();
        Observer.Observe('second', Card.Caption());
        Card.Close();
        Card.OpenNew();
        Observer.Observe('new', Card.Caption());
        Card.Close();
        Observer.Expect('first', 'CD NoCap - C1');
        Observer.Expect('second', 'CD NoCap - C2');
        Observer.Expect('new', 'New - CD NoCap');
        Observer.Verify();
    end;

    // ---- Item 51: Visible over page variables, changed by an action after the page opened ------------------------------------

    local procedure ObserveVis(Prefix: Text; var Card: TestPage "LT CD Vis Card")
    begin
        Observer.Observe(Prefix, 'field=' + Format(Card.NameCtl.Visible()) + ' groupfield=' + Format(Card.IdInGroup.Visible())
            + ' action=' + Format(Card.Target.Visible()));
    end;

    [Test]
    procedure Item51_VisibleVariables_ActionWithoutUpdate()
    var
        Card: TestPage "LT CD Vis Card";
    begin
        Seed();
        Card.OpenEdit();
        ObserveVis('open', Card);
        Card.HideAll.Invoke();
        ObserveVis('after-action', Card);
        Card.Next();
        Card.Previous();
        ObserveVis('after-move', Card);
        Card.Close();
        Observer.Expect('open', 'field=Yes groupfield=Yes action=Yes');
        Observer.Expect('after-action', 'field=Yes groupfield=No action=No');
        Observer.Expect('after-move', 'field=Yes groupfield=No action=No');
        Observer.Verify();
    end;

    [Test]
    procedure Item51_VisibleVariables_ActionWithUpdate()
    var
        Card: TestPage "LT CD Vis Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.HideAllUpdate.Invoke();
        ObserveVis('after-action-update', Card);
        Card.Close();
        Observer.Expect('after-action-update', 'field=Yes groupfield=No action=No');
        Observer.Verify();
    end;

    // ---- Item 52: Validate of a table field with Editable = false ------------------------------------------------------------

    [Test]
    procedure Item52_ValidateEditableFalseField_InCode()
    var
        Row: Record "LT CD Row";
    begin
        Seed();
        Row.Get(1);
        ClearLastError();
        Row.Validate(Locked, 'set-by-validate');
        Observer.Observe('err', GetLastErrorText());
        Observer.Observe('log', Log.Take());
        Row.Modify();
        Row.Get(1);
        Row.Locked := 'set-by-assign';
        Row.Modify(true);
        Observer.Observe('rows', Rows());
        Observer.Expect('err', '');
        Observer.Expect('log', 'locked-onvalidate:set-by-validate;');
        Observer.Expect('rows', '1:n1:set-by-assign:,2:n3::,3:n2::,4:n4::,');
        Observer.Verify();
    end;

    // ---- Item 54: Editable after an action that changes Status ---------------------------------------------------------------

    local procedure ObserveStatusEd(Prefix: Text; var Card: TestPage "LT CD Status Card")
    begin
        Observer.Observe(Prefix, 'status=' + Card.StatusCtl.Value() + ' byVar=' + Format(Card.NameByVar.Editable())
            + ' byRec=' + Format(Card.TByRec.Editable()));
    end;

    [Test]
    procedure Item54_EditableAfterAction_OpenEdit()
    var
        Card: TestPage "LT CD Status Card";
    begin
        Seed();
        Card.OpenEdit();
        ObserveStatusEd('open', Card);
        Card.Release.Invoke();
        ObserveStatusEd('after-release', Card);
        Card.ReopenUpdate.Invoke();
        ObserveStatusEd('after-reopen-update', Card);
        Card.ReleaseUpdate.Invoke();
        ObserveStatusEd('after-release-update', Card);
        Card.Close();
        Observer.Expect('open', 'status=Open byVar=Yes byRec=Yes');
        Observer.Expect('after-release', 'status=Released byVar=No byRec=No');
        Observer.Expect('after-reopen-update', 'status=Open byVar=Yes byRec=Yes');
        Observer.Expect('after-release-update', 'status=Released byVar=No byRec=No');
        Observer.Verify();
    end;

    [Test]
    procedure Item54_EditableAfterAction_OpenView()
    var
        Card: TestPage "LT CD Status Card";
    begin
        Seed();
        Card.OpenView();
        ObserveStatusEd('open', Card);
        Card.ReleaseUpdate.Invoke();
        ObserveStatusEd('after-release-update', Card);
        Card.Close();
        Observer.Expect('open', 'status=Open byVar=No byRec=No');
        Observer.Expect('after-release-update', 'status=Released byVar=No byRec=No');
        Observer.Verify();
    end;

    [Test]
    procedure Item54_EditableOnReleasedRow_SetValue()
    var
        Row: Record "LT CD Row";
        Card: TestPage "LT CD Status Card";
    begin
        Seed();
        Row.Get(1);
        Row.Status := Row.Status::Released;
        Row.Modify();
        Card.OpenEdit();
        ObserveStatusEd('open-released', Card);
        ClearLastError();
        Card.NameByVar.SetValue('typed');
        Observer.Observe('setvalue-err', GetLastErrorText());
        Card.Close();
        Observer.Observe('rows', Rows());
        Observer.Expect('open-released', 'status=Released byVar=No byRec=No');
        Observer.Expect('setvalue-err', '');
        Observer.Expect('rows', '1:typed::,2:n3::,3:n2::,4:n4::,');
        Observer.Verify();
    end;

    // ---- Item 55: a page-variable control on a card opened with OpenView -----------------------------------------------------

    [Test]
    procedure Item55_VariableControl_OpenView_SetValue()
    var
        Card: TestPage "LT CD Status Card";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('pageEd', Format(Card.Editable()));
        Observer.Observe('noteEd', Format(Card.NoteCtl.Editable()));
        ClearLastError();
        Card.NoteCtl.SetValue('typed note');
        Observer.Observe('err', GetLastErrorText());
        Observer.Observe('shown', Card.NoteCtl.Value());
        Card.Close();
        Observer.Expect('pageEd', 'No');
        Observer.Expect('noteEd', 'Yes');
        Observer.Expect('err', '');
        Observer.Expect('shown', 'typed note');
        Observer.Verify();
    end;

    // ---- Item 56: ValuesAllowed = '', 'A', 'N' on a Code[1] table field -------------------------------------------------------

    [Test]
    procedure Item56_ValuesAllowedEmpty_SetValueEmptyAfterA()
    var
        Card: TestPage "LT CD Status Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.C1Ctl.SetValue('A');
        Observer.Observe('after-a', Card.C1Ctl.Value());
        asserterror Card.C1Ctl.SetValue('');
        Observer.ObserveError('set-empty');
        Observer.Observe('after-empty', Card.C1Ctl.Value());
        Card.Close();
        Observer.Expect('after-a', 'A');
        Observer.Expect('set-empty|text', 'Validation error for Field: C1Ctl,  Message = ''Value '''' is not a valid value. The following values can be used: ;A;N. (Select Refresh to discard errors)''');
        Observer.Expect('set-empty|code', 'TestValidation');
        Observer.Expect('after-empty', 'A');
        Observer.Verify();
    end;

    [Test]
    procedure Item56_ValuesAllowed_SetValueNotAllowed()
    var
        Card: TestPage "LT CD Status Card";
    begin
        Seed();
        Card.OpenEdit();
        asserterror Card.C1Ctl.SetValue('X');
        Observer.ObserveError('set-x');
        Card.Close();
        Observer.Expect('set-x|text', 'Validation error for Field: C1Ctl,  Message = ''Value ''X'' is not a valid value. The following values can be used: ;A;N. (Select Refresh to discard errors)''');
        Observer.Expect('set-x|code', 'TestValidation');
        Observer.Verify();
    end;

    // ValuesAllowed is checked by TestPage SetValue (error 'Value '' is not a valid value...') but not by Validate in code.
    [Test]
    procedure Item56_ValuesAllowed_ValidateInCode()
    var
        Row: Record "LT CD Row";
    begin
        Seed();
        Row.Get(1);
        Row.Validate(C1, 'A');
        Row.Validate(C1, '');
        Observer.Observe('after-empty', Row.C1);
        ClearLastError();
        Row.Validate(C1, 'X');
        Observer.Observe('validate-x-err', GetLastErrorText());
        Observer.Observe('after-x', Row.C1);
        Observer.Expect('after-empty', '');
        Observer.Expect('validate-x-err', '');
        Observer.Expect('after-x', 'X');
        Observer.Verify();
    end;

    // ---- Item 53: area(Prompting) actions -------------------------------------------------------------------------------------

    [Test]
    procedure Item53_PromptingActions()
    var
        Card: TestPage "LT CD Prompting Card";
    begin
        Seed();
        Card.OpenEdit();
        Observer.Observe('no-run', 'visible=' + Format(Card.PromptNoRun.Visible()) + ' enabled=' + Format(Card.PromptNoRun.Enabled()));
        Observer.Observe('with-run', 'visible=' + Format(Card.PromptWithRun.Visible()) + ' enabled=' + Format(Card.PromptWithRun.Enabled()));
        Observer.Observe('plain', 'visible=' + Format(Card.Plain.Visible()));
        ClearLastError();
        Card.PromptNoRun.Invoke();
        Observer.Observe('invoke-err', GetLastErrorText());
        Observer.Observe('log', Log.Take());
        Card.Close();
        Observer.Expect('no-run', 'visible=Yes enabled=Yes');
        Observer.Expect('with-run', 'visible=Yes enabled=Yes');
        Observer.Expect('plain', 'visible=Yes');
        Observer.Expect('invoke-err', '');
        Observer.Expect('log', 'prompt-no-run;');
        Observer.Verify();
    end;

    // ---- Item 57: NavigatePage labels with Visible expressions ----------------------------------------------------------------

    local procedure ObserveNav(Prefix: Text; var Nav: TestPage "LT CD Navigate")
    begin
        Observer.Observe(Prefix, 'const=' + Format(Nav.ConstExprLabel.Visible()) + ' var=' + Format(Nav.VarLabel.Visible())
            + ' grouped=' + Format(Nav.GroupedLabel.Visible()));
    end;

    [Test]
    procedure Item57_NavigatePageLabels()
    var
        Nav: TestPage "LT CD Navigate";
    begin
        Seed();
        Nav.OpenEdit();
        ObserveNav('open', Nav);
        Nav.OkCtl.SetValue(true);
        ObserveNav('after-ok', Nav);
        Nav.Close();
        Observer.Expect('open', 'const=No var=Yes grouped=Yes');
        Observer.Expect('after-ok', 'const=No var=Yes grouped=No');
        Observer.Verify();
    end;

    // ---- Item 58: SourceTableView with const(0D), filter(0D) and other const values ------------------------------------------

    local procedure ShownIds0D(var List: TestPage "LT CD Const0D List"): Text
    var
        Result: Text;
    begin
        if List.First() then
            repeat
                Result += List.IdCtl.Value() + ',';
            until not List.Next();
        exit(Result);
    end;

    [Test]
    procedure Item58_SourceTableView_Const0D()
    var
        List: TestPage "LT CD Const0D List";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('ids', ShownIds0D(List));
        List.Close();
        Observer.Expect('ids', '1,2,');
        Observer.Verify();
    end;

    [Test]
    procedure Item58_SourceTableView_Filter0D()
    var
        List: TestPage "LT CD Filter0D List";
        Result: Text;
    begin
        Seed();
        List.OpenView();
        if List.First() then
            repeat
                Result += List.IdCtl.Value() + ',';
            until not List.Next();
        Observer.Observe('ids', Result);
        List.Close();
        Observer.Expect('ids', '1,2,');
        Observer.Verify();
    end;

    [Test]
    procedure Item58_SourceTableView_ConstEmptyTextAndEnum()
    var
        Row: Record "LT CD Row";
        List: TestPage "LT CD ConstOthers List";
        Result: Text;
    begin
        Seed();
        Row.Get(2);
        Row.T := 'x';
        Row.Modify();
        Row.Get(3);
        Row.Status := Row.Status::Released;
        Row.Modify();
        List.OpenView();
        if List.First() then
            repeat
                Result += List.IdCtl.Value() + ',';
            until not List.Next();
        Observer.Observe('ids', Result);
        List.Close();
        Observer.Expect('ids', '1,2,4,');
        Observer.Verify();
    end;

    // ---- Items 59, 64: a part linked through an enum field ---------------------------------------------------------------------

    local procedure SeedHead(HeadKind: Enum "LT CD Kind")
    var
        Head: Record "LT CD Head";
        Line: Record "LT CD Line";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Head.Id := 1;
        Head.Kind := HeadKind;
        Head.Insert();
        Line.Kind := Line.Kind::First;
        Line.No := 10000;
        Line.Descr := 'first line';
        Line.Insert();
        Line.Kind := Line.Kind::Second;
        Line.No := 10000;
        Line.Descr := 'second line';
        Line.Insert();
        Log.Clear();
    end;

    [Test]
    procedure Item59_EnumSubPageLink_NewLine()
    var
        Card: TestPage "LT CD Head Card";
    begin
        SeedHead("LT CD Kind"::Second);
        Card.OpenEdit();
        Card.Lines.First();
        Observer.Observe('part-first', Card.Lines.KindCtl.Value() + '/' + Card.Lines.DescrCtl.Value());
        Observer.Observe('part-next', Format(Card.Lines.Next()));
        Card.Lines.New();
        Observer.Observe('new-kind-shown', Card.Lines.KindCtl.Value());
        Card.Lines.DescrCtl.SetValue('typed line');
        Card.Lines.First();
        Card.Close();
        Observer.Observe('lines', LineRows());
        Observer.Expect('part-first', 'Second/second line');
        Observer.Expect('part-next', 'Yes');
        Observer.Expect('new-kind-shown', 'Second');
        Observer.Expect('lines', 'First/10000/first line,Second/10000/second line,Second/30000/typed line,');
        Observer.Verify();
    end;

    [Test]
    procedure Item64_PartFilterGroupsInOnOpenPage()
    var
        Card: TestPage "LT CD Head Card";
    begin
        SeedHead("LT CD Kind"::Second);
        Card.OpenView();
        Card.Close();
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'part-onopenpage:;part-aftergetcurr:g4=Kind: Second;');
        Observer.Verify();
    end;

    // ---- Item 61: RunPageLink on an enum key field, new row ---------------------------------------------------------------------

    // RunPageLink Kind = field(Kind): TestPage Filter.GetFilter gives the enum ordinal ('2'); with const(Second) it gives the name. A new row gets the link value.
    [Test]
    procedure Item61_RunPageLinkEnumKey_ByField_New()
    var
        Card: TestPage "LT CD Head Card";
        List: TestPage "LT CD Line List";
    begin
        SeedHead("LT CD Kind"::Third);
        Card.OpenView();
        List.Trap();
        Card.LinesByField.Invoke();
        Observer.Observe('filter', List.Filter.GetFilter(Kind));
        List.New();
        Observer.Observe('new-kind-shown', List.KindCtl.Value());
        List.NoCtl.SetValue(5);
        List.DescrCtl.SetValue('typed');
        List.Close();
        Card.Close();
        Observer.Observe('lines', LineRows());
        Observer.Expect('filter', '2');
        Observer.Expect('new-kind-shown', 'Third');
        Observer.Expect('lines', 'First/10000/first line,Second/10000/second line,Third/5/typed,');
        Observer.Verify();
    end;

    [Test]
    procedure Item61_RunPageLinkEnumKey_ByConst_New()
    var
        Card: TestPage "LT CD Head Card";
        List: TestPage "LT CD Line List";
    begin
        SeedHead("LT CD Kind"::First);
        Card.OpenView();
        List.Trap();
        Card.LinesByConst.Invoke();
        Observer.Observe('filter', List.Filter.GetFilter(Kind));
        List.New();
        Observer.Observe('new-kind-shown', List.KindCtl.Value());
        List.NoCtl.SetValue(5);
        List.DescrCtl.SetValue('typed');
        List.Close();
        Card.Close();
        Observer.Observe('lines', LineRows());
        Observer.Expect('filter', 'Second');
        Observer.Expect('new-kind-shown', 'Second');
        Observer.Expect('lines', 'First/10000/first line,Second/5/typed,Second/10000/second line,');
        Observer.Verify();
    end;

    // ---- Item 60: SetSelectionFilter on a list sorted descending -----------------------------------------------------------------

    [Test]
    procedure Item60_SelectionFilter_SourceTableViewDescending()
    var
        List: TestPage "LT CD Desc List";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('first-shown', List.IdCtl.Value());
        List.GoToKey(2);
        List.Sel.Invoke();
        Observer.Observe('log', Log.Take());
        List.Close();
        Observer.Expect('first-shown', '4');
        Observer.Expect('log', 'filters=Id: 2 count=1 markedonly=No asc=Yes;marked=2,;');
        Observer.Verify();
    end;

    [Test]
    procedure Item60_SelectionFilter_AscendingFalseInOnOpenPage()
    var
        List: TestPage "LT CD AscFalse List";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('first-shown', List.IdCtl.Value());
        List.GoToKey(3);
        List.Sel.Invoke();
        Observer.Observe('log', Log.Take());
        List.Close();
        Observer.Expect('first-shown', '4');
        Observer.Expect('log', 'filters=Id: 3 count=1 markedonly=No asc=Yes;marked=3,;');
        Observer.Verify();
    end;

    // ---- Item 62: TestPage Filter against filters set in OnOpenPage in filter groups 2 and 4 -----------------------------------

    // TestPage Filter cannot remove a filter set in filter group 2 or 4 in OnOpenPage: GetFilter still answers it and a second filter combines with it.
    [Test]
    procedure Item62_FilterGroup2_TestPageFilter()
    var
        List: TestPage "LT CD FG2 List";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('open', FG2Ids(List) + ' filter=' + List.Filter.GetFilter(Grp));
        List.Filter.SetFilter(Grp, '');
        Observer.Observe('cleared', FG2Ids(List) + ' filter=' + List.Filter.GetFilter(Grp));
        List.Filter.SetFilter(Grp, 'B');
        Observer.Observe('set-b', FG2Ids(List) + ' filter=' + List.Filter.GetFilter(Grp));
        List.Close();
        Observer.Expect('open', 'ids=1,3, filter=A');
        Observer.Expect('cleared', 'ids=1,3, filter=A');
        Observer.Expect('set-b', 'ids= filter=A');
        Observer.Verify();
    end;

    local procedure FG2Ids(var List: TestPage "LT CD FG2 List"): Text
    var
        Result: Text;
    begin
        if List.First() then
            repeat
                Result += List.IdCtl.Value() + ',';
            until not List.Next();
        exit('ids=' + Result);
    end;

    [Test]
    procedure Item62_FilterGroup4_TestPageFilter()
    var
        List: TestPage "LT CD FG4 List";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('open', FG4Ids(List) + ' filter=' + List.Filter.GetFilter(Grp));
        List.Filter.SetFilter(Grp, '');
        Observer.Observe('cleared', FG4Ids(List) + ' filter=' + List.Filter.GetFilter(Grp));
        List.Filter.SetFilter(Grp, 'B');
        Observer.Observe('set-b', FG4Ids(List) + ' filter=' + List.Filter.GetFilter(Grp));
        List.Close();
        Observer.Expect('open', 'ids=1,3, filter=A');
        Observer.Expect('cleared', 'ids=1,3, filter=A');
        Observer.Expect('set-b', 'ids= filter=A');
        Observer.Verify();
    end;

    local procedure FG4Ids(var List: TestPage "LT CD FG4 List"): Text
    var
        Result: Text;
    begin
        if List.First() then
            repeat
                Result += List.IdCtl.Value() + ',';
            until not List.Next();
        exit('ids=' + Result);
    end;

    // ---- Item 63: FilterGroup(-1) and FilterGroup(4) with two SetRange calls in OnOpenPage ------------------------------------

    // FilterGroup(-1) filters set in OnOpenPage: the record counts 3 rows (OR) inside the trigger, but the page shows all 4 rows.
    [Test]
    procedure Item63_FilterGroupMinus1_InOnOpenPage()
    var
        List: TestPage "LT CD OrGroup List";
        Result: Text;
    begin
        Seed();
        List.OpenView();
        if List.First() then
            repeat
                Result += List.IdCtl.Value() + ',';
            until not List.Next();
        Observer.Observe('ids', Result);
        Observer.Observe('log', Log.Take());
        List.Close();
        Observer.Expect('ids', '1,2,3,4,');
        Observer.Expect('log', 'g-1=Name: n3, Grp: A count=3;');
        Observer.Verify();
    end;

    [Test]
    procedure Item63_FilterGroup4_TwoFields_InOnOpenPage()
    var
        Row: Record "LT CD Row";
        List: TestPage "LT CD AndGroup4 List";
        Result: Text;
    begin
        Seed();
        Row.Get(3);
        Row.Name := 'n3';
        Row.Modify();
        List.OpenView();
        if List.First() then
            repeat
                Result += List.IdCtl.Value() + ',';
            until not List.Next();
        Observer.Observe('ids', Result);
        List.Close();
        Observer.Expect('ids', '3,');
        Observer.Verify();
    end;

    // ---- Item 64: SetCurrentKey on a two-field key, then SetAscending on the second field, in OnOpenPage ----------------------

    // SetAscending(Id, false) after SetCurrentKey(Grp, Id) in OnOpenPage: the page shows the key ascending (SetAscending has no effect on the page).
    [Test]
    procedure Item64_SetAscendingInOnOpenPage_TwoFieldKey()
    var
        List: TestPage "LT CD SortKey List";
        Result: Text;
    begin
        Seed();
        List.OpenView();
        if List.First() then
            repeat
                Result += List.IdCtl.Value() + ',';
            until not List.Next();
        Observer.Observe('ids', Result);
        List.Close();
        Observer.Expect('ids', '1,3,2,4,');
        Observer.Verify();
    end;

    // ---- Writer SH, al-runner issues 5957 and 5958: SourceTableView filter('') and filter(<> '') on a Date field (pages in CdConst0D.al):
    // the rows the page shows, and the SourceTableView text in Page Metadata.

    [Test]
    procedure SH_SourceTableView_DateFilterBlank_Rows()
    var
        Row: Record "LT CD Row";
        List: TestPage "LT SH Blank Date List";
        Result: Text;
    begin
        Seed();
        List.OpenView();
        if List.First() then
            repeat
                Result += List.IdCtl.Value() + ',';
            until not List.Next();
        Observer.Observe('OpenView ids', Result);
        List.Close();
        // The reporter's form: Page.Run on a record positioned on a blank-date row.
        Row.Get(2);
        List.Trap();
        Page.Run(Page::"LT SH Blank Date List", Row);
        Observer.Observe('Page.Run current id', List.IdCtl.Value());
        Observer.Observe('Page.Run Next', Format(List.Next()));
        Observer.Observe('Page.Run id after Next', List.IdCtl.Value());
        List.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SH_SourceTableView_DateFilterNotBlank_Rows()
    var
        List: TestPage "LT SH NotBlank Date List";
        Result: Text;
    begin
        Seed();
        List.OpenView();
        if List.First() then
            repeat
                Result += List.IdCtl.Value() + ',';
            until not List.Next();
        Observer.Observe('OpenView ids', Result);
        List.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SH_SourceTableView_DateFilterBlank_PageMetadata()
    var
        Meta: Record "Page Metadata";
    begin
        Meta.Get(Page::"LT SH Blank Date List");
        Observer.Observe('filter blank', Meta.SourceTableView);
        Meta.Get(Page::"LT SH NotBlank Date List");
        Observer.Observe('filter not blank', Meta.SourceTableView);
        Meta.Get(Page::"LT CD Filter0D List");
        Observer.Observe('filter 0D', Meta.SourceTableView);
        Meta.Get(Page::"LT CD Const0D List");
        Observer.Observe('const 0D', Meta.SourceTableView);
        Observer.Finish();
    end;
}
