// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope (Cloud-compatible) -- every member is driven from a [Test] with no client
// Fixtures used: ALT Page Update Gone Row (67300), ALT Page Update Gone Card (67300),
//   ALT Page Update Gone List (67301), ALT Page Update Gone Find List (67302),
//   ALT Page Update Gone Trace (67301); shared Assert (60021)
// BC versions: 27.0+
//
/// <summary>
/// CLAIM: what a page does when its current row is not in the table after an action, and what
/// the refresh CurrPage.Update(false) asks for raises on an unsaved DelayedInsert row.
///
///   1. A Card whose current row was deleted -- by its own action, or by the test underneath it
///      -- is closed once an action on it returns: OnClosePage runs, no OnAfterGetCurrRecord
///      does, and the TestPage is no longer open afterwards, Close() included. CurrPage.Update(false) is not what closes it; an action that only
///      deletes does the same. A new row the table does not hold yet is not "deleted": an action
///      on the untouched row OpenNew starts leaves the Card open, and so does an action on a Card
///      opened with OpenEdit that never showed a stored row (an empty table, or a filter that
///      matches nothing).
///   2. A List in the same shape moves to the neighbouring row instead: the next row, the
///      previous one when the deleted row was the last, and no stored row when it was the only
///      one -- with or without CurrPage.Update(false) in the action. A List that declares
///      OnFindRecord: the re-read goes through that trigger, three times, with Which '=', then
///      '=>', then '=' again, and the page shows the row the trigger answers. A pass-through
///      OnFindRecord (exit(Rec.Find(Which))) answers false on the deleted key, and BC still asks
///      '=>' and then '=' for the row it lands on: the next row, else the previous one; with no
///      row left it asks '=>' and '=><' only, no '=', and shows no stored row.
///   3. A new row on a DelayedInsert page whose field OnValidate calls CurrPage.Update(false):
///      the call does not save, and the refresh raises neither OnAfterGetRecord nor
///      OnAfterGetCurrRecord for the unsaved row. Once with the key set, once without.
///   4. Controls: the same two CurrPage.Update(false) routes on a stored row refresh it.
/// </summary>
codeunit 67300 "ALT Page Update Gone Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Trace: Codeunit "ALT Page Update Gone Trace";

    local procedure Seed(WithNeighbour: Boolean)
    var
        Row: Record "ALT Page Update Gone Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Code := 'A';
        Row.Name := 'Alpha';
        Row.Insert();
        if WithNeighbour then begin
            Row.Init();
            Row.Code := 'B';
            Row.Name := 'Beta';
            Row.Insert();
        end;
    end;

    // What BC raises once an action returns and the Card's row is gone, measured on every cloud
    // leg: 'AGR:A;ActionBegin;ActionEnd;AGR:B;ClosePage;' with a neighbour B, and
    // 'AGR:A;ActionBegin;ActionEnd;ClosePage;' without one. The OnAfterGetRecord calls are the
    // client re-reading rows; the claim is that OnClosePage ends the trace, and that neither the
    // deleted row's OnAfterGetRecord nor any OnAfterGetCurrRecord runs after the action.
    local procedure AssertClosedAfterAction(Recorded: Text)
    var
        After: Text;
        Position: Integer;
    begin
        Position := StrPos(Recorded, 'ActionEnd;');
        Assert.AreNotEqual(0, Position, 'the action ran; trace ' + Recorded);
        After := CopyStr(Recorded, Position + StrLen('ActionEnd;'));
        Assert.IsTrue(After.EndsWith('ClosePage;'),
            'OnClosePage ends the trace; trace ' + Recorded);
        Assert.AreEqual(0, StrPos(After, 'AGR:A;'), 'no OnAfterGetRecord for the deleted row; trace ' + Recorded);
        Assert.AreEqual(0, StrPos(After, 'AGCR'), 'no OnAfterGetCurrRecord after the action; trace ' + Recorded);
    end;

    [Test]
    procedure Card_DeletedByAction_WithNeighbour_UpdateClosesThePage()
    var
        Card: TestPage "ALT Page Update Gone Card";
        Recorded: Text;
        Probe: Text;
    begin
        Seed(true);
        Card.OpenEdit();
        Card.GoToKey('A');
        Trace.Reset();

        Card.DeleteAndUpdate.Invoke();
        Recorded := Trace.Get();

        asserterror Probe := Card.CodeField.Value();
        Assert.ExpectedError('The TestPage is not open.');
        AssertClosedAfterAction(Recorded);
    end;

    [Test]
    procedure Card_DeletedByAction_LastRow_UpdateClosesThePage()
    var
        Card: TestPage "ALT Page Update Gone Card";
        Recorded: Text;
        Probe: Text;
    begin
        Seed(false);
        Card.OpenEdit();
        Card.GoToKey('A');
        Trace.Reset();

        Card.DeleteAndUpdate.Invoke();
        Recorded := Trace.Get();

        asserterror Probe := Card.CodeField.Value();
        Assert.ExpectedError('The TestPage is not open.');
        AssertClosedAfterAction(Recorded);
    end;

    [Test]
    procedure Card_DeletedUnderneath_UpdateActionClosesThePage()
    var
        Row: Record "ALT Page Update Gone Row";
        Card: TestPage "ALT Page Update Gone Card";
        Recorded: Text;
        Probe: Text;
    begin
        Seed(true);
        Card.OpenEdit();
        Card.GoToKey('A');
        Row.Get('A');
        Row.Delete();
        Trace.Reset();

        Card.UpdateOnly.Invoke();
        Recorded := Trace.Get();

        asserterror Probe := Card.CodeField.Value();
        Assert.ExpectedError('The TestPage is not open.');
        AssertClosedAfterAction(Recorded);
    end;

    [Test]
    procedure Card_DeletedByAction_NoUpdate_ClosesThePage()
    var
        Card: TestPage "ALT Page Update Gone Card";
        Recorded: Text;
        Probe: Text;
    begin
        Seed(true);
        Card.OpenEdit();
        Card.GoToKey('A');
        Trace.Reset();

        Card.DeleteOnly.Invoke();
        Recorded := Trace.Get();

        asserterror Probe := Card.CodeField.Value();
        Assert.ExpectedError('The TestPage is not open.');
        AssertClosedAfterAction(Recorded);
    end;

    [Test]
    procedure Card_DeletedByAction_CloseAfterwards_IsNotOpen()
    var
        Card: TestPage "ALT Page Update Gone Card";
    begin
        Seed(true);
        Card.OpenEdit();
        Card.GoToKey('A');

        Card.DeleteOnly.Invoke();

        asserterror Card.Close();
        Assert.ExpectedError('The TestPage is not open.');
    end;

    [Test]
    procedure Card_OpenNew_UntouchedRow_UpdateAction_StaysOpen()
    var
        Row: Record "ALT Page Update Gone Row";
        Card: TestPage "ALT Page Update Gone Card";
        Recorded: Text;
        Shown: Text;
    begin
        Row.DeleteAll();
        Card.OpenNew();
        Trace.Reset();

        Card.UpdateOnly.Invoke();
        Recorded := Trace.Get();
        Shown := Card.CodeField.Value();

        Assert.AreEqual('ActionBegin;ActionEnd;', Recorded, 'an action on the untouched new row; shows ' + Shown);
        Assert.AreEqual('', Shown, 'the untouched new row is still shown; trace ' + Recorded);
        Assert.IsTrue(Row.IsEmpty(), 'the action did not insert the untouched new row');
        Card.Close();
    end;

    local procedure FindCalls(Recorded: Text) Calls: Text
    var
        Entry: Text;
    begin
        foreach Entry in Recorded.Split(';') do
            if Entry.StartsWith('Find:') then
                Calls += Entry + ';';
    end;

    [TryFunction]
    local procedure TryReadCode(var Card: TestPage "ALT Page Update Gone Card"; var Shown: Text)
    begin
        Shown := Card.CodeField.Value();
    end;

    [Test]
    procedure Card_OpenEdit_EmptyTable_NoOpAction_StaysOpen()
    var
        Row: Record "ALT Page Update Gone Row";
        Card: TestPage "ALT Page Update Gone Card";
        Recorded: Text;
        Shown: Text;
        Readable: Boolean;
    begin
        Row.DeleteAll();
        Card.OpenEdit();
        Trace.Reset();

        Card.NoOp.Invoke();
        Recorded := Trace.Get();
        Readable := TryReadCode(Card, Shown);

        Assert.IsTrue(Readable, 'empty table: the Card is still open after the action; error ' + GetLastErrorText() + '; trace ' + Recorded);
        Assert.AreEqual('', Shown, 'empty table: the Card still shows a blank row; trace ' + Recorded);
        Assert.AreEqual(0, StrPos(Recorded, 'ClosePage'), 'empty table: no OnClosePage; trace ' + Recorded);
        Card.Close();
    end;

    [Test]
    procedure Card_OpenEdit_FilterMatchesNothing_NoOpAction_StaysOpen()
    var
        Card: TestPage "ALT Page Update Gone Card";
        Recorded: Text;
        Shown: Text;
        Readable: Boolean;
    begin
        Seed(false);
        Card.OpenEdit();
        Card.Filter.SetFilter(Code, 'Q');
        Trace.Reset();

        Card.NoOp.Invoke();
        Recorded := Trace.Get();
        Readable := TryReadCode(Card, Shown);

        Assert.IsTrue(Readable, 'no-match filter: the Card is still open after the action; error ' + GetLastErrorText() + '; trace ' + Recorded);
        // What the new row shows is not the claim (a single-value filter may pre-fill its key);
        // that the Card is still open and not on the filtered-out stored row is.
        Assert.AreNotEqual('A', Shown, 'no-match filter: the Card does not show the filtered-out row A; trace ' + Recorded);
        Assert.AreEqual(0, StrPos(Recorded, 'ClosePage'), 'no-match filter: no OnClosePage; trace ' + Recorded);
        Card.Close();
    end;

    [Test]
    procedure List_DeletedByAction_WithNeighbour_MovesToTheNeighbour()
    var
        List: TestPage "ALT Page Update Gone List";
        After: Text;
        Shown: Text;
    begin
        Seed(true);
        List.OpenEdit();
        List.GoToKey('A');
        Trace.Reset();

        List.DeleteAndUpdate.Invoke();
        After := Trace.AfterActionEnd();
        Shown := List.CodeField.Value();

        // BC raises OnAfterGetRecord and OnAfterGetCurrRecord for the neighbour more than once
        // (AGR:B;AGR:B;AGCR:B;AGR:B;AGR:B;AGCR:B on the first run); the row is the claim.
        Assert.AreEqual('B', Shown, 'list: the row shown after deleting the current one; trace ' + Trace.Get());
        Assert.AreEqual(0, StrPos(After, 'AGR:A;'), 'list: no OnAfterGetRecord for the deleted row; trace ' + Trace.Get());
        Assert.IsTrue(After.EndsWith('AGCR:B;'),
            'list: OnAfterGetCurrRecord runs for the neighbour; trace ' + Trace.Get());
        List.Close();
    end;

    [Test]
    procedure List_DeletedByAction_LastRow_MovesToThePreviousRow()
    var
        List: TestPage "ALT Page Update Gone List";
        After: Text;
        Shown: Text;
    begin
        Seed(true);
        List.OpenEdit();
        List.GoToKey('B');
        Trace.Reset();

        List.DeleteAndUpdate.Invoke();
        After := Trace.AfterActionEnd();
        Shown := List.CodeField.Value();

        // B was the last row: with no row after it, the page is expected on A, the row before it.
        Assert.AreEqual('A', Shown, 'list, last row: the row shown after deleting the current one; trace ' + Trace.Get());
        Assert.AreEqual(0, StrPos(After, 'AGR:B;'), 'list, last row: no OnAfterGetRecord for the deleted row; trace ' + Trace.Get());
        Assert.IsTrue(After.EndsWith('AGCR:A;'),
            'list, last row: OnAfterGetCurrRecord runs for the previous row; trace ' + Trace.Get());
        List.Close();
    end;

    [Test]
    procedure List_DeletedByAction_MiddleRow_MovesToTheNextRow()
    var
        Row: Record "ALT Page Update Gone Row";
        List: TestPage "ALT Page Update Gone List";
        After: Text;
        Shown: Text;
    begin
        Seed(true);
        Row.Init();
        Row.Code := 'C';
        Row.Name := 'Gamma';
        Row.Insert();
        List.OpenEdit();
        List.GoToKey('B');
        Trace.Reset();

        List.DeleteAndUpdate.Invoke();
        After := Trace.AfterActionEnd();
        Shown := List.CodeField.Value();

        // Rows on both sides of B: the page is expected on C, the row after it, not on the first row.
        Assert.AreEqual('C', Shown, 'list, middle row: the row shown after deleting the current one; trace ' + Trace.Get());
        Assert.AreEqual(0, StrPos(After, 'AGR:B;'), 'list, middle row: no OnAfterGetRecord for the deleted row; trace ' + Trace.Get());
        Assert.IsTrue(After.EndsWith('AGCR:C;'),
            'list, middle row: OnAfterGetCurrRecord runs for the next row; trace ' + Trace.Get());
        List.Close();
    end;

    [Test]
    procedure List_DeletedByAction_OnlyRow_ShowsNoStoredRow()
    var
        Row: Record "ALT Page Update Gone Row";
        List: TestPage "ALT Page Update Gone List";
        After: Text;
        Shown: Text;
    begin
        Seed(false);
        List.OpenEdit();
        List.GoToKey('A');
        Trace.Reset();

        List.DeleteAndUpdate.Invoke();
        After := Trace.AfterActionEnd();
        Shown := List.CodeField.Value();

        // No neighbour either side: the List stays open and shows no stored row.
        Assert.AreEqual('', Shown, 'list, only row: the row shown after deleting the only one; trace ' + Trace.Get());
        Assert.AreEqual(0, StrPos(After, 'AGR:A;'), 'list, only row: no OnAfterGetRecord for the deleted row; trace ' + Trace.Get());
        Assert.AreEqual(0, StrPos(After, 'AGCR:A;'), 'list, only row: no OnAfterGetCurrRecord for the deleted row; trace ' + Trace.Get());
        // The blank line raises OnAfterGetCurrRecord; the whole trace after the action is pinned.
        Assert.AreEqual('AGCR:;AGCR:;AGCR:;', After, 'list only row: trace');
        Assert.IsTrue(Row.IsEmpty(), 'list, only row: nothing re-inserted the deleted row');
        List.Close();
    end;

    [Test]
    procedure List_DeletedByAction_NoUpdate_MovesToTheNeighbour()
    var
        List: TestPage "ALT Page Update Gone List";
        After: Text;
        Shown: Text;
    begin
        Seed(true);
        List.OpenEdit();
        List.GoToKey('A');
        Trace.Reset();

        List.DeleteOnly.Invoke();
        After := Trace.AfterActionEnd();
        Shown := List.CodeField.Value();

        // The same move without CurrPage.Update: the re-read after the action is what moves the page.
        Assert.AreEqual('B', Shown, 'list, no update: the row shown after deleting the current one; trace ' + Trace.Get());
        Assert.AreEqual(0, StrPos(After, 'AGR:A;'), 'list, no update: no OnAfterGetRecord for the deleted row; trace ' + Trace.Get());
        Assert.IsTrue(After.EndsWith('AGCR:B;'),
            'list, no update: OnAfterGetCurrRecord runs for the neighbour; trace ' + Trace.Get());
        List.Close();
    end;

    [Test]
    procedure List_DeletedByAction_OnFindRecord_PicksTheRow()
    var
        Row: Record "ALT Page Update Gone Row";
        List: TestPage "ALT Page Update Gone Find List";
        After: Text;
        Shown: Text;
    begin
        Seed(true);
        Row.Init();
        Row.Code := 'C';
        Row.Name := 'Gamma';
        Row.Insert();
        List.OpenEdit();
        List.GoToKey('B');
        Trace.Reset();

        List.DeleteAndPickFirst.Invoke();
        After := Trace.AfterActionEnd();
        Shown := List.CodeField.Value();

        // The page's OnFindRecord answers the first row once the action ran; the default re-read
        // of a deleted middle row lands on C. So A means the re-read went through the trigger.
        // BC calls it three times after the action: '=' for the gone row, '=>' to read the rows
        // from there on, and '=' again for the row it settled on.
        Assert.AreEqual('A', Shown, 'list with OnFindRecord: the row shown after deleting B; after ' + After);
        Assert.AreEqual('Find:=;Find:=>;Find:=;', FindCalls(After), 'list with OnFindRecord: the Which strings, in order; after ' + After);
        Assert.AreEqual(0, StrPos(After, 'AGR:B;'), 'list with OnFindRecord: no OnAfterGetRecord for the deleted row; after ' + After);
        Assert.IsTrue(After.EndsWith('AGCR:A;'),
            'list with OnFindRecord: OnAfterGetCurrRecord runs for the row the trigger answered; after ' + After);
        List.Close();
    end;

    [Test]
    procedure List_DeletedByAction_PassThroughFind_MiddleRow()
    var
        Row: Record "ALT Page Update Gone Row";
        List: TestPage "ALT Page Update Gone Find List";
        After: Text;
        Shown: Text;
    begin
        Seed(true);
        Row.Init();
        Row.Code := 'C';
        Row.Name := 'Gamma';
        Row.Insert();
        List.OpenEdit();
        List.GoToKey('B');
        Trace.Reset();

        List.DeletePassThrough.Invoke();
        After := Trace.AfterActionEnd();
        Shown := List.CodeField.Value();

        // The trigger is exit(Rec.Find(Which)), so it answers false to '=' on the deleted key B.
        // BC asks the same three Which strings as for a trigger that answers true: '=', then '=>',
        // which reaches C, then '=' for C.
        Assert.AreEqual('C', Shown, 'pass-through OnFindRecord, middle row: the row shown after deleting B; after ' + After);
        Assert.AreEqual('Find:=;Find:=>;Find:=;', FindCalls(After),
            'pass-through OnFindRecord, middle row: the Which strings, in order; after ' + After);
        Assert.AreEqual(0, StrPos(After, 'AGR:B;'), 'pass-through OnFindRecord, middle row: no OnAfterGetRecord for the deleted row; after ' + After);
        Assert.IsTrue(After.EndsWith('AGCR:C;'),
            'pass-through OnFindRecord, middle row: OnAfterGetCurrRecord runs for the row shown; after ' + After);
        List.Close();
    end;

    [Test]
    procedure List_DeletedByAction_PassThroughFind_LastRow()
    var
        List: TestPage "ALT Page Update Gone Find List";
        After: Text;
        Shown: Text;
    begin
        Seed(true);
        List.OpenEdit();
        List.GoToKey('B');
        Trace.Reset();

        List.DeletePassThrough.Invoke();
        After := Trace.AfterActionEnd();
        Shown := List.CodeField.Value();

        // Nothing after B, so '=>' answers false too; the page still lands on the previous row A,
        // and the third '=' is asked for A.
        Assert.AreEqual('A', Shown, 'pass-through OnFindRecord, last row: the row shown after deleting B; after ' + After);
        Assert.AreEqual('Find:=;Find:=>;Find:=;', FindCalls(After),
            'pass-through OnFindRecord, last row: the Which strings, in order; after ' + After);
        Assert.AreEqual(0, StrPos(After, 'AGR:B;'), 'pass-through OnFindRecord, last row: no OnAfterGetRecord for the deleted row; after ' + After);
        Assert.IsTrue(After.EndsWith('AGCR:A;'),
            'pass-through OnFindRecord, last row: OnAfterGetCurrRecord runs for the row shown; after ' + After);
        List.Close();
    end;

    [Test]
    procedure List_DeletedByAction_PassThroughFind_OnlyRow()
    var
        Row: Record "ALT Page Update Gone Row";
        List: TestPage "ALT Page Update Gone Find List";
        After: Text;
        Shown: Text;
    begin
        Seed(false);
        List.OpenEdit();
        List.GoToKey('A');
        Trace.Reset();

        List.DeletePassThrough.Invoke();
        After := Trace.AfterActionEnd();
        Shown := List.CodeField.Value();

        // No row either side: BC does not ask '=' at all here; it asks '=>' and then '=><', both
        // answer false, and there is no row to settle on.
        Assert.AreEqual('Find:=>;Find:=><;', FindCalls(After),
            'pass-through OnFindRecord, only row: the Which strings, in order; after ' + After);
        Assert.AreEqual('', Shown, 'pass-through OnFindRecord, only row: the row shown after deleting A; after ' + After);
        Assert.AreEqual(0, StrPos(After, 'AGR:A;'), 'pass-through OnFindRecord, only row: no OnAfterGetRecord for the deleted row; after ' + After);
        Assert.AreEqual(0, StrPos(After, 'AGCR:A;'), 'pass-through OnFindRecord, only row: no OnAfterGetCurrRecord for the deleted row; after ' + After);
        // The blank line raises OnAfterGetCurrRecord. The whole trace after the action is pinned,
        // with a short message: a failure message is cut at 200 characters, which is how the first
        // read of this trace lost its end.
        Assert.AreEqual('AGCR:;Find:=>;Find:=><;AGCR:;AGCR:;', After, 'pass-through only row: trace');
        Assert.IsTrue(Row.IsEmpty(), 'pass-through OnFindRecord, only row: nothing re-inserted the deleted row');
        List.Close();
    end;

    [Test]
    procedure Card_StoredRow_UpdateAction_RefreshesTheRow()
    var
        Card: TestPage "ALT Page Update Gone Card";
        After: Text;
    begin
        Seed(true);
        Card.OpenEdit();
        Card.GoToKey('A');
        Trace.Reset();

        Card.UpdateOnly.Invoke();
        After := Trace.AfterActionEnd();

        // BC raises OnAfterGetRecord more than once around an action (AGR:A;AGR:A;AGCR:A on the
        // first run of this suite); the count of OnAfterGetCurrRecord and the row are the claim.
        Assert.IsTrue(After.EndsWith('AGCR:A;'),
            'control: the refresh of a stored row ends with its OnAfterGetCurrRecord; trace ' + Trace.Get());
        Assert.AreNotEqual(0, StrPos(After, 'AGR:A;'), 'control: OnAfterGetRecord runs for the stored row; trace ' + Trace.Get());
        Assert.AreEqual('A', Card.CodeField.Value(), 'control: the page stays on the stored row');
        Card.Close();
    end;

    [Test]
    procedure UnsavedKeyedRow_OnValidateUpdateFalse_Trace()
    var
        Row: Record "ALT Page Update Gone Row";
        Card: TestPage "ALT Page Update Gone Card";
    begin
        Row.DeleteAll();
        Card.OpenNew();
        Card.CodeField.SetValue('K');
        Trace.Reset();

        Card.NameField.SetValue('Kappa');

        Assert.AreEqual('Validate;', Trace.Get(), 'OnValidate CurrPage.Update(false) on an unsaved DelayedInsert row');
        Assert.IsFalse(Row.Get('K'), 'CurrPage.Update(false) must not save the DelayedInsert row');
        Card.Close();
    end;

    [Test]
    procedure UnsavedBlankRow_OnValidateUpdateFalse_Trace()
    var
        Row: Record "ALT Page Update Gone Row";
        Card: TestPage "ALT Page Update Gone Card";
    begin
        Row.DeleteAll();
        Card.OpenNew();
        Trace.Reset();

        Card.NameField.SetValue('Blank');

        Assert.AreEqual('Validate;', Trace.Get(), 'OnValidate CurrPage.Update(false) on an unsaved DelayedInsert row with no key');
        Assert.IsTrue(Row.IsEmpty(), 'CurrPage.Update(false) must not save the DelayedInsert row');
        Card.Close();
    end;

    [Test]
    procedure StoredRow_OnValidateUpdateFalse_Trace()
    var
        Card: TestPage "ALT Page Update Gone Card";
    begin
        Seed(true);
        Card.OpenEdit();
        Card.GoToKey('A');
        Trace.Reset();

        Card.NameField.SetValue('Alpha 2');

        Assert.AreEqual('Validate;AGR:A;AGCR:A;', Trace.Get(), 'control: OnValidate CurrPage.Update(false) on a stored row');
        Card.Close();
    end;
}
