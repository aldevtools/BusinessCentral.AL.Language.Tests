// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 79600, log codeunit 79601, pages 79610-79619 (ApObjects.al)
// Settles corpus issue 642 (TestPage behavior, part 3), items 1-18. The log tokens are listed at the top of ApObjects.al.

codeunit 79650 "LT AP TestPage Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        HandlerFilter: Text;

    local procedure Seed()
    var
        Row: Record "LT AP Row";
    begin
        Row.DeleteAll();
        AddRow('A', 'Alpha', true, 'G1');
        AddRow('B', 'Beta', false, 'G1');
        AddRow('C', 'Charlie', true, 'G2');
        AddRow('D', 'Delta', false, 'G2');
    end;

    local procedure AddRow(NewCode: Code[20]; NewName: Text[50]; NewFlag: Boolean; NewGrp: Code[10])
    var
        Row: Record "LT AP Row";
    begin
        Row.Init();
        Row."Code" := NewCode;
        Row.Name := NewName;
        Row.Flag := NewFlag;
        Row.Grp := NewGrp;
        Row.Txt := 'txt';
        Row.Insert();
    end;

    local procedure Rows(var P: TestPage "LT AP List"): Text
    var
        Result: Text;
    begin
        if P.First() then
            repeat
                Result += P."Code".Value() + ',';
            until not P.Next();
        exit(Result);
    end;

    local procedure Start()
    var
        Log: Codeunit "LT AP Log";
    begin
        Clear(Observer);
        Log.Take();
    end;

    // ---- item 1: a part page with a group named Page and a part page with a field named Page; CurrPage.Part.Page.Proc() ----

    [Test]
    procedure Ap01_PartPage_ControlNamedPage()
    var
        Log: Codeunit "LT AP Log";
        Host: TestPage "LT AP Host";
    begin
        Start();
        Seed();
        Host.OpenView();
        Host.GoToKey('B');
        Log.Take();
        Host.CallG.Invoke();
        Host.CallF.Invoke();
        Observer.Observe('log', Log.Take());
        Observer.Observe('g-name', Host.PartG.Name.Value());
        Observer.Observe('f-page', Host.PartF."Page".Value());
        Host.Close();
        Observer.Expect('log', 'PGB;PFB;');
        Observer.Expect('g-name', 'Beta');
        Observer.Expect('f-page', 'Beta');
        Observer.Verify();
    end;

    // ---- item 2: OpenNew, Filter.SetFilter on a key field / a non-key field, then SetValue on a non-key field ----

    local procedure Stored(Prefix: Text)
    var
        Row: Record "LT AP Row";
    begin
        Observer.Observe(Prefix + '-count', Format(Row.Count()));
        if Row.FindFirst() then
            Observer.Observe(Prefix + '-row', Row."Code" + '|' + Row.Name + '|' + Row.Grp);
    end;

    [Test]
    procedure Ap02_OpenNew_KeyFilter_SetValue()
    var
        Row: Record "LT AP Row";
        Log: Codeunit "LT AP Log";
        P: TestPage "LT AP List";
    begin
        Start();
        Row.DeleteAll();
        P.OpenNew();
        Observer.Observe('open', Log.Take());
        P.Filter.SetFilter("Code", 'K1');
        Observer.Observe('filter', Log.Take());
        Observer.Observe('code-on-page', P."Code".Value());
        P.Name.SetValue('typed');
        Observer.Observe('setvalue', Log.Take());
        Stored('sv');
        P.Close();
        Observer.Observe('close', Log.Take());
        Stored('closed');
        Observer.Expect('open', 'O;W;C;');
        Observer.Expect('filter', 'W;CK1;W;CK1;');
        Observer.Expect('code-on-page', 'K1');
        Observer.Expect('setvalue', '');
        Observer.Expect('sv-count', '0');
        Observer.Expect('close', 'IK1/typed;Q;');
        Observer.Expect('closed-count', '1');
        Observer.Expect('closed-row', 'K1|typed|');
        Observer.Verify();
    end;

    [Test]
    procedure Ap02_OpenNew_NonKeyFilter_SetValue()
    var
        Row: Record "LT AP Row";
        Log: Codeunit "LT AP Log";
        P: TestPage "LT AP List";
    begin
        Start();
        Row.DeleteAll();
        P.OpenNew();
        Observer.Observe('open', Log.Take());
        P.Filter.SetFilter(Grp, 'G7');
        Observer.Observe('filter', Log.Take());
        Observer.Observe('grp-on-page', P.Grp.Value());
        P.Name.SetValue('typed');
        Observer.Observe('setvalue', Log.Take());
        Stored('sv');
        P.Close();
        Observer.Observe('close', Log.Take());
        Stored('closed');
        Observer.Expect('open', 'O;W;C;');
        Observer.Expect('filter', 'W;C;W;C;');
        Observer.Expect('grp-on-page', '');
        Observer.Expect('setvalue', '');
        Observer.Expect('sv-count', '0');
        Observer.Expect('close', 'I/typed;Q;');
        Observer.Expect('closed-count', '1');
        Observer.Expect('closed-row', '|typed|');
        Observer.Verify();
    end;

    // ---- item 3: an empty list shows a row inserted by page code; reads of the action and of First() apart ----

    [Test]
    procedure Ap03_EmptyList_RowInsertedByAction()
    var
        Row: Record "LT AP Row";
        Log: Codeunit "LT AP Log";
        P: TestPage "LT AP List";
    begin
        Start();
        Row.DeleteAll();
        P.OpenEdit();
        Observer.Observe('open', Log.Take());
        P.InsertViaRec.Invoke();
        Observer.Observe('action', Log.Take());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first-log', Log.Take());
        Observer.Observe('code', P."Code".Value());
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next-log', Log.Take());
        P.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', 'O;W;C;W;C;');
        Observer.Expect('action', 'ins;RNEW1;RNEW1;RNEW1;CNEW1;');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first-log', '');
        Observer.Expect('code', 'NEW1');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next-log', 'W;C;');
        Observer.Expect('close', 'Q;');
        Observer.Verify();
    end;

    // ---- item 4: Filter.SetFilter on a Boolean field (non-modal list) and a Text field filter on a modal list ----

    local procedure BoolFilter(Word: Text)
    var
        P: TestPage "LT AP List";
    begin
        P.OpenView();
        P.Filter.SetFilter(Flag, Word);
        Observer.Observe(Word + '-filter', P.Filter.GetFilter(Flag));
        Observer.Observe(Word + '-rows', Rows(P));
        P.Close();
    end;

    [Test]
    procedure Ap04_BooleanFilter_NonModalList()
    begin
        Start();
        Seed();
        BoolFilter('Yes');
        BoolFilter('No');
        BoolFilter('true');
        BoolFilter('false');
        Observer.Expect('Yes-filter', 'Yes');
        Observer.Expect('Yes-rows', 'A,C,');
        Observer.Expect('No-filter', 'No');
        Observer.Expect('No-rows', 'B,D,');
        Observer.Expect('true-filter', '');
        Observer.Expect('true-rows', 'A,B,C,D,');
        Observer.Expect('false-filter', '');
        Observer.Expect('false-rows', 'A,B,C,D,');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure FilterModalHandler(var P: TestPage "LT AP List")
    begin
        Observer.Observe('before', Rows(P));
        P.Filter.SetFilter(Name, HandlerFilter);
        Observer.Observe('filter', P.Filter.GetFilter(Name));
        Observer.Observe('after', Rows(P));
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('FilterModalHandler')]
    procedure Ap04_TextFilter_ModalList()
    var
        Row: Record "LT AP Row";
    begin
        Start();
        Seed();
        HandlerFilter := 'B*|D*';
        Page.RunModal(Page::"LT AP List", Row);
        Observer.Expect('before', 'A,B,C,D,,');
        Observer.Expect('filter', 'B*|D*');
        Observer.Expect('after', 'B,D,,');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure BoolModalHandler(var P: TestPage "LT AP List")
    begin
        P.Filter.SetFilter(Flag, HandlerFilter);
        Observer.Observe(HandlerFilter + '-filter', P.Filter.GetFilter(Flag));
        Observer.Observe(HandlerFilter + '-rows', Rows(P));
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('BoolModalHandler')]
    procedure Ap04_BooleanFilter_ModalList()
    var
        Row: Record "LT AP Row";
    begin
        Start();
        Seed();
        HandlerFilter := 'Yes';
        Page.RunModal(Page::"LT AP List", Row);
        HandlerFilter := 'false';
        Page.RunModal(Page::"LT AP List", Row);
        Observer.Expect('Yes-filter', 'Yes');
        Observer.Expect('Yes-rows', 'A,C,,');
        Observer.Expect('false-filter', '');
        Observer.Expect('false-rows', 'A,B,C,D,,');
        Observer.Verify();
    end;

    // ---- item 5: Page.RunModal over a temporary record: reads, where New() rows go ----

    [ModalPageHandler]
    procedure TempNewHandler(var P: TestPage "LT AP List")
    var
        Log: Codeunit "LT AP Log";
    begin
        Observer.Observe('h-open', Log.Take());
        Observer.Observe('h-cur', P."Code".Value());
        Observer.Observe('h-rows', Rows(P));
        Observer.Observe('h-walk', Log.Take());
        P.First();
        P.New();
        P."Code".SetValue('T4');
        P.Name.SetValue('n4');
        P.New();
        P."Code".SetValue('T0');
        P.Name.SetValue('n0');
        Observer.Observe('h-new', Log.Take());
        Observer.Observe('h-rows2', Rows(P));
        Log.Take();
        P.OK().Invoke();
        Observer.Observe('h-ok', Log.Take());
    end;

    [Test]
    [HandlerFunctions('TempNewHandler')]
    procedure Ap05_RunModal_TempRecord_NewRows()
    var
        Temp: Record "LT AP Row" temporary;
        Log: Codeunit "LT AP Log";
        Shown: Text;
    begin
        Start();
        Seed();
        Temp."Code" := 'T1';
        Temp.Name := 't1';
        Temp.Insert();
        Temp."Code" := 'T3';
        Temp.Name := 't3';
        Temp.Insert();
        Temp."Code" := 'T5';
        Temp.Name := 't5';
        Temp.Insert();
        Observer.Observe('result', Format(Page.RunModal(Page::"LT AP List", Temp)));
        Observer.Observe('after', Log.Take());
        Temp.Reset();
        if Temp.FindSet() then
            repeat
                Shown += Temp."Code" + ',';
            until Temp.Next() = 0;
        Observer.Observe('temp', Shown);
        Observer.Expect('h-open', 'O;RT5;RT3;RT1;RT5;RT5;CT5;');
        Observer.Expect('h-cur', 'T5');
        Observer.Expect('h-rows', 'T1,T3,T5,');
        Observer.Expect('h-walk', 'RT1;RT1;CT1;RT3;RT3;CT3;RT5;RT5;CT5;');
        Observer.Expect('h-new', 'RT1;RT1;CT1;W;C;IT4/n4;W;C;');
        Observer.Expect('h-rows2', 'T1,T4,T0,T3,T5,');
        Observer.Expect('h-ok', 'Q;');
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('after', '');
        Observer.Expect('temp', 'T0,T1,T3,T4,T5,');
        Observer.Verify();
    end;

    // ---- item 6: the same OnValidate error on a card, a list and a list part ----

    [Test]
    procedure Ap06_ValidationError_Card()
    var
        P: TestPage "LT AP Card";
    begin
        Start();
        Seed();
        P.OpenEdit();
        P.GoToKey('A');
        asserterror P.Val.SetValue('BAD');
        Observer.ObserveError('card');
        Observer.Expect('card|text', 'Validation error for Field: Val,  Message = ''LT AP bad value BAD (Select Refresh to discard errors)''');
        Observer.Expect('card|code', 'TestValidation');
        Observer.Verify();
    end;

    [Test]
    procedure Ap06_ValidationError_List()
    var
        P: TestPage "LT AP List";
    begin
        Start();
        Seed();
        P.OpenEdit();
        P.GoToKey('A');
        asserterror P.Val.SetValue('BAD');
        Observer.ObserveError('list');
        Observer.Expect('list|text', 'Validation error for Field: Val,  Message = ''LT AP bad value BAD''');
        Observer.Expect('list|code', 'TestValidation');
        Observer.Verify();
    end;

    [Test]
    procedure Ap06_ValidationError_ListPart()
    var
        P: TestPage "LT AP Host";
    begin
        Start();
        Seed();
        P.OpenEdit();
        P.GoToKey('A');
        asserterror P.PartF.Val.SetValue('BAD');
        Observer.ObserveError('listpart');
        Observer.Expect('listpart|text', 'Validation error for Field: Val,  Message = ''LT AP bad value BAD''');
        Observer.Expect('listpart|code', 'TestValidation');
        Observer.Verify();
    end;

    // ---- items 7 and 18: ShowMandatory of Text and Code fields with and without NotBlank, and of page variables ----

    local procedure Mand(var P: TestPage "LT AP Card"; Name: Text)
    begin
        Observer.Observe(Name, 'Code=' + Format(P."Code".ShowMandatory()) + ' Name=' + Format(P.Name.ShowMandatory()) + ' Txt=' + Format(P.Txt.ShowMandatory()) + ' Cd=' + Format(P.Cd.ShowMandatory()) +
            ' TxtNB=' + Format(P.TxtNB.ShowMandatory()) + ' CdNB=' + Format(P.CdNB.ShowMandatory()) +
            ' VarTxt=' + Format(P.VarTxt.ShowMandatory()) + ' VarCd=' + Format(P.VarCd.ShowMandatory()));
    end;

    local procedure SeedMand()
    var
        Row: Record "LT AP Row";
    begin
        Row.DeleteAll();
        Row."Code" := 'V';
        Row.Txt := 'x';
        Row.Cd := 'X';
        Row.TxtNB := 'x';
        Row.CdNB := 'X';
        Row.Insert();
        Row.Init();
        Row."Code" := 'E';
        Row.Insert();
    end;

    [Test]
    procedure Ap07_ShowMandatory_OpenEdit()
    var
        P: TestPage "LT AP Card";
    begin
        Start();
        SeedMand();
        P.OpenEdit();
        P.GoToKey('V');
        Mand(P, 'value');
        P.GoToKey('E');
        Mand(P, 'blank');
        P.VarTxt.SetValue('x');
        P.VarCd.SetValue('X');
        Mand(P, 'vars-set');
        P.Close();
        Observer.Expect('value', 'Code=No Name=No Txt=No Cd=No TxtNB=No CdNB=No VarTxt=No VarCd=No');
        Observer.Expect('blank', 'Code=No Name=No Txt=No Cd=No TxtNB=No CdNB=No VarTxt=No VarCd=No');
        Observer.Expect('vars-set', 'Code=No Name=No Txt=No Cd=No TxtNB=No CdNB=No VarTxt=No VarCd=No');
        Observer.Verify();
    end;

    [Test]
    procedure Ap07_ShowMandatory_OpenView()
    var
        P: TestPage "LT AP Card";
    begin
        Start();
        SeedMand();
        P.OpenView();
        P.GoToKey('V');
        Mand(P, 'value');
        P.GoToKey('E');
        Mand(P, 'blank');
        P.Close();
        Observer.Expect('value', 'Code=No Name=No Txt=No Cd=No TxtNB=No CdNB=No VarTxt=No VarCd=No');
        Observer.Expect('blank', 'Code=No Name=No Txt=No Cd=No TxtNB=No CdNB=No VarTxt=No VarCd=No');
        Observer.Verify();
    end;

    [Test]
    procedure Ap07_ShowMandatory_OpenNew()
    var
        P: TestPage "LT AP Card";
    begin
        Start();
        SeedMand();
        P.OpenNew();
        Mand(P, 'new');
        P.Close();
        Observer.Expect('new', 'Code=No Name=No Txt=No Cd=No TxtNB=No CdNB=No VarTxt=No VarCd=No');
        Observer.Verify();
    end;

    // ---- item 8: SetValue on a page with ModifyAllowed = false ----

    [TryFunction]
    local procedure TrySetName(var P: TestPage "LT AP NoModify Card"; V: Text)
    begin
        P.Name.SetValue(V);
    end;

    [TryFunction]
    local procedure TrySetCode(var P: TestPage "LT AP NoModify Card"; V: Text)
    begin
        P."Code".SetValue(V);
    end;

    [TryFunction]
    local procedure TryClose(var P: TestPage "LT AP NoModify Card")
    begin
        P.Close();
    end;

    [Test]
    procedure Ap08_ModifyAllowedFalse_StoredRow()
    var
        Row: Record "LT AP Row";
        P: TestPage "LT AP NoModify Card";
    begin
        Start();
        Seed();
        P.OpenEdit();
        P.GoToKey('A');
        Observer.Observe('editable', Format(P.Name.Editable()));
        if TrySetName(P, 'changed') then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('value', P.Name.Value());
        if TryClose(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Row.Get('A');
        Observer.Observe('stored', Row.Name);
        Observer.Expect('editable', 'No');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'changed');
        Observer.Expect('close|text', 'Page cannot be saved.');
        Observer.Expect('close|code', 'TestWrapped');
        Observer.Expect('stored', 'Alpha');
        Observer.Verify();
    end;

    [Test]
    procedure Ap08_ModifyAllowedFalse_NewRow()
    var
        Row: Record "LT AP Row";
        P: TestPage "LT AP NoModify Card";
    begin
        Start();
        Seed();
        P.OpenNew();
        Observer.Observe('editable', Format(P.Name.Editable()));
        if TrySetCode(P, 'NM1') then
            Observer.Observe('set-code', 'ok')
        else
            Observer.ObserveError('set-code');
        if TrySetName(P, 'new') then
            Observer.Observe('set-name', 'ok')
        else
            Observer.ObserveError('set-name');
        Observer.Observe('value', P.Name.Value());
        if TryClose(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('stored', Format(Row.Get('NM1')) + '|' + Row.Name);
        Observer.Expect('editable', 'No');
        Observer.Expect('set-code', 'ok');
        Observer.Expect('set-name', 'ok');
        Observer.Expect('value', 'new');
        Observer.Expect('close|text', 'Page cannot be saved.');
        Observer.Expect('close|code', 'TestWrapped');
        Observer.Expect('stored', 'Yes|');
        Observer.Verify();
    end;

    // ---- item 9: Ratio control text ----

    local procedure RatioRow(NewCode: Code[20]; V: Decimal)
    var
        Row: Record "LT AP Row";
    begin
        Row.Init();
        Row."Code" := NewCode;
        Row.Rt := V;
        Row.Insert();
    end;

    // Linux suspect, not asserted: on the BC 29.0 Linux container every value (0.5, 1, 12.5, 0.25, -0.5, 0.333) reads '0%' from the Ratio
    // control while a plain control on the same field reads the value. Kept as a probe without [Test] until the Windows nightly confirms it.
    procedure Ap09_RatioValue()
    var
        Row: Record "LT AP Row";
        P: TestPage "LT AP Card";
    begin
        Start();
        Row.DeleteAll();
        RatioRow('R1', 0.5);
        RatioRow('R2', 1);
        RatioRow('R3', 12.5);
        RatioRow('R4', 0.25);
        RatioRow('R5', -0.5);
        RatioRow('R6', 0.333);
        P.OpenView();
        P.GoToKey('R1');
        Observer.Observe('0.5', P."Code".Value() + '|' + P.RtF.Value() + '|' + P.RtPlain.Value());
        P.GoToKey('R2');
        Observer.Observe('1', P."Code".Value() + '|' + P.RtF.Value() + '|' + P.RtPlain.Value());
        P.GoToKey('R3');
        Observer.Observe('12.5', P."Code".Value() + '|' + P.RtF.Value() + '|' + P.RtPlain.Value());
        P.GoToKey('R4');
        Observer.Observe('0.25', P."Code".Value() + '|' + P.RtF.Value() + '|' + P.RtPlain.Value());
        P.GoToKey('R5');
        Observer.Observe('-0.5', P."Code".Value() + '|' + P.RtF.Value() + '|' + P.RtPlain.Value());
        P.GoToKey('R6');
        Observer.Observe('0.333', P."Code".Value() + '|' + P.RtF.Value() + '|' + P.RtPlain.Value());
        P.Close();
        Observer.Finish();
    end;

    // ---- item 10: SetSelectionFilter on a list whose filter hides every row of a table that has rows ----

    [Test]
    procedure Ap10_SetSelectionFilter_FilterHidesAll_TestPageFilter()
    var
        Log: Codeunit "LT AP Log";
        P: TestPage "LT AP List";
    begin
        Start();
        Seed();
        P.OpenView();
        P.Filter.SetFilter("Code", 'ZZZ');
        Observer.Observe('first', Format(P.First()));
        Log.Take();
        P.SelFilter.Invoke();
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Expect('first', 'No');
        Observer.Expect('log', 'S n=0 f=[Code: ZZZ] cf=[ZZZ];');
        Observer.Verify();
    end;

    [Test]
    procedure Ap10_SetSelectionFilter_FilterHidesAll_RunWithFilter()
    var
        Row: Record "LT AP Row";
        Log: Codeunit "LT AP Log";
        P: TestPage "LT AP List";
    begin
        Start();
        Seed();
        Row.SetFilter(Grp, 'G9');
        P.Trap();
        Page.Run(Page::"LT AP List", Row);
        Log.Take();
        P.SelFilter.Invoke();
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Expect('log', 'S n=0 f=[Code: ''''] cf=[''''];W;C;W;C;');
        Observer.Verify();
    end;

    // ---- item 11: CurrPage.SaveRecord and CurrPage.Update in one action ----

    [Test]
    procedure Ap11_SaveRecordAndUpdate()
    var
        Row: Record "LT AP Row";
        Log: Codeunit "LT AP Log";
        P: TestPage "LT AP Card";
    begin
        Start();
        Seed();
        P.OpenEdit();
        P.GoToKey('A');
        P.Name.SetValue('edited');
        Observer.Observe('before', Log.Take());
        P.SaveUpd.Invoke();
        Observer.Observe('action', Log.Take());
        Row.Get('A');
        Observer.Observe('stored', Row.Name);
        P.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('before', 'O;RA;RA;');
        Observer.Expect('action', 'RA;saved;updated;RA;RA;');
        Observer.Expect('stored', 'edited');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure Ap11_SaveRecordAndUpdateFalse()
    var
        Row: Record "LT AP Row";
        Log: Codeunit "LT AP Log";
        P: TestPage "LT AP Card";
    begin
        Start();
        Seed();
        P.OpenEdit();
        P.GoToKey('A');
        P.Name.SetValue('edited');
        Observer.Observe('before', Log.Take());
        P.SaveUpdF.Invoke();
        Observer.Observe('action', Log.Take());
        Row.Get('A');
        Observer.Observe('stored', Row.Name);
        P.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('before', 'O;RA;RA;');
        Observer.Expect('action', 'RA;saved;updated;RA;RA;');
        Observer.Expect('stored', 'edited');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    // ---- items 5 and 12: a Page variable with SetRecord of a temporary record whose key is before, between or after the table's keys ----

    [ModalPageHandler]
    procedure CurrentRowHandler(var P: TestPage "LT AP List")
    var
        Log: Codeunit "LT AP Log";
    begin
        Observer.Observe('h-open', Log.Take());
        Observer.Observe('h-cur', P."Code".Value() + '|' + P.Name.Value());
        Observer.Observe('h-rows', Rows(P));
        P.OK().Invoke();
    end;

    local procedure SetRecordTemp(TempCode: Code[20])
    var
        Row: Record "LT AP Row";
        Temp: Record "LT AP Row" temporary;
        Pg: Page "LT AP List";
    begin
        Row.DeleteAll();
        AddRow('B', 'db-b', false, '');
        AddRow('D', 'db-d', false, '');
        AddRow('F', 'db-f', false, '');
        Temp."Code" := TempCode;
        Temp.Name := 'temp';
        Temp.Insert();
        Pg.SetRecord(Temp);
        Pg.RunModal();
    end;

    [Test]
    [HandlerFunctions('CurrentRowHandler')]
    procedure Ap12_PageVar_SetRecordTemp_KeyBetween()
    begin
        Start();
        SetRecordTemp('C');
        Observer.Expect('h-open', 'O;RD;RF;RD;RB;RD;RD;CD;');
        Observer.Expect('h-cur', 'D|db-d');
        Observer.Expect('h-rows', 'B,D,F,,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CurrentRowHandler')]
    procedure Ap12_PageVar_SetRecordTemp_KeyBefore()
    begin
        Start();
        SetRecordTemp('A');
        Observer.Expect('h-open', 'O;RB;RD;RF;RB;RB;CB;');
        Observer.Expect('h-cur', 'B|db-b');
        Observer.Expect('h-rows', 'B,D,F,,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CurrentRowHandler')]
    procedure Ap12_PageVar_SetRecordTemp_KeyAfter()
    begin
        Start();
        SetRecordTemp('G');
        Observer.Expect('h-open', 'O;RF;RD;RB;RF;RF;CF;');
        Observer.Expect('h-cur', 'F|db-f');
        Observer.Expect('h-rows', 'B,D,F,,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CurrentRowHandler')]
    procedure Ap12_PageVar_SetRecordTemp_KeyEqual()
    begin
        Start();
        SetRecordTemp('D');
        Observer.Expect('h-open', 'O;RD;RF;RD;RB;RD;RD;CD;');
        Observer.Expect('h-cur', 'D|db-d');
        Observer.Expect('h-rows', 'B,D,F,,');
        Observer.Verify();
    end;

    // ---- item 13: Cancel().Invoke() on a card and on a list that declare only OnAfterGetCurrRecord ----

    [ModalPageHandler]
    procedure CancelCardHandler(var P: TestPage "LT AP Cancel Card")
    var
        Log: Codeunit "LT AP Log";
    begin
        Observer.Observe('h-open', Log.Take());
        P.Cancel().Invoke();
        Observer.Observe('h-cancel', Log.Take());
    end;

    [ModalPageHandler]
    procedure CancelListHandler(var P: TestPage "LT AP Cancel List")
    var
        Log: Codeunit "LT AP Log";
    begin
        Observer.Observe('h-open', Log.Take());
        P.Cancel().Invoke();
        Observer.Observe('h-cancel', Log.Take());
    end;

    [Test]
    [HandlerFunctions('CancelCardHandler')]
    procedure Ap13_Cancel_Card_OnlyAfterGetCurrRecord()
    var
        Row: Record "LT AP Row";
        Log: Codeunit "LT AP Log";
    begin
        Start();
        Seed();
        Row.Get('B');
        Observer.Observe('result', Format(Page.RunModal(Page::"LT AP Cancel Card", Row)));
        Observer.Observe('after', Log.Take());
        Observer.Expect('h-open', 'CB;');
        Observer.Expect('h-cancel', 'CB;QLookupCancel;X;');
        Observer.Expect('result', 'LookupCancel');
        Observer.Expect('after', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CancelListHandler')]
    procedure Ap13_Cancel_List_OnlyAfterGetCurrRecord()
    var
        Row: Record "LT AP Row";
        Log: Codeunit "LT AP Log";
    begin
        Start();
        Seed();
        Row.Get('B');
        Observer.Observe('result', Format(Page.RunModal(Page::"LT AP Cancel List", Row)));
        Observer.Observe('after', Log.Take());
        Observer.Expect('h-open', 'CB;');
        Observer.Expect('h-cancel', 'CB;QLookupCancel;X;');
        Observer.Expect('result', 'LookupCancel');
        Observer.Expect('after', '');
        Observer.Verify();
    end;

    // ---- item 14: CaptionML in German only, English session (and a German one) ----

    [Test]
    procedure Ap14_CaptionML_GermanOnly()
    var
        P: TestPage "LT AP Caption DE";
        OldLanguage: Integer;
    begin
        Start();
        Seed();
        OldLanguage := GlobalLanguage();
        Observer.Observe('lang', Format(OldLanguage));
        P.OpenView();
        Observer.Observe('en-page', P.Caption());
        Observer.Observe('en-field', P.Name.Caption());
        P.Close();
        GlobalLanguage(1031);
        P.OpenView();
        Observer.Observe('de-page', P.Caption());
        Observer.Observe('de-field', P.Name.Caption());
        P.Close();
        GlobalLanguage(OldLanguage);
        Observer.Expect('lang', '1033');
        Observer.Expect('en-page', 'LT AP Caption DE - A');
        Observer.Expect('en-field', 'Name');
        Observer.Expect('de-page', 'Deutsche Seite - A');
        Observer.Expect('de-field', 'Deutscher Name');
        Observer.Verify();
    end;

    // ---- item 15: SetSelectionFilter into a record that already has marks ----

    [Test]
    procedure Ap15_SetSelectionFilter_IntoMarkedRecord()
    var
        Log: Codeunit "LT AP Log";
        P: TestPage "LT AP List";
    begin
        Start();
        Seed();
        P.OpenView();
        P.GoToKey('C');
        Log.Take();
        P.SelMarks.Invoke();
        Observer.Observe('marks', Log.Take());
        P.SelMarksOnly.Invoke();
        Observer.Observe('marked-only', Log.Take());
        P.Close();
        Observer.Expect('marks', 'RC;before=AB;n=1 f=[Code: C] mo=No;rows=C*;after=C;RC;RC;RD;RC;RB;RA;RC;RC;CC;');
        Observer.Expect('marked-only', 'RC;before=AB;n=1 f=[Marked: Yes, Code: C] mo=Yes;rows=C*;after=C;RC;RC;RD;RC;RB;RA;RC;RC;CC;');
        Observer.Verify();
    end;

    // ---- item 16: a field in a group with Enabled = false on a card page ----

    [TryFunction]
    local procedure TrySetQty(var P: TestPage "LT AP Card"; V: Decimal)
    begin
        P.Qty.SetValue(V);
    end;

    [Test]
    procedure Ap16_GroupEnabledFalse_Card()
    var
        Row: Record "LT AP Row";
        P: TestPage "LT AP Card";
    begin
        Start();
        Seed();
        P.OpenEdit();
        P.GoToKey('A');
        Observer.Observe('edit-enabled', Format(P.Qty.Enabled()));
        Observer.Observe('edit-editable', Format(P.Qty.Editable()));
        Observer.Observe('edit-visible', Format(P.Qty.Visible()));
        Observer.Observe('name-enabled', Format(P.Name.Enabled()));
        if TrySetQty(P, 5) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        P.Close();
        Row.Get('A');
        Observer.Observe('stored', Format(Row.Qty));
        P.OpenView();
        P.GoToKey('A');
        Observer.Observe('view-enabled', Format(P.Qty.Enabled()));
        Observer.Observe('view-editable', Format(P.Qty.Editable()));
        P.Close();
        Observer.Expect('edit-enabled', 'No');
        Observer.Expect('edit-editable', 'Yes');
        Observer.Expect('edit-visible', 'Yes');
        Observer.Expect('name-enabled', 'Yes');
        Observer.Expect('set', 'ok');
        Observer.Expect('stored', '5');
        Observer.Expect('view-enabled', 'No');
        Observer.Expect('view-editable', 'No');
        Observer.Verify();
    end;

    // ---- item 17: NotBlank on a list and on a page without a row; Masked under 11 characters; Numeric with other non-digits ----

    [Test]
    procedure Ap17_NotBlank_List()
    var
        P: TestPage "LT AP List";
    begin
        Start();
        Seed();
        P.OpenEdit();
        P.GoToKey('A');
        asserterror P.NameNB.SetValue('');
        Observer.ObserveError('list-blank');
        Observer.Expect('list-blank|text', 'Validation error for Field: NameNB,  Message = ''Txt must be filled in. Enter a value.''');
        Observer.Expect('list-blank|code', 'TestValidation');
        Observer.Verify();
    end;

    [Test]
    procedure Ap17_NotBlank_CardOnEmptyTable()
    var
        Row: Record "LT AP Row";
        P: TestPage "LT AP Card";
    begin
        Start();
        Row.DeleteAll();
        P.OpenEdit();
        Observer.Observe('code', P."Code".Value());
        asserterror P.NBF.SetValue('');
        Observer.ObserveError('empty-blank');
        Observer.Expect('code', '');
        Observer.Expect('empty-blank|text', 'The row does not exist on the TestPage.');
        Observer.Expect('empty-blank|code', 'TestRowNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Ap17_NotBlank_PageWithoutSourceTable()
    var
        P: TestPage "LT AP NoSource";
    begin
        Start();
        P.OpenEdit();
        P.VarNB.SetValue('x');
        asserterror P.VarNB.SetValue('');
        Observer.ObserveError('nosource-blank');
        Observer.Expect('nosource-blank|text', 'Validation error for Field: VarNB,  Message = '' must be filled in. Enter a value.''');
        Observer.Expect('nosource-blank|code', 'TestValidation');
        Observer.Verify();
    end;

    local procedure MaskRow(NewCode: Code[20]; V: Text[30])
    var
        Row: Record "LT AP Row";
    begin
        Row.Init();
        Row."Code" := NewCode;
        Row.Sec := V;
        Row.Insert();
    end;

    [Test]
    procedure Ap17_Masked_ShortTexts()
    var
        Row: Record "LT AP Row";
        P: TestPage "LT AP Card";
    begin
        Start();
        Row.DeleteAll();
        MaskRow('M0', '');
        MaskRow('M1', 'a');
        MaskRow('M5', 'abcde');
        MaskRow('M10', 'abcdefghij');
        MaskRow('M11', 'abcdefghijk');
        MaskRow('M20', 'abcdefghijklmnopqrst');
        P.OpenView();
        P.GoToKey('M0');
        Observer.Observe('0', P.SecF.Value());
        P.GoToKey('M1');
        Observer.Observe('1', P.SecF.Value());
        P.GoToKey('M5');
        Observer.Observe('5', P.SecF.Value());
        P.GoToKey('M10');
        Observer.Observe('10', P.SecF.Value());
        P.GoToKey('M11');
        Observer.Observe('11', P.SecF.Value());
        P.GoToKey('M20');
        Observer.Observe('20', P.SecF.Value());
        P.Close();
        Observer.Expect('0', '');
        Observer.Expect('1', '••••••••••');
        Observer.Expect('5', '••••••••••');
        Observer.Expect('10', '••••••••••');
        Observer.Expect('11', '••••••••••');
        Observer.Expect('20', '••••••••••');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySetNum(var P: TestPage "LT AP Card"; V: Text)
    begin
        P.NumF.SetValue(V);
    end;

    local procedure Num(var P: TestPage "LT AP Card"; V: Text)
    begin
        P.NumF.SetValue('0');
        if TrySetNum(P, V) then
            Observer.Observe('[' + V + ']', 'ok:' + P.NumF.Value())
        else
            Observer.Observe('[' + V + ']', 'error:' + GetLastErrorText());
        ClearLastError();
    end;

    [Test]
    procedure Ap17_Numeric_NonDigits()
    var
        P: TestPage "LT AP Card";
    begin
        Start();
        Seed();
        P.OpenEdit();
        P.GoToKey('A');
        Num(P, '12-3');
        Num(P, '-5');
        Num(P, '+5');
        Num(P, '1.5');
        Num(P, '1,5');
        Num(P, '1 2');
        Num(P, '#1');
        Num(P, '');
        P.Close();
        Observer.Expect('[12-3]', 'error:Validation error for Field: NumF,  Message = ''Your entry of ''12-3'' is not an acceptable value for ''Num''. Only numeric characters are allowed in field. (Select Refresh to discard errors)''');
        Observer.Expect('[-5]', 'error:Validation error for Field: NumF,  Message = ''Your entry of ''-5'' is not an acceptable value for ''Num''. Only numeric characters are allowed in field. (Select Refresh to discard errors)''');
        Observer.Expect('[+5]', 'error:Validation error for Field: NumF,  Message = ''Your entry of ''+5'' is not an acceptable value for ''Num''. Only numeric characters are allowed in field. (Select Refresh to discard errors)''');
        Observer.Expect('[1.5]', 'error:Validation error for Field: NumF,  Message = ''Your entry of ''1.5'' is not an acceptable value for ''Num''. Only numeric characters are allowed in field. (Select Refresh to discard errors)''');
        Observer.Expect('[1,5]', 'error:Validation error for Field: NumF,  Message = ''Your entry of ''1,5'' is not an acceptable value for ''Num''. Only numeric characters are allowed in field. (Select Refresh to discard errors)''');
        Observer.Expect('[1 2]', 'ok:1 2');
        Observer.Expect('[#1]', 'error:Validation error for Field: NumF,  Message = ''Your entry of ''#1'' is not an acceptable value for ''Num''. Only numeric characters are allowed in field. (Select Refresh to discard errors)''');
        Observer.Expect('[]', 'ok:');
        Observer.Verify();
    end;

    // ---- Writer SH, al-runner issue 5945: a field whose own Enabled (or Editable) is true inside a group whose Enabled (Editable) is false.

    local procedure ShObserveControl(var P: TestPage "LT SH Grp Enabled Card"; Name: Text; IsEnabled: Boolean; IsEditable: Boolean)
    begin
        Observer.Observe(Name, 'Enabled=' + Format(IsEnabled) + ' Editable=' + Format(IsEditable));
    end;

    [Test]
    procedure Ap16_GroupEnabledFalse_FieldEnabledTrue()
    var
        P: TestPage "LT SH Grp Enabled Card";
    begin
        Start();
        Seed();
        P.OpenEdit();
        P.GoToKey('A');
        ShObserveControl(P, 'NameOn (group off, field Enabled = true)', P.NameOn.Enabled(), P.NameOn.Editable());
        ShObserveControl(P, 'QtyPlain (group off, field plain)', P.QtyPlain.Enabled(), P.QtyPlain.Editable());
        ShObserveControl(P, 'TxtExprOn (group off, field Enabled = expression true)', P.TxtExprOn.Enabled(), P.TxtExprOn.Editable());
        ShObserveControl(P, 'CdInner (outer group off, inner group on)', P.CdInner.Enabled(), P.CdInner.Editable());
        ShObserveControl(P, 'GrpEditOn (group Editable = false, field Editable = true)', P.GrpEditOn.Enabled(), P.GrpEditOn.Editable());
        ShObserveControl(P, 'ValOff (group on, field Enabled = false)', P.ValOff.Enabled(), P.ValOff.Editable());
        P.Close();
        Observer.Finish();
    end;
}

page 89425 "LT SH Grp Enabled Card"
{
    PageType = Card;
    SourceTable = "LT AP Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(GrpOff)
            {
                Enabled = false;
                field(NameOn; Rec.Name) { ApplicationArea = All; Enabled = true; }
                field(QtyPlain; Rec.Qty) { ApplicationArea = All; }
            }
            group(GrpOffExpr)
            {
                Enabled = false;
                field(TxtExprOn; Rec.Txt) { ApplicationArea = All; Enabled = OnFlag; }
            }
            group(GrpOuterOff)
            {
                Enabled = false;
                group(GrpInnerOn)
                {
                    Enabled = true;
                    field(CdInner; Rec.Cd) { ApplicationArea = All; }
                }
            }
            group(GrpEditOff)
            {
                Editable = false;
                field(GrpEditOn; Rec.Grp) { ApplicationArea = All; Editable = true; }
            }
            group(GrpOn)
            {
                Enabled = true;
                field(ValOff; Rec.Val) { ApplicationArea = All; Enabled = false; }
            }
        }
    }

    var
        OnFlag: Boolean;

    trigger OnInit()
    begin
        OnFlag := true;
    end;
}
