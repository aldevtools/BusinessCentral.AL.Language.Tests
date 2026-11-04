// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 84100, log codeunit 84101, pages 84100-84103 (CaObjects.al)
// Probe: every literal asserted below is what BC 29.0 produced (local Linux container); BC 27 and 28 are checked by the CI legs.
// Settles corpus issue 667 (odd AL behavior leads, part B), items 1, 3, 6, 7, 9, 15 and 16.
// Facts: AsDecimal()/AsInteger() of a Decimal control that reads blank through BlankZero answer 0; AsDecimal() of a Text control that holds
// '', ' ' or a word raises "The input string '...' was not in a correct format." (AL:Format). A Role Center TestPage opens with OpenView,
// reads its Caption and invokes an action. Value and Format(control) assign to a Code variable (upper-cased; too long: StringLengthExceeded).
// Control.Caption without parentheses reads the caption. New() on a list with CardPageId does not open the trapped card (TestPageNotOpened).
// OK()/Cancel() held in a Variant: the Variant formats as 'TestAction', IsAction() is false, the page stays open; Cancel() on a page that
// has no Cancel raises TestActionNotFound already when it is read. A Dialog opened in a page action (local or global variable, closed or
// left open) runs without error under a TestPage, and GuiAllowed() is true there.
// Not asserted (Linux suspect, queued for Windows): Trap() then Page.Run of a Role Center page (CLR NullReferenceException).
// Item 1 for a part or page that shows NO row is pinned in testpart/BnrBlankPart.al.
// BC versions: 27, 28, 29
codeunit 84110 "LT CA TestPage Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(RowCode: Code[20]; RowName: Text[50]; RowAmt: Decimal; RowTxt: Text[30])
    var
        Row: Record "LT CA Row";
        Log: Codeunit "LT CA Log";
    begin
        Row.DeleteAll();
        Row."Code" := RowCode;
        Row.Name := RowName;
        Row.Amt := RowAmt;
        Row.Txt := RowTxt;
        Row.Insert();
        Log.Take();
    end;

    local procedure OpenCard(var P: TestPage "LT CA Card"; RowCode: Code[20])
    var
        Row: Record "LT CA Row";
    begin
        Row.Get(RowCode);
        P.OpenEdit();
        P.GoToRecord(Row);
    end;

    [TryFunction]
    local procedure TryAmtBlankDec(var P: TestPage "LT CA Card"; var D: Decimal)
    begin
        D := P.AmtBlankZero.AsDecimal();
    end;

    [TryFunction]
    local procedure TryAmtBlankInt(var P: TestPage "LT CA Card"; var I: Integer)
    begin
        I := P.AmtBlankZero.AsInteger();
    end;

    [TryFunction]
    local procedure TryTxtDec(var P: TestPage "LT CA Card"; var D: Decimal)
    begin
        D := P.TxtCtl.AsDecimal();
    end;

    // ---- item 1: AsDecimal() on a control of a row whose value reads empty ----

    [Test]
    procedure Ca01_AsDecimal_BlankZeroControlAndEmptyText()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT CA Card";
        D: Decimal;
        I: Integer;
    begin
        Seed('A', 'n', 0, '');
        OpenCard(P, 'A');
        Observer.Observe('blankzero-value', P.AmtBlankZero.Value());
        Observer.Observe('plain-value', P.AmtPlain.Value());
        if TryAmtBlankDec(P, D) then
            Observer.Observe('blankzero-asdecimal', Format(D))
        else
            Observer.ObserveError('blankzero-asdecimal');
        if TryAmtBlankInt(P, I) then
            Observer.Observe('blankzero-asinteger', Format(I))
        else
            Observer.ObserveError('blankzero-asinteger');
        Observer.Observe('text-value', P.TxtCtl.Value());
        if TryTxtDec(P, D) then
            Observer.Observe('emptytext-asdecimal', Format(D))
        else
            Observer.ObserveError('emptytext-asdecimal');
        P.Close();
        Observer.Expect('blankzero-value', '');
        Observer.Expect('plain-value', '0.00');
        Observer.Expect('blankzero-asdecimal', '0');
        Observer.Expect('blankzero-asinteger', '0');
        Observer.Expect('text-value', '');
        Observer.Expect('emptytext-asdecimal|text', 'The input string '''' was not in a correct format.');
        Observer.Expect('emptytext-asdecimal|code', 'AL:Format');
        Observer.Verify();
    end;

    [Test]
    procedure Ca01_AsDecimal_TextControlWithNumberAndNonNumber()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT CA Card";
        D: Decimal;
    begin
        Seed('A', 'n', 2.5, '12.5');
        OpenCard(P, 'A');
        Observer.Observe('blankzero-value', P.AmtBlankZero.Value());
        Observer.Observe('blankzero-asdecimal', Format(P.AmtBlankZero.AsDecimal()));
        if TryTxtDec(P, D) then
            Observer.Observe('number-text-asdecimal', Format(D))
        else
            Observer.ObserveError('number-text-asdecimal');
        P.TxtCtl.SetValue('abc');
        if TryTxtDec(P, D) then
            Observer.Observe('word-text-asdecimal', Format(D))
        else
            Observer.ObserveError('word-text-asdecimal');
        P.TxtCtl.SetValue(' ');
        Observer.Observe('space-text-value', '[' + P.TxtCtl.Value() + ']');
        if TryTxtDec(P, D) then
            Observer.Observe('space-text-asdecimal', Format(D))
        else
            Observer.ObserveError('space-text-asdecimal');
        P.Close();
        Observer.Expect('blankzero-value', '2.50');
        Observer.Expect('blankzero-asdecimal', '2.5');
        Observer.Expect('number-text-asdecimal', '12.5');
        Observer.Expect('word-text-asdecimal|text', 'The input string ''abc'' was not in a correct format.');
        Observer.Expect('word-text-asdecimal|code', 'AL:Format');
        Observer.Expect('space-text-value', '[ ]');
        Observer.Expect('space-text-asdecimal|text', 'The input string '' '' was not in a correct format.');
        Observer.Expect('space-text-asdecimal|code', 'AL:Format');
        Observer.Verify();
    end;

    // ---- item 3: a TestPage of a Role Center page ----

    [TryFunction]
    local procedure TryRunRoleCenter()
    begin
        Page.Run(Page::"LT CA Role Center");
    end;

    [TryFunction]
    local procedure TryOpenRoleCenter(var Rc: TestPage "LT CA Role Center")
    begin
        Rc.OpenView();
    end;

    [TryFunction]
    local procedure TryRcCaption(var Rc: TestPage "LT CA Role Center"; var C: Text)
    begin
        C := Rc.Caption();
    end;

    [TryFunction]
    local procedure TryInvokeRcAction(var Rc: TestPage "LT CA Role Center")
    var
        L: TestPage "LT CA List";
    begin
        L.Trap();
        Rc.RcAction.Invoke();
        L.Close();
    end;

    // NOT a test (Linux suspect, queued for the Windows check): on the Linux BC 29.0 container, Trap() then Page.Run of a Role Center page
    // fails with an uncatchable CLR NullReferenceException in TestPageClientSession.UISession_FormToShow. The probe is kept for that check.
    local procedure Ca03_RoleCenter_TrapThenPageRun()
    var
        Observer: Codeunit "Probe Observer";
        Rc: TestPage "LT CA Role Center";
        C: Text;
    begin
        Rc.Trap();
        if TryRunRoleCenter() then
            Observer.Observe('run', 'ok')
        else
            Observer.ObserveError('run');
        if TryRcCaption(Rc, C) then
            Observer.Observe('caption', C)
        else
            Observer.ObserveError('caption');
        if TryInvokeRcAction(Rc) then
            Observer.Observe('invoke', 'ok')
        else
            Observer.ObserveError('invoke');
        Observer.Finish();
    end;

    [Test]
    procedure Ca03_RoleCenter_OpenView()
    var
        Observer: Codeunit "Probe Observer";
        Rc: TestPage "LT CA Role Center";
        C: Text;
    begin
        if TryOpenRoleCenter(Rc) then
            Observer.Observe('openview', 'ok')
        else
            Observer.ObserveError('openview');
        if TryRcCaption(Rc, C) then
            Observer.Observe('caption', C)
        else
            Observer.ObserveError('caption');
        if TryInvokeRcAction(Rc) then
            Observer.Observe('invoke', 'ok')
        else
            Observer.ObserveError('invoke');
        Observer.Expect('openview', 'ok');
        Observer.Expect('caption', 'LT CA Role Center Caption');
        Observer.Expect('invoke', 'ok');
        Observer.Verify();
    end;

    // ---- item 6: a TestPage control's Value (and Format of the control) assigned to a Code variable ----

    [TryFunction]
    local procedure TryShortCode(var P: TestPage "LT CA Card"; var Short: Code[3])
    begin
        Short := P.NameCtl.Value;
    end;

    [Test]
    procedure Ca06_ValueAndFormatIntoCodeAndText()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT CA Card";
        C: Code[20];
        Short: Code[3];
        T: Text;
    begin
        Seed('ABC', 'mixed Case', 0, '');
        OpenCard(P, 'ABC');
        C := P.CodeCtl.Value;
        Observer.Observe('code-from-code-value', C);
        C := P.NameCtl.Value;
        Observer.Observe('code-from-text-value', C);
        C := Format(P.CodeCtl);
        Observer.Observe('code-from-format-control', C);
        T := Format(P.NameCtl);
        Observer.Observe('text-from-format-control', T);
        T := P.NameCtl.Value;
        Observer.Observe('text-from-value', T);
        if TryShortCode(P, Short) then
            Observer.Observe('code3-from-long-value', Short)
        else
            Observer.ObserveError('code3-from-long-value');
        P.Close();
        Observer.Expect('code-from-code-value', 'ABC');
        Observer.Expect('code-from-text-value', 'MIXED CASE');
        Observer.Expect('code-from-format-control', 'ABC');
        Observer.Expect('text-from-format-control', 'mixed Case');
        Observer.Expect('text-from-value', 'mixed Case');
        Observer.Expect('code3-from-long-value|text', 'The length of the string is 10, but it must be less than or equal to 3 characters. Value: mixed Case');
        Observer.Expect('code3-from-long-value|code', 'StringLengthExceeded');
        Observer.Verify();
    end;

    // ---- item 7: Caption of a TestPage control read without parentheses ----

    [Test]
    procedure Ca07_CaptionWithoutParentheses()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT CA Card";
        T: Text;
    begin
        Seed('A', 'n', 0, '');
        OpenCard(P, 'A');
        T := P.NameCtl.Caption;
        Observer.Observe('name-caption-property', T);
        Observer.Observe('name-caption-method', P.NameCtl.Caption());
        T := P.CodeCtl.Caption;
        Observer.Observe('code-caption-property', T);
        P.Close();
        Observer.Expect('name-caption-property', 'LT CA Name Caption');
        Observer.Expect('name-caption-method', 'LT CA Name Caption');
        Observer.Expect('code-caption-property', 'Code');
        Observer.Verify();
    end;

    // ---- item 9: New() on a list page whose CardPageId names a card, with the card trapped ----

    [TryFunction]
    local procedure TrySetCardCode(var Card: TestPage "LT CA Card"; V: Text)
    begin
        Card.CodeCtl.SetValue(V);
    end;

    [TryFunction]
    local procedure TryListNew(var L: TestPage "LT CA List")
    begin
        L.New();
    end;

    [TryFunction]
    local procedure TryEditableListNew(var L: TestPage "LT CA Editable List")
    begin
        L.New();
    end;

    [TryFunction]
    local procedure TryReadListCode(var L: TestPage "LT CA Editable List"; var V: Text)
    begin
        V := L.CodeCtl.Value();
    end;

    [Test]
    procedure Ca09_NotEditableList_New_TrappedCard()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CA Row";
        L: TestPage "LT CA List";
        Card: TestPage "LT CA Card";
    begin
        Seed('A', 'n', 0, '');
        L.OpenView();
        Card.Trap();
        if TryListNew(L) then
            Observer.Observe('new', 'ok')
        else
            Observer.ObserveError('new');
        if TrySetCardCode(Card, 'NEWROW') then
            Observer.Observe('card-setvalue', 'ok')
        else
            Observer.ObserveError('card-setvalue');
        Observer.Observe('rows', Format(Row.Count()));
        Observer.Expect('new', 'ok');
        Observer.Expect('card-setvalue|text', 'The TestPage is not open.');
        Observer.Expect('card-setvalue|code', 'TestPageNotOpened');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Ca09_EditableList_New_TrappedCard()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CA Row";
        L: TestPage "LT CA Editable List";
        Card: TestPage "LT CA Card";
        V: Text;
    begin
        Seed('A', 'n', 0, '');
        L.OpenEdit();
        Card.Trap();
        if TryEditableListNew(L) then
            Observer.Observe('new', 'ok')
        else
            Observer.ObserveError('new');
        if TrySetCardCode(Card, 'NEWROW') then
            Observer.Observe('card-setvalue', 'ok')
        else
            Observer.ObserveError('card-setvalue');
        if TryReadListCode(L, V) then
            Observer.Observe('list-code-after-new', '[' + V + ']')
        else
            Observer.ObserveError('list-code-after-new');
        Observer.Observe('rows', Format(Row.Count()));
        Observer.Expect('new', 'ok');
        Observer.Expect('card-setvalue|text', 'The TestPage is not open.');
        Observer.Expect('card-setvalue|code', 'TestPageNotOpened');
        Observer.Expect('list-code-after-new', '[]');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    // ---- item 15: OK() and Cancel() return a TestAction that can be held in a Variant ----

    [TryFunction]
    local procedure TryReadCardCode(var P: TestPage "LT CA Card"; var V: Text)
    begin
        V := P.CodeCtl.Value();
    end;

    [TryFunction]
    local procedure TryCancelIntoVariant(var P: TestPage "LT CA Card"; var V: Variant)
    begin
        V := P.Cancel();
    end;

    [TryFunction]
    local procedure TryListOkIntoVariant(var L: TestPage "LT CA Editable List"; var V: Variant)
    begin
        V := L.OK();
    end;

    [TryFunction]
    local procedure TryListCancelIntoVariant(var L: TestPage "LT CA Editable List"; var V: Variant)
    begin
        V := L.Cancel();
    end;

    [Test]
    procedure Ca15_OkIntoVariant_DoesNotClose()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT CA Card";
        V: Variant;
        T: Text;
    begin
        Seed('A', 'n', 0, '');
        OpenCard(P, 'A');
        V := P.OK();
        Observer.Observe('variant-isaction', Format(V.IsAction()));
        Observer.Observe('variant-format', Format(V));
        if TryReadCardCode(P, T) then
            Observer.Observe('read-after-ok-into-variant', T)
        else
            Observer.ObserveError('read-after-ok-into-variant');
        if TryCancelIntoVariant(P, V) then
            Observer.Observe('cancel-into-variant', 'ok')
        else
            Observer.ObserveError('cancel-into-variant');
        if TryReadCardCode(P, T) then
            Observer.Observe('read-after-cancel-into-variant', T)
        else
            Observer.ObserveError('read-after-cancel-into-variant');
        P.OK().Invoke();
        if TryReadCardCode(P, T) then
            Observer.Observe('read-after-ok-invoke', T)
        else
            Observer.ObserveError('read-after-ok-invoke');
        Observer.Expect('variant-isaction', 'No');
        Observer.Expect('variant-format', 'TestAction');
        Observer.Expect('read-after-ok-into-variant', 'A');
        Observer.Expect('cancel-into-variant|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('cancel-into-variant|code', 'TestActionNotFound');
        Observer.Expect('read-after-cancel-into-variant', 'A');
        Observer.Expect('read-after-ok-invoke|text', 'The TestPage is not open.');
        Observer.Expect('read-after-ok-invoke|code', 'TestPageNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure Ca15_ListOkCancelIntoVariant()
    var
        Observer: Codeunit "Probe Observer";
        L: TestPage "LT CA Editable List";
        V: Variant;
        T: Text;
    begin
        Seed('A', 'n', 0, '');
        L.OpenView();
        if TryListOkIntoVariant(L, V) then
            Observer.Observe('ok-into-variant', 'ok')
        else
            Observer.ObserveError('ok-into-variant');
        if TryListCancelIntoVariant(L, V) then
            Observer.Observe('cancel-into-variant', 'ok')
        else
            Observer.ObserveError('cancel-into-variant');
        if TryReadListCode(L, T) then
            Observer.Observe('read-after', T)
        else
            Observer.ObserveError('read-after');
        Observer.Observe('variant-isaction', Format(V.IsAction()));
        Observer.Expect('ok-into-variant', 'ok');
        Observer.Expect('cancel-into-variant|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('cancel-into-variant|code', 'TestActionNotFound');
        Observer.Expect('read-after', 'A');
        Observer.Expect('variant-isaction', 'No');
        Observer.Verify();
    end;

    // ---- item 16: a Dialog local to a page action, and one global to the page ----

    [TryFunction]
    local procedure TryInvoke(var P: TestPage "LT CA Card"; Which: Integer)
    begin
        case Which of
            1:
                P.DialogLocal.Invoke();
            2:
                P.DialogGlobal.Invoke();
            3:
                P.DialogGlobalLeftOpen.Invoke();
        end;
    end;

    [Test]
    procedure Ca16_DialogLocalAndGlobalInPageAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT CA Log";
        P: TestPage "LT CA Card";
        Which: Integer;
    begin
        Seed('A', 'n', 0, '');
        OpenCard(P, 'A');
        for Which := 1 to 3 do begin
            if TryInvoke(P, Which) then
                Observer.Observe('invoke' + Format(Which), 'ok')
            else
                Observer.ObserveError('invoke' + Format(Which));
            Observer.Observe('log' + Format(Which), Log.Take());
        end;
        if TryInvoke(P, 3) then
            Observer.Observe('invoke3-again', 'ok')
        else
            Observer.ObserveError('invoke3-again');
        Observer.Observe('log3-again', Log.Take());
        P.Close();
        Observer.Expect('invoke1', 'ok');
        Observer.Expect('log1', 'local:gui=Yes;local:done;');
        Observer.Expect('invoke2', 'ok');
        Observer.Expect('log2', 'global:gui=Yes;global:done;');
        Observer.Expect('invoke3', 'ok');
        Observer.Expect('log3', 'open-left:done;');
        Observer.Expect('invoke3-again', 'ok');
        Observer.Expect('log3-again', 'open-left:done;');
        Observer.Verify();
    end;
}
