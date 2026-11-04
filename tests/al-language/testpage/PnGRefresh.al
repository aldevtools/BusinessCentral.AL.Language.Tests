// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT PnG List (70135), LT PnG Card (70134), LT PnG Item (70130), LT PnG Log (70133)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md rows 82 (TestPage: CurrPage.Update outside SetValue/action schedules no re-read; a list that loses its only row after an action without Update), 83 (the re-read keeps the client's unsaved edits) and 89 (a repeater row keeps the buffer OnAfterGetRecord left; xRec of such a row)
// Facts: trigger logs (AGR / AGCR) of open with and without CurrPage.Update in OnOpenPage, of modify / delete actions with and without Update, of an edited unsaved field followed by Update, of an OnAfterGetRecord buffer edit
// BC versions: 29 (27 and 28 by CI)

codeunit 70177 "LT PnG Refresh"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Rows: Integer)
    var
        Item: Record "LT PnG Item";
        i: Integer;
    begin
        Item.DeleteAll();
        for i := 1 to Rows do begin
            Item.Init();
            Item."No." := 'U' + Format(i);
            Item.Name := 'Upd ' + Format(i);
            Item.Qty := i;
            Item.Insert();
        end;
    end;

    [Test]
    procedure ListOpenWithAndWithoutUpdateInOnOpenPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Seed(3);
        Log.Reset();
        List.OpenView();
        Observer.Observe('plain-open', Log.Dump());
        List.Close();
        Log.Reset();
        Log.SetFlag('ListUpdateInOpen', true);
        List.OpenView();
        Observer.Observe('update-in-open', Log.Dump());
        List.Close();
        Log.SetFlag('ListUpdateInOpen', false);
        Observer.Expect('plain-open', 'List.OnInit;List.OnOpenPage;List.AGR(U1,Upd 1);List.AGR(U2,Upd 2);List.AGR(U3,Upd 3);List.AGR(U1,Upd 1);List.AGR(U1,Upd 1);List.AGCR(U1,)');
        Observer.Expect('update-in-open', 'List.OnInit;List.OnOpenPage;List.AGR(U1,Upd 1);List.AGR(U2,Upd 2);List.AGR(U3,Upd 3);List.AGR(U1,Upd 1);List.AGR(U1,Upd 1);List.AGCR(U1,)');
        Observer.Verify();
    end;

    [Test]
    procedure CardOpenWithAndWithoutUpdateInOnOpenPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Card: TestPage "LT PnG Card";
    begin
        Seed(2);
        Log.Reset();
        Card.OpenView();
        Observer.Observe('plain-open', Log.Dump());
        Card.Close();
        Log.Reset();
        Log.SetFlag('CardUpdateInOpen', true);
        Card.OpenView();
        Observer.Observe('update-in-open', Log.Dump());
        Card.Close();
        Log.SetFlag('CardUpdateInOpen', false);
        Observer.Expect('plain-open', 'Card.OnInit;Card.OnOpenPage;Card.AGR(U1,Upd 1);Card.AGCR(U1,Upd 1)');
        Observer.Expect('update-in-open', 'Card.OnInit;Card.OnOpenPage;Card.AGR(U1,Upd 1);Card.AGCR(U1,Upd 1)');
        Observer.Verify();
    end;

    [Test]
    procedure ListModifyWithAndWithoutUpdate()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Seed(3);
        List.OpenEdit();
        List.GoToKey('U2');
        Log.Reset();
        List.ModifyNoUpdate.Invoke();
        Observer.Observe('no-update-name', List.NameCtl.Value());
        Observer.Observe('no-update-log', Log.Dump());
        List.GoToKey('U3');
        Log.Reset();
        List.ModifyWithUpdate.Invoke();
        Observer.Observe('update-name', List.NameCtl.Value());
        Observer.Observe('update-log', Log.Dump());
        List.Close();
        Observer.Expect('no-update-name', 'Changed');
        Observer.Expect('no-update-log', 'List.AGR(U2,Upd 2);List.AGR(U2,Changed);List.AGR(U2,Changed);List.AGR(U3,Upd 3);List.AGR(U2,Changed);List.AGR(U1,Upd 1);List.AGR(U2,Changed);List.AGR(U2,Changed);List.AGCR(U2,U2)');
        Observer.Expect('update-name', 'Changed');
        Observer.Expect('update-log', 'List.AGR(U3,Upd 3);List.AGR(U3,Changed);List.AGR(U3,Changed);List.AGR(U2,Changed);List.AGR(U1,Upd 1);List.AGR(U3,Changed);List.AGR(U3,Changed);List.AGCR(U3,U3)');
        Observer.Verify();
    end;

    [Test]
    procedure ListLosesOnlyRowDeleteNoUpdate()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Seed(1);
        List.OpenEdit();
        Log.Reset();
        List.DeleteNoUpdate.Invoke();
        Observer.Observe('stored', Format(Item.Count()));
        Observer.Observe('first', Format(List.First()));
        Observer.Observe('log', Log.Dump());
        List.Close();
        Observer.Expect('stored', '0');
        Observer.Expect('first', 'No');
        Observer.Expect('log', 'List.AGR(U1,Upd 1);List.OnNewRecord;List.AGCR(,);List.OnNewRecord;List.AGCR(,);List.OnNewRecord;List.AGCR(,)');
        Observer.Verify();
    end;

    [Test]
    procedure ListLosesOnlyRowDeleteWithUpdate()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Seed(1);
        List.OpenEdit();
        Log.Reset();
        List.DeleteWithUpdate.Invoke();
        Observer.Observe('stored', Format(Item.Count()));
        Observer.Observe('first', Format(List.First()));
        Observer.Observe('log', Log.Dump());
        List.Close();
        Observer.Expect('stored', '0');
        Observer.Expect('first', 'No');
        Observer.Expect('log', 'List.AGR(U1,Upd 1);List.OnNewRecord;List.AGCR(,);List.OnNewRecord;List.AGCR(,);List.OnNewRecord;List.AGCR(,)');
        Observer.Verify();
    end;

    [Test]
    procedure ListLosesOneOfTwoRowsWithoutUpdate()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Seed(2);
        List.OpenEdit();
        List.GoToKey('U1');
        Log.Reset();
        List.DeleteNoUpdate.Invoke();
        Observer.Observe('current-after', List.NoCtl.Value());
        Observer.Observe('first', Format(List.First()));
        Observer.Observe('first-no', List.NoCtl.Value());
        Observer.Observe('next', Format(List.Next()));
        Observer.Observe('log', Log.Dump());
        List.Close();
        Observer.Expect('current-after', 'U2');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first-no', 'U2');
        Observer.Expect('next', 'Yes');
        Observer.Expect('log', 'List.AGR(U1,Upd 1);List.AGR(U2,Upd 2);List.AGR(U2,Upd 2);List.AGCR(U2,U1);List.AGR(U2,Upd 2);List.AGR(U2,Upd 2);List.AGCR(U2,U2);List.OnNewRecord;List.AGCR(,)');
        Observer.Verify();
    end;

    [Test]
    procedure UpdateKeepsUnsavedEditOfTheRow()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Log: Codeunit "LT PnG Log";
        Card: TestPage "LT PnG Card";
    begin
        Seed(2);
        Card.OpenEdit();
        Log.Reset();
        Card.NameCtl.SetValue('Edited by client');
        Observer.Observe('log-after-setvalue', Log.Dump());
        Item.Get('U1');
        Observer.Observe('stored-after-setvalue', Item.Name);
        Log.Reset();
        Card.UpdateOnly.Invoke();
        Observer.Observe('name-after-update', Card.NameCtl.Value());
        Observer.Observe('log-after-update', Log.Dump());
        Item.Get('U1');
        Observer.Observe('stored-after-update', Item.Name);
        Card.Close();
        Item.Get('U1');
        Observer.Observe('stored-after-close', Item.Name);
        Observer.Expect('log-after-setvalue', 'TblVal(U1,Edited by client)');
        Observer.Expect('stored-after-setvalue', 'Upd 1');
        Observer.Expect('name-after-update', 'Edited by client');
        Observer.Expect('log-after-update', 'Card.AGR(U1,Edited by client);Card.AGR(U1,Edited by client);Card.AGR(U1,Edited by client);Card.AGCR(U1,Edited by client)');
        Observer.Expect('stored-after-update', 'Edited by client');
        Observer.Expect('stored-after-close', 'Edited by client');
        Observer.Verify();
    end;

    [Test]
    procedure UpdateWithSaveKeepsEditOfTheRow()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Log: Codeunit "LT PnG Log";
        Card: TestPage "LT PnG Card";
    begin
        Seed(2);
        Card.OpenEdit();
        Card.QtyCtl.SetValue(77);
        Log.Reset();
        Card.UpdateAndSave.Invoke();
        Observer.Observe('qty-after-update', Card.QtyCtl.Value());
        Item.Get('U1');
        Observer.Observe('stored-qty-after-update', Format(Item.Qty));
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Observer.Expect('qty-after-update', '77');
        Observer.Expect('stored-qty-after-update', '77');
        Observer.Expect('log', 'Card.AGR(U1,Upd 1);Card.AGR(U1,Upd 1);Card.AGR(U1,Upd 1);Card.AGCR(U1,Upd 1)');
        Observer.Verify();
    end;

    [Test]
    procedure BufferEditOfOnAfterGetRecordOnAList()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Seed(3);
        Log.SetFlag('ListBufferEdit', true);
        Log.Reset();
        List.OpenView();
        Observer.Observe('first-name', List.NameCtl.Value());
        Observer.Observe('open-log', Log.Dump());
        Observer.Observe('next', Format(List.Next()));
        Observer.Observe('second-name', List.NameCtl.Value());
        Item.Get('U2');
        Observer.Observe('stored-second-name', Item.Name);
        Item.Name := 'Changed elsewhere';
        Item.Modify();
        Log.Reset();
        Observer.Observe('goto-first', Format(List.GoToKey('U1')));
        Observer.Observe('goto-first-name', List.NameCtl.Value());
        Observer.Observe('goto-log', Log.Dump());
        Log.Reset();
        Observer.Observe('goto-second', Format(List.GoToKey('U2')));
        Observer.Observe('second-name-after-change', List.NameCtl.Value());
        Observer.Observe('second-log', Log.Dump());
        Log.SetFlag('ListBufferEdit', false);
        List.Close();
        Observer.Expect('first-name', 'Upd 1');
        Observer.Expect('open-log', 'List.OnInit;List.OnOpenPage;List.AGR(U1,Upd 1);List.AGR(U2,Upd 2);List.AGR(U3,Upd 3);List.AGR(U1,Upd 1);List.AGR(U1,Upd 1);List.AGCR(U1,)');
        Observer.Expect('next', 'Yes');
        Observer.Expect('second-name', 'Upd 2');
        Observer.Expect('stored-second-name', 'Upd 2');
        Observer.Expect('goto-first', 'Yes');
        Observer.Expect('goto-first-name', 'Upd 1');
        Observer.Expect('goto-log', 'List.AGR(U1,Upd 1);List.AGR(U1,Upd 1);List.AGCR(U1,U2)');
        Observer.Expect('goto-second', 'Yes');
        Observer.Expect('second-name-after-change', 'Changed elsewhere');
        Observer.Expect('second-log', 'List.AGR(U2,Changed elsewhere);List.AGR(U2,Changed elsewhere);List.AGCR(U2,U1)');
        Observer.Verify();
    end;

    [Test]
    procedure BufferEditOfOnAfterGetRecordOnACard()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Log: Codeunit "LT PnG Log";
        Card: TestPage "LT PnG Card";
    begin
        Seed(1);
        Log.SetFlag('CardBufferEdit', true);
        Log.Reset();
        Card.OpenEdit();
        Observer.Observe('name', Card.NameCtl.Value());
        Observer.Observe('log', Log.Dump());
        Card.QtyCtl.SetValue(9);
        Item.Get('U1');
        Observer.Observe('stored-name', Item.Name);
        Observer.Observe('stored-qty', Format(Item.Qty));
        Observer.Observe('name-after-qty', Card.NameCtl.Value());
        Log.SetFlag('CardBufferEdit', false);
        Card.Close();
        Observer.Expect('name', 'Upd 1');
        Observer.Expect('log', 'Card.OnInit;Card.OnOpenPage;Card.AGR(U1,Upd 1);Card.AGCR(U1,Upd 1)');
        Observer.Expect('stored-name', 'Upd 1');
        Observer.Expect('stored-qty', '1');
        Observer.Expect('name-after-qty', 'Upd 1');
        Observer.Verify();
    end;

    // ---- Writer QL (2026-10-21), al-runtime-rs PR 387: a list action that puts another row into Rec (Rec := Other with changed fields),
    // then Close or the page stays open; a list filtered in filter group 2 to one template and batch that loses its only row to an action.
    // Fixtures: misc/lt-probes-needed-7/PnGQlFixtures.al. ----
    // Probed by corpus CI on BC 27.5, 28.5 and 29.0 (batch runs 39559542435, 39559572012, 39559599293; the same values on all three).
    // Results: after `Rec := Other` (another stored row, changed or not, or a temporary copy with changes) the list reads its rows again and
    // shows the other row with its STORED values; no OnModifyRecord or OnModify runs, at once, on Next or on Close, and nothing is stored.
    // With CurrPage.Close() in the action, Rec is the shown row again after the Close call. A list filtered to one template and batch (filter
    // group 2 or 0, Worksheet or List) that loses its only row to an action (with or without CurrPage.Update) shows its blank line three
    // times: each time the client validates Template and Batch with the filter values, then runs OnNewRecord (Rec stamped, xRec stamped
    // too) and OnAfterGetCurrRecord; a value typed there is inserted at Close with Line No. 10000.

    local procedure SeedQlRows()
    var
        Row: Record "LT QL Act Row";
        Log: Codeunit "LT PnG Log";
    begin
        Row.DeleteAll();
        Row."No." := 'A';
        Row.Name := 'orig A';
        Row.Qty := 1;
        Row.Insert();
        Row."No." := 'B';
        Row.Name := 'orig B';
        Row.Qty := 2;
        Row.Insert();
        Row."No." := 'C';
        Row.Name := 'orig C';
        Row.Qty := 3;
        Row.Insert();
        Log.Reset();
    end;

    local procedure QlRows(): Text
    var
        Row: Record "LT QL Act Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                if Result <> '' then
                    Result += ' ';
                Result += Row."No." + ':' + Row.Name + ',' + Format(Row.Qty);
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure QlTake(): Text
    var
        Log: Codeunit "LT PnG Log";
        Result: Text;
    begin
        Result := Log.Dump();
        Log.Reset();
        exit(Result);
    end;

    // Opens and closes the list once before the asserted tests: on BC 28.5 the first Close of the freshly published page once failed with
    // 'The page definition has changed while opening the page, please try to re-open the page.' (batch run 39560986109; a tier metadata
    // flake, not page behavior). Nothing is asserted here.
    [Test]
    procedure QL_RecAssign_WarmUp()
    var
        List: TestPage "LT QL Act List";
    begin
        SeedQlRows();
        if TryOpenQlList(List) then
            if TryCloseQlList(List) then;
        ClearLastError();
    end;

    [TryFunction]
    local procedure TryOpenQlList(var List: TestPage "LT QL Act List")
    begin
        List.OpenEdit();
    end;

    [Test]
    procedure QL_RecAssign_OtherChanged_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QL Act List";
    begin
        SeedQlRows();
        List.OpenEdit();
        Observer.Observe('log-open', QlTake());
        List.TakeOtherChanged.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('shown-after-action', List.NoF.Value() + ',' + List.NameF.Value());
        Observer.Observe('stored-after-action', QlRows());
        Observer.Observe('close-ok', Format(TryCloseQlList(List)));
        Observer.ObserveError('close');
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlRows());
        Observer.Expect('log-open', 'P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(A,orig A);P.AGR(A,orig A);P.AGCR(A,orig A x=,)');
        Observer.Expect('log-action', 'P.AGR(A,orig A);ACT.end(B,changed B x=A,orig A);P.AGR(B,changed B);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(B,orig B);P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(B,orig B);P.AGCR(B,orig B x=A,orig A)');
        Observer.Expect('shown-after-action', 'B,orig B');
        Observer.Expect('stored-after-action', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Expect('close-ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Verify();
    end;

    [Test]
    procedure QL_RecAssign_OtherChangedUpdate_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QL Act List";
    begin
        SeedQlRows();
        List.OpenEdit();
        Observer.Observe('log-open', QlTake());
        List.TakeOtherChangedUpdate.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('shown-after-action', List.NoF.Value() + ',' + List.NameF.Value());
        Observer.Observe('stored-after-action', QlRows());
        Observer.Observe('close-ok', Format(TryCloseQlList(List)));
        Observer.ObserveError('close');
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlRows());
        Observer.Expect('log-open', 'P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(A,orig A);P.AGR(A,orig A);P.AGCR(A,orig A x=,)');
        Observer.Expect('log-action', 'P.AGR(A,orig A);ACT.end(B,changed B x=A,orig A);P.AGR(B,changed B);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(B,orig B);P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(B,orig B);P.AGCR(B,orig B x=A,orig A)');
        Observer.Expect('shown-after-action', 'B,orig B');
        Observer.Expect('stored-after-action', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Expect('close-ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Verify();
    end;

    [Test]
    procedure QL_RecAssign_TempChanged_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QL Act List";
    begin
        SeedQlRows();
        List.OpenEdit();
        Observer.Observe('log-open', QlTake());
        List.TakeTempChanged.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('shown-after-action', List.NoF.Value() + ',' + List.NameF.Value());
        Observer.Observe('stored-after-action', QlRows());
        Observer.Observe('close-ok', Format(TryCloseQlList(List)));
        Observer.ObserveError('close');
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlRows());
        Observer.Expect('log-open', 'P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(A,orig A);P.AGR(A,orig A);P.AGCR(A,orig A x=,)');
        Observer.Expect('log-action', 'P.AGR(A,orig A);ACT.end(B,temp B x=A,orig A);P.AGR(B,temp B);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(B,orig B);P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(B,orig B);P.AGCR(B,orig B x=A,orig A)');
        Observer.Expect('shown-after-action', 'B,orig B');
        Observer.Expect('stored-after-action', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Expect('close-ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Verify();
    end;

    [Test]
    procedure QL_RecAssign_OtherUnchanged_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QL Act List";
    begin
        SeedQlRows();
        List.OpenEdit();
        Observer.Observe('log-open', QlTake());
        List.TakeOtherUnchanged.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('shown-after-action', List.NoF.Value() + ',' + List.NameF.Value());
        Observer.Observe('stored-after-action', QlRows());
        Observer.Observe('close-ok', Format(TryCloseQlList(List)));
        Observer.ObserveError('close');
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlRows());
        Observer.Expect('log-open', 'P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(A,orig A);P.AGR(A,orig A);P.AGCR(A,orig A x=,)');
        Observer.Expect('log-action', 'P.AGR(A,orig A);ACT.end(B,orig B x=A,orig A);P.AGR(B,orig B);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(B,orig B);P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(B,orig B);P.AGCR(B,orig B x=A,orig A)');
        Observer.Expect('shown-after-action', 'B,orig B');
        Observer.Expect('stored-after-action', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Expect('close-ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Verify();
    end;

    [Test]
    procedure QL_RecAssign_OwnRowChanged_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QL Act List";
    begin
        SeedQlRows();
        List.OpenEdit();
        Observer.Observe('log-open', QlTake());
        List.ChangeOwnRow.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('shown-after-action', List.NoF.Value() + ',' + List.NameF.Value());
        Observer.Observe('stored-after-action', QlRows());
        Observer.Observe('close-ok', Format(TryCloseQlList(List)));
        Observer.ObserveError('close');
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlRows());
        Observer.Expect('log-open', 'P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(A,orig A);P.AGR(A,orig A);P.AGCR(A,orig A x=,)');
        Observer.Expect('log-action', 'P.AGR(A,orig A);ACT.end(A,own changed x=A,orig A);P.AGR(A,own changed);P.MODR(A,own changed x=A,orig A);T.MOD(A,own changed x=A,orig A);P.AGR(A,own changed);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(A,own changed);P.AGR(A,own changed);P.AGCR(A,own changed x=A,own changed)');
        Observer.Expect('shown-after-action', 'A,own changed');
        Observer.Expect('stored-after-action', 'A:own changed,1 B:orig B,2 C:orig C,3');
        Observer.Expect('close-ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 'A:own changed,1 B:orig B,2 C:orig C,3');
        Observer.Verify();
    end;

    [Test]
    procedure QL_RecAssign_OtherChanged_StaysOpen_Next()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QL Act List";
    begin
        SeedQlRows();
        List.OpenEdit();
        QlTake();
        List.TakeOtherChanged.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('next', Format(List.Next()));
        Observer.Observe('log-next', QlTake());
        Observer.Observe('shown-after-next', List.NoF.Value() + ',' + List.NameF.Value());
        Observer.Observe('stored-after-next', QlRows());
        Observer.Observe('first', Format(List.First()));
        Observer.Observe('log-first', QlTake());
        Observer.Observe('shown-after-first', List.NoF.Value() + ',' + List.NameF.Value());
        Observer.Observe('close-ok', Format(TryCloseQlList(List)));
        Observer.ObserveError('close');
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlRows());
        Observer.Expect('log-action', 'P.AGR(A,orig A);ACT.end(B,changed B x=A,orig A);P.AGR(B,changed B);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(B,orig B);P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(B,orig B);P.AGCR(B,orig B x=A,orig A)');
        Observer.Expect('next', 'Yes');
        Observer.Expect('log-next', 'P.AGR(C,orig C);P.AGR(C,orig C);P.AGCR(C,orig C x=B,orig B)');
        Observer.Expect('shown-after-next', 'C,orig C');
        Observer.Expect('stored-after-next', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Expect('first', 'Yes');
        Observer.Expect('log-first', 'P.AGR(A,orig A);P.AGR(A,orig A);P.AGCR(A,orig A x=C,orig C)');
        Observer.Expect('shown-after-first', 'A,orig A');
        Observer.Expect('close-ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Verify();
    end;

    [Test]
    procedure QL_RecAssign_TempChanged_StaysOpen_Next()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QL Act List";
    begin
        SeedQlRows();
        List.OpenEdit();
        QlTake();
        List.TakeTempChanged.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('next', Format(List.Next()));
        Observer.Observe('log-next', QlTake());
        Observer.Observe('shown-after-next', List.NoF.Value() + ',' + List.NameF.Value());
        Observer.Observe('stored-after-next', QlRows());
        Observer.Observe('first', Format(List.First()));
        Observer.Observe('log-first', QlTake());
        Observer.Observe('shown-after-first', List.NoF.Value() + ',' + List.NameF.Value());
        Observer.Observe('close-ok', Format(TryCloseQlList(List)));
        Observer.ObserveError('close');
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlRows());
        Observer.Expect('log-action', 'P.AGR(A,orig A);ACT.end(B,temp B x=A,orig A);P.AGR(B,temp B);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(B,orig B);P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(B,orig B);P.AGCR(B,orig B x=A,orig A)');
        Observer.Expect('next', 'Yes');
        Observer.Expect('log-next', 'P.AGR(C,orig C);P.AGR(C,orig C);P.AGCR(C,orig C x=B,orig B)');
        Observer.Expect('shown-after-next', 'C,orig C');
        Observer.Expect('stored-after-next', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Expect('first', 'Yes');
        Observer.Expect('log-first', 'P.AGR(A,orig A);P.AGR(A,orig A);P.AGCR(A,orig A x=C,orig C)');
        Observer.Expect('shown-after-first', 'A,orig A');
        Observer.Expect('close-ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Verify();
    end;

    [Test]
    procedure QL_RecAssign_OtherChanged_CloseInAction()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QL Act List";
    begin
        SeedQlRows();
        List.OpenEdit();
        QlTake();
        List.TakeOtherChangedClose.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('stored-after-action', QlRows());
        Observer.Observe('close-ok', Format(TryCloseQlList(List)));
        Observer.ObserveError('close');
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlRows());
        Observer.Expect('log-action', 'P.AGR(A,orig A);P.AGR(A,orig A);ACT.end(A,orig A x=A,orig A);P.AGR(A,orig A)');
        Observer.Expect('stored-after-action', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Expect('close-ok', 'No');
        Observer.Expect('close|text', 'The TestPage is not open.');
        Observer.Expect('close|code', 'TestPageNotOpened');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryCloseQlList(var List: TestPage "LT QL Act List")
    begin
        List.Close();
    end;

    local procedure SeedQlJournal(WithOnlyRow: Boolean)
    var
        Line: Record "LT QL Jnl Line";
        Log: Codeunit "LT PnG Log";
    begin
        Line.DeleteAll();
        Line.Template := 'T1';
        Line.Batch := 'B2';
        Line."Line No." := 10000;
        Line.Descr := 'other batch';
        Line.Insert();
        Line.Template := 'T2';
        Line.Batch := 'B1';
        Line."Line No." := 10000;
        Line.Descr := 'other template';
        Line.Insert();
        if WithOnlyRow then begin
            Line.Template := 'T1';
            Line.Batch := 'B1';
            Line."Line No." := 10000;
            Line.Descr := 'only';
            Line.Insert();
        end;
        Log.Reset();
    end;

    local procedure QlJournal(): Text
    var
        Line: Record "LT QL Jnl Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                if Result <> '' then
                    Result += ' ';
                Result += Line.Template + '/' + Line.Batch + '/' + Format(Line."Line No.") + ':' + Line.Descr;
            until Line.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure QL_Jnl_SheetFG2_DeleteNoUpdate_OnlyRow()
    var
        Observer: Codeunit "Probe Observer";
        Jnl: TestPage "LT QL Jnl Sheet FG2";
    begin
        SeedQlJournal(true);
        Jnl.OpenEdit();
        Observer.Observe('log-open', QlTake());
        Jnl.DeleteNoUpdate.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('shown-after-action', Jnl.TemplateF.Value() + '/' + Jnl.BatchF.Value() + '/' + Jnl.LineNoF.Value() + ':' + Jnl.DescrF.Value());
        Observer.Observe('stored-after-action', QlJournal());
        Jnl.DescrF.SetValue('typed');
        Observer.Observe('log-typed', QlTake());
        Observer.Observe('shown-after-typed', Jnl.TemplateF.Value() + '/' + Jnl.BatchF.Value() + '/' + Jnl.LineNoF.Value() + ':' + Jnl.DescrF.Value());
        Jnl.Close();
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlJournal());
        Observer.Expect('log-open', 'P.AGR(T1/B1/10000);P.AGR(T1/B1/10000);P.AGCR(T1/B1/10000 x=T1/B1/0)');
        Observer.Expect('log-action', 'P.AGR(T1/B1/10000);T.Template.V(T1);T.Batch.V(B1);P.NEW(T1/B1/0 x=T1/B1/0 below=Yes);P.AGCR(T1/B1/0 x=T1/B1/0);T.Template.V(T1);T.Batch.V(B1);P.NEW(T1/B1/0 x=T1/B1/0 below=Yes);P.AGCR(T1/B1/0 x=T1/B1/0);T.Template.V(T1);T.Batch.V(B1);P.NEW(T1/B1/0 x=T1/B1/0 below=Yes);P.AGCR(T1/B1/0 x=T1/B1/0)');
        Observer.Expect('shown-after-action', 'T1/B1/0:');
        Observer.Expect('stored-after-action', 'T1/B2/10000:other batch T2/B1/10000:other template');
        Observer.Expect('log-typed', '');
        Observer.Expect('shown-after-typed', 'T1/B1/0:typed');
        Observer.Expect('log-close', 'P.INSR(T1/B1/10000,typed);T.INS(T1/B1/10000,typed)');
        Observer.Expect('stored-after-close', 'T1/B1/10000:typed T1/B2/10000:other batch T2/B1/10000:other template');
        Observer.Verify();
    end;

    [Test]
    procedure QL_Jnl_SheetFG2_DeleteWithUpdate_OnlyRow()
    var
        Observer: Codeunit "Probe Observer";
        Jnl: TestPage "LT QL Jnl Sheet FG2";
    begin
        SeedQlJournal(true);
        Jnl.OpenEdit();
        Observer.Observe('log-open', QlTake());
        Jnl.DeleteWithUpdate.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('shown-after-action', Jnl.TemplateF.Value() + '/' + Jnl.BatchF.Value() + '/' + Jnl.LineNoF.Value() + ':' + Jnl.DescrF.Value());
        Observer.Observe('stored-after-action', QlJournal());
        Jnl.DescrF.SetValue('typed');
        Observer.Observe('log-typed', QlTake());
        Observer.Observe('shown-after-typed', Jnl.TemplateF.Value() + '/' + Jnl.BatchF.Value() + '/' + Jnl.LineNoF.Value() + ':' + Jnl.DescrF.Value());
        Jnl.Close();
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlJournal());
        Observer.Expect('log-open', 'P.AGR(T1/B1/10000);P.AGR(T1/B1/10000);P.AGCR(T1/B1/10000 x=T1/B1/0)');
        Observer.Expect('log-action', 'P.AGR(T1/B1/10000);T.Template.V(T1);T.Batch.V(B1);P.NEW(T1/B1/0 x=T1/B1/0 below=Yes);P.AGCR(T1/B1/0 x=T1/B1/0);T.Template.V(T1);T.Batch.V(B1);P.NEW(T1/B1/0 x=T1/B1/0 below=Yes);P.AGCR(T1/B1/0 x=T1/B1/0);T.Template.V(T1);T.Batch.V(B1);P.NEW(T1/B1/0 x=T1/B1/0 below=Yes);P.AGCR(T1/B1/0 x=T1/B1/0)');
        Observer.Expect('shown-after-action', 'T1/B1/0:');
        Observer.Expect('stored-after-action', 'T1/B2/10000:other batch T2/B1/10000:other template');
        Observer.Expect('log-typed', '');
        Observer.Expect('shown-after-typed', 'T1/B1/0:typed');
        Observer.Expect('log-close', 'P.INSR(T1/B1/10000,typed);T.INS(T1/B1/10000,typed)');
        Observer.Expect('stored-after-close', 'T1/B1/10000:typed T1/B2/10000:other batch T2/B1/10000:other template');
        Observer.Verify();
    end;

    [Test]
    procedure QL_Jnl_ListFG2_DeleteWithUpdate_OnlyRow()
    var
        Observer: Codeunit "Probe Observer";
        Jnl: TestPage "LT QL Jnl List FG2";
    begin
        SeedQlJournal(true);
        Jnl.OpenEdit();
        Observer.Observe('log-open', QlTake());
        Jnl.DeleteWithUpdate.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('shown-after-action', Jnl.TemplateF.Value() + '/' + Jnl.BatchF.Value() + '/' + Jnl.LineNoF.Value() + ':' + Jnl.DescrF.Value());
        Observer.Observe('stored-after-action', QlJournal());
        Jnl.DescrF.SetValue('typed');
        Observer.Observe('log-typed', QlTake());
        Observer.Observe('shown-after-typed', Jnl.TemplateF.Value() + '/' + Jnl.BatchF.Value() + '/' + Jnl.LineNoF.Value() + ':' + Jnl.DescrF.Value());
        Jnl.Close();
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlJournal());
        Observer.Expect('log-open', 'P.AGR(T1/B1/10000);P.AGR(T1/B1/10000);P.AGCR(T1/B1/10000 x=T1/B1/0)');
        Observer.Expect('log-action', 'P.AGR(T1/B1/10000);T.Template.V(T1);T.Batch.V(B1);P.NEW(T1/B1/0 x=T1/B1/0 below=Yes);P.AGCR(T1/B1/0 x=T1/B1/0);T.Template.V(T1);T.Batch.V(B1);P.NEW(T1/B1/0 x=T1/B1/0 below=Yes);P.AGCR(T1/B1/0 x=T1/B1/0);T.Template.V(T1);T.Batch.V(B1);P.NEW(T1/B1/0 x=T1/B1/0 below=Yes);P.AGCR(T1/B1/0 x=T1/B1/0)');
        Observer.Expect('shown-after-action', 'T1/B1/0:');
        Observer.Expect('stored-after-action', 'T1/B2/10000:other batch T2/B1/10000:other template');
        Observer.Expect('log-typed', '');
        Observer.Expect('shown-after-typed', 'T1/B1/0:typed');
        Observer.Expect('log-close', 'P.INSR(T1/B1/10000,typed);T.INS(T1/B1/10000,typed)');
        Observer.Expect('stored-after-close', 'T1/B1/10000:typed T1/B2/10000:other batch T2/B1/10000:other template');
        Observer.Verify();
    end;

    [Test]
    procedure QL_Jnl_SheetFG0_DeleteWithUpdate_OnlyRow()
    var
        Observer: Codeunit "Probe Observer";
        Jnl: TestPage "LT QL Jnl Sheet FG0";
    begin
        SeedQlJournal(true);
        Jnl.OpenEdit();
        Observer.Observe('log-open', QlTake());
        Jnl.DeleteWithUpdate.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('shown-after-action', Jnl.TemplateF.Value() + '/' + Jnl.BatchF.Value() + '/' + Jnl.LineNoF.Value() + ':' + Jnl.DescrF.Value());
        Observer.Observe('stored-after-action', QlJournal());
        Jnl.DescrF.SetValue('typed');
        Observer.Observe('log-typed', QlTake());
        Observer.Observe('shown-after-typed', Jnl.TemplateF.Value() + '/' + Jnl.BatchF.Value() + '/' + Jnl.LineNoF.Value() + ':' + Jnl.DescrF.Value());
        Jnl.Close();
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlJournal());
        Observer.Expect('log-open', 'P.AGR(T1/B1/10000);P.AGR(T1/B1/10000);P.AGCR(T1/B1/10000 x=T1/B1/0)');
        Observer.Expect('log-action', 'P.AGR(T1/B1/10000);T.Template.V(T1);T.Batch.V(B1);P.NEW(T1/B1/0 x=T1/B1/0 below=Yes);P.AGCR(T1/B1/0 x=T1/B1/0);T.Template.V(T1);T.Batch.V(B1);P.NEW(T1/B1/0 x=T1/B1/0 below=Yes);P.AGCR(T1/B1/0 x=T1/B1/0);T.Template.V(T1);T.Batch.V(B1);P.NEW(T1/B1/0 x=T1/B1/0 below=Yes);P.AGCR(T1/B1/0 x=T1/B1/0)');
        Observer.Expect('shown-after-action', 'T1/B1/0:');
        Observer.Expect('stored-after-action', 'T1/B2/10000:other batch T2/B1/10000:other template');
        Observer.Expect('log-typed', '');
        Observer.Expect('shown-after-typed', 'T1/B1/0:typed');
        Observer.Expect('log-close', 'P.INSR(T1/B1/10000,typed);T.INS(T1/B1/10000,typed)');
        Observer.Expect('stored-after-close', 'T1/B1/10000:typed T1/B2/10000:other batch T2/B1/10000:other template');
        Observer.Verify();
    end;

    [Test]
    procedure QL_Jnl_SheetFG2_OpenOnNoRow()
    var
        Observer: Codeunit "Probe Observer";
        Jnl: TestPage "LT QL Jnl Sheet FG2";
    begin
        SeedQlJournal(false);
        Jnl.OpenEdit();
        Observer.Observe('log-open', QlTake());
        Observer.Observe('shown-after-open', Jnl.TemplateF.Value() + '/' + Jnl.BatchF.Value() + '/' + Jnl.LineNoF.Value() + ':' + Jnl.DescrF.Value());
        Jnl.DescrF.SetValue('typed');
        Observer.Observe('log-typed', QlTake());
        Jnl.Close();
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlJournal());
        Observer.Expect('log-open', 'T.Template.V(T1);T.Batch.V(B1);P.NEW(T1/B1/0 x=//0 below=Yes);P.AGCR(T1/B1/0 x=T1/B1/0);T.Template.V(T1);T.Batch.V(B1);P.NEW(T1/B1/0 x=//0 below=Yes);P.AGCR(T1/B1/0 x=T1/B1/0)');
        Observer.Expect('shown-after-open', 'T1/B1/0:');
        Observer.Expect('log-typed', '');
        Observer.Expect('log-close', 'P.INSR(T1/B1/10000,typed);T.INS(T1/B1/10000,typed)');
        Observer.Expect('stored-after-close', 'T1/B1/10000:typed T1/B2/10000:other batch T2/B1/10000:other template');
        Observer.Verify();
    end;

    // ---- Writer QN (2026-10-21), al-runtime-rs PR 5594: CurrPage.Close() in a list action after `Rec := Other` on pages with OnQueryClosePage
    // and OnClosePage (Worksheet LT QN Close Sheet, List LT QN Close List; fixtures in PnGQlFixtures.al): the order of the close triggers and
    // the shown-row read back, Rec and xRec in each; also opened with Page.RunModal and closed from the action inside a ModalPageHandler. ----
    // Probed by corpus CI on BC 29.0 (batch run 39595069689); 27.5 and 28.5 by the final check.
    // Results: with CurrPage.Close() in the action the shown row is read back (OnAfterGetRecord) BEFORE the close triggers, so
    // OnQueryClosePage (CloseAction OK, or LookupCancel under Page.RunModal) and then OnClosePage see the shown row as Rec and xRec; then the
    // action goes on with Rec the shown row, and one more OnAfterGetRecord follows. Nothing is stored, also when the action changed a field of
    // its own row before Close (no OnModifyRecord). Worksheet and List alike; Page.RunModal returns LookupCancel and leaves the record var on
    // the first row. Without Close in the action, a later TestPage.Close() runs the close triggers on the other row with its stored values.

    [Test]
    procedure QN_CloseQ_WarmUp()
    var
        Sheet: TestPage "LT QN Close Sheet";
        List: TestPage "LT QN Close List";
    begin
        SeedQlRows();
        if TryOpenQnSheet(Sheet) then
            if TryCloseQnSheet(Sheet) then;
        if TryOpenQnList(List) then
            if TryCloseQnList(List) then;
        ClearLastError();
    end;

    // Opens and closes each new page once before the asserted tests (see QL_RecAssign_WarmUp: a first Close of a freshly published page once
    // failed on BC 28.5 with 'The page definition has changed'). The close triggers log, which fails inside a TryFunction; nothing is asserted.
    [TryFunction]
    local procedure TryOpenQnSheet(var Sheet: TestPage "LT QN Close Sheet")
    begin
        Sheet.OpenView();
    end;

    [TryFunction]
    local procedure TryCloseQnSheet(var Sheet: TestPage "LT QN Close Sheet")
    begin
        Sheet.Close();
    end;

    [TryFunction]
    local procedure TryOpenQnList(var List: TestPage "LT QN Close List")
    begin
        List.OpenView();
    end;

    [TryFunction]
    local procedure TryCloseQnList(var List: TestPage "LT QN Close List")
    begin
        List.Close();
    end;

    [Test]
    procedure QN_CloseQ_Sheet_OtherChanged_CloseInAction()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QN Close Sheet";
    begin
        SeedQlRows();
        List.OpenEdit();
        Observer.Observe('log-open', QlTake());
        List.TakeOtherChangedClose.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('stored-after-action', QlRows());
        asserterror List.Close();
        Observer.ObserveError('close');
        Observer.Expect('log-open', 'P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(A,orig A);P.AGR(A,orig A);P.AGCR(A,orig A x=,)');
        Observer.Expect('log-action', 'P.AGR(A,orig A);P.AGR(A,orig A);P.QCP(A,orig A x=A,orig A a=OK);P.CP(A,orig A x=A,orig A);ACT.end(A,orig A x=A,orig A);P.AGR(A,orig A)');
        Observer.Expect('stored-after-action', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Expect('close|text', 'The TestPage is not open.');
        Observer.Expect('close|code', 'TestPageNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure QN_CloseQ_Sheet_OtherUnchanged_CloseInAction()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QN Close Sheet";
    begin
        SeedQlRows();
        List.OpenEdit();
        Observer.Observe('log-open', QlTake());
        List.TakeOtherUnchangedClose.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('stored-after-action', QlRows());
        asserterror List.Close();
        Observer.ObserveError('close');
        Observer.Expect('log-open', 'P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(A,orig A);P.AGR(A,orig A);P.AGCR(A,orig A x=,)');
        Observer.Expect('log-action', 'P.AGR(A,orig A);P.AGR(A,orig A);P.QCP(A,orig A x=A,orig A a=OK);P.CP(A,orig A x=A,orig A);ACT.end(A,orig A x=A,orig A);P.AGR(A,orig A)');
        Observer.Expect('stored-after-action', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Expect('close|text', 'The TestPage is not open.');
        Observer.Expect('close|code', 'TestPageNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure QN_CloseQ_Sheet_TempChanged_CloseInAction()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QN Close Sheet";
    begin
        SeedQlRows();
        List.OpenEdit();
        Observer.Observe('log-open', QlTake());
        List.TakeTempChangedClose.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('stored-after-action', QlRows());
        asserterror List.Close();
        Observer.ObserveError('close');
        Observer.Expect('log-open', 'P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(A,orig A);P.AGR(A,orig A);P.AGCR(A,orig A x=,)');
        Observer.Expect('log-action', 'P.AGR(A,orig A);P.AGR(A,orig A);P.QCP(A,orig A x=A,orig A a=OK);P.CP(A,orig A x=A,orig A);ACT.end(A,orig A x=A,orig A);P.AGR(A,orig A)');
        Observer.Expect('stored-after-action', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Expect('close|text', 'The TestPage is not open.');
        Observer.Expect('close|code', 'TestPageNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure QN_CloseQ_Sheet_OwnRowChanged_CloseInAction()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QN Close Sheet";
    begin
        SeedQlRows();
        List.OpenEdit();
        Observer.Observe('log-open', QlTake());
        List.ChangeOwnRowClose.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('stored-after-action', QlRows());
        asserterror List.Close();
        Observer.ObserveError('close');
        Observer.Expect('log-open', 'P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(A,orig A);P.AGR(A,orig A);P.AGCR(A,orig A x=,)');
        Observer.Expect('log-action', 'P.AGR(A,orig A);P.QCP(A,orig A x=A,orig A a=OK);P.CP(A,orig A x=A,orig A);ACT.end(A,orig A x=A,orig A);P.AGR(A,orig A)');
        Observer.Expect('stored-after-action', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Expect('close|text', 'The TestPage is not open.');
        Observer.Expect('close|code', 'TestPageNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure QN_CloseQ_Sheet_NoChange_CloseInAction()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QN Close Sheet";
    begin
        SeedQlRows();
        List.OpenEdit();
        Observer.Observe('log-open', QlTake());
        List.CloseOnly.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('stored-after-action', QlRows());
        asserterror List.Close();
        Observer.ObserveError('close');
        Observer.Expect('log-open', 'P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(A,orig A);P.AGR(A,orig A);P.AGCR(A,orig A x=,)');
        Observer.Expect('log-action', 'P.AGR(A,orig A);P.QCP(A,orig A x=A,orig A a=OK);P.CP(A,orig A x=A,orig A);ACT.end(A,orig A x=A,orig A);P.AGR(A,orig A)');
        Observer.Expect('stored-after-action', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Expect('close|text', 'The TestPage is not open.');
        Observer.Expect('close|code', 'TestPageNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure QN_CloseQ_Sheet_OtherChanged_ThenTestPageClose()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QN Close Sheet";
    begin
        SeedQlRows();
        List.OpenEdit();
        QlTake();
        List.TakeOtherChanged.Invoke();
        Observer.Observe('log-action', QlTake());
        List.Close();
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlRows());
        Observer.Expect('log-action', 'P.AGR(A,orig A);ACT.end(B,changed B x=A,orig A);P.AGR(B,changed B);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(B,orig B);P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(B,orig B);P.AGCR(B,orig B x=A,orig A)');
        Observer.Expect('log-close', 'P.QCP(B,orig B x=B,orig B a=OK);P.CP(B,orig B x=B,orig B)');
        Observer.Expect('stored-after-close', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QnCloseSheetOtherChangedHandler')]
    procedure QN_CloseQ_Sheet_RunModal_OtherChanged_CloseInAction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QL Act Row";
        Result: Action;
    begin
        SeedQlRows();
        Result := Page.RunModal(Page::"LT QN Close Sheet", Row);
        Observer.Observe('run-modal-result', Format(Result));
        Observer.Observe('row-after', Row."No." + ',' + Row.Name);
        Observer.Observe('log', QlTake());
        Observer.Observe('stored-after', QlRows());
        Observer.Expect('run-modal-result', 'LookupCancel');
        Observer.Expect('row-after', 'A,orig A');
        Observer.Expect('log', 'P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(A,orig A);P.AGR(A,orig A);P.AGCR(A,orig A x=,);MPH.in;P.AGR(A,orig A);P.AGR(A,orig A);P.QCP(A,orig A x=A,orig A a=LookupCancel);P.CP(A,orig A x=A,orig A);ACT.end(A,orig A x=A,orig A);P.AGR(A,orig A);MPH.out');
        Observer.Expect('stored-after', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure QnCloseSheetOtherChangedHandler(var List: TestPage "LT QN Close Sheet")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('MPH.in');
        List.TakeOtherChangedClose.Invoke();
        Log.Add('MPH.out');
    end;

    [Test]
    procedure QN_CloseQ_List_OtherChanged_CloseInAction()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QN Close List";
    begin
        SeedQlRows();
        List.OpenEdit();
        Observer.Observe('log-open', QlTake());
        List.TakeOtherChangedClose.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('stored-after-action', QlRows());
        asserterror List.Close();
        Observer.ObserveError('close');
        Observer.Expect('log-open', 'P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(A,orig A);P.AGR(A,orig A);P.AGCR(A,orig A x=,)');
        Observer.Expect('log-action', 'P.AGR(A,orig A);P.AGR(A,orig A);P.QCP(A,orig A x=A,orig A a=OK);P.CP(A,orig A x=A,orig A);ACT.end(A,orig A x=A,orig A);P.AGR(A,orig A)');
        Observer.Expect('stored-after-action', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Expect('close|text', 'The TestPage is not open.');
        Observer.Expect('close|code', 'TestPageNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure QN_CloseQ_List_OwnRowChanged_CloseInAction()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QN Close List";
    begin
        SeedQlRows();
        List.OpenEdit();
        Observer.Observe('log-open', QlTake());
        List.ChangeOwnRowClose.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('stored-after-action', QlRows());
        asserterror List.Close();
        Observer.ObserveError('close');
        Observer.Expect('log-open', 'P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(A,orig A);P.AGR(A,orig A);P.AGCR(A,orig A x=,)');
        Observer.Expect('log-action', 'P.AGR(A,orig A);P.QCP(A,orig A x=A,orig A a=OK);P.CP(A,orig A x=A,orig A);ACT.end(A,orig A x=A,orig A);P.AGR(A,orig A)');
        Observer.Expect('stored-after-action', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Expect('close|text', 'The TestPage is not open.');
        Observer.Expect('close|code', 'TestPageNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure QN_CloseQ_List_NoChange_CloseInAction()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QN Close List";
    begin
        SeedQlRows();
        List.OpenEdit();
        Observer.Observe('log-open', QlTake());
        List.CloseOnly.Invoke();
        Observer.Observe('log-action', QlTake());
        Observer.Observe('stored-after-action', QlRows());
        asserterror List.Close();
        Observer.ObserveError('close');
        Observer.Expect('log-open', 'P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(A,orig A);P.AGR(A,orig A);P.AGCR(A,orig A x=,)');
        Observer.Expect('log-action', 'P.AGR(A,orig A);P.QCP(A,orig A x=A,orig A a=OK);P.CP(A,orig A x=A,orig A);ACT.end(A,orig A x=A,orig A);P.AGR(A,orig A)');
        Observer.Expect('stored-after-action', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Expect('close|text', 'The TestPage is not open.');
        Observer.Expect('close|code', 'TestPageNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure QN_CloseQ_List_OtherChanged_ThenTestPageClose()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QN Close List";
    begin
        SeedQlRows();
        List.OpenEdit();
        QlTake();
        List.TakeOtherChanged.Invoke();
        Observer.Observe('log-action', QlTake());
        List.Close();
        Observer.Observe('log-close', QlTake());
        Observer.Observe('stored-after-close', QlRows());
        Observer.Expect('log-action', 'P.AGR(A,orig A);ACT.end(B,changed B x=A,orig A);P.AGR(B,changed B);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(B,orig B);P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(B,orig B);P.AGCR(B,orig B x=A,orig A)');
        Observer.Expect('log-close', 'P.QCP(B,orig B x=B,orig B a=OK);P.CP(B,orig B x=B,orig B)');
        Observer.Expect('stored-after-close', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QnCloseListOtherChangedHandler')]
    procedure QN_CloseQ_List_RunModal_OtherChanged_CloseInAction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QL Act Row";
        Result: Action;
    begin
        SeedQlRows();
        Result := Page.RunModal(Page::"LT QN Close List", Row);
        Observer.Observe('run-modal-result', Format(Result));
        Observer.Observe('row-after', Row."No." + ',' + Row.Name);
        Observer.Observe('log', QlTake());
        Observer.Observe('stored-after', QlRows());
        Observer.Expect('run-modal-result', 'LookupCancel');
        Observer.Expect('row-after', 'A,orig A');
        Observer.Expect('log', 'P.AGR(A,orig A);P.AGR(B,orig B);P.AGR(C,orig C);P.AGR(A,orig A);P.AGR(A,orig A);P.AGCR(A,orig A x=,);MPH.in;P.AGR(A,orig A);P.AGR(A,orig A);P.QCP(A,orig A x=A,orig A a=LookupCancel);P.CP(A,orig A x=A,orig A);ACT.end(A,orig A x=A,orig A);P.AGR(A,orig A);MPH.out');
        Observer.Expect('stored-after', 'A:orig A,1 B:orig B,2 C:orig C,3');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure QnCloseListOtherChangedHandler(var List: TestPage "LT QN Close List")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('MPH.in');
        List.TakeOtherChangedClose.Invoke();
        Log.Add('MPH.out');
    end;
}
