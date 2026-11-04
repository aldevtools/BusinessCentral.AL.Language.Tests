// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P82 Card (71187), LT P82 List (71188), LT P82 Item (71184), LT P82 Log (71186) from P82Fixtures.al
// Probe: written against BC 29 (runtime 16); the facts are measured later
// Facts: CurrPage.Update(false/true/default), Close, Editable, SaveRecord, SetSelectionFilter, ObjectId(true/false), Caption (read and assigned) called from page actions, with the trigger log and the stored rows
// BC versions: 29

codeunit 71202 "LT P82 CurrPage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Item: Record "LT P82 Item";
        Log: Codeunit "LT P82 Log";
    begin
        Item.DeleteAll();
        Log.Reset();
        Item."No." := 'A';
        Item.Name := 'Alpha';
        Item.Qty := 1;
        Item.Insert();
        Item."No." := 'B';
        Item.Name := 'Beta';
        Item.Qty := 2;
        Item.Insert();
        Item."No." := 'C';
        Item.Name := 'Gamma';
        Item.Qty := 3;
        Item.Insert();
    end;

    [Test]
    procedure Update_False_KeepsPendingEdit()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Item: Record "LT P82 Item";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('A');
        Observer.Observe('log-open', Log.Dump());
        Log.Reset();
        Card.NameCtl.SetValue('Edited');
        Observer.Observe('log-after-setvalue', Log.Dump());
        Log.Reset();
        Card.ActUpdate.Invoke();
        Observer.Observe('log-after-update-false', Log.Dump());
        Observer.Observe('name-on-page', Card.NameCtl.Value());
        Item.Get('A');
        Observer.Observe('name-stored', Item.Name);
        Card.Close();
        Item.Get('A');
        Observer.Observe('name-stored-after-close', Item.Name);
        Observer.Expect('log-open', 'OnOpenPage;OnAfterGetRecord(A);OnAfterGetRecord(A)');
        Observer.Expect('log-after-setvalue', '');
        Observer.Expect('log-after-update-false', 'OnAfterGetRecord(A);OnAfterGetRecord(A);OnAfterGetRecord(A)');
        Observer.Expect('name-on-page', 'Edited');
        Observer.Expect('name-stored', 'Edited');
        Observer.Expect('name-stored-after-close', 'Edited');
        Observer.Verify();
    end;

    [Test]
    procedure Update_True_SavesPendingEdit()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Item: Record "LT P82 Item";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('B');
        Card.NameCtl.SetValue('Edited B');
        Log.Reset();
        Card.ActUpdateSave.Invoke();
        Observer.Observe('log-after-update-true', Log.Dump());
        Item.Get('B');
        Observer.Observe('name-stored', Item.Name);
        Card.Close();
        Observer.Expect('log-after-update-true', 'OnAfterGetRecord(B);OnAfterGetRecord(B);OnAfterGetRecord(B)');
        Observer.Expect('name-stored', 'Edited B');
        Observer.Verify();
    end;

    [Test]
    procedure Update_Default_Overload()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Item: Record "LT P82 Item";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('B');
        Card.NameCtl.SetValue('Edited default');
        Log.Reset();
        Card.ActUpdateDefault.Invoke();
        Observer.Observe('log-after-update', Log.Dump());
        Item.Get('B');
        Observer.Observe('name-stored', Item.Name);
        Card.Close();
        Observer.Expect('log-after-update', 'OnAfterGetRecord(B);OnAfterGetRecord(B);OnAfterGetRecord(B)');
        Observer.Expect('name-stored', 'Edited default');
        Observer.Verify();
    end;

    [Test]
    procedure Update_PicksUpRowChangedBehindThePage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Item: Record "LT P82 Item";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('C');
        Observer.Observe('name-before', Card.NameCtl.Value());
        Item.Get('C');
        Item.Name := 'Changed behind';
        Item.Modify();
        Observer.Observe('name-before-update', Card.NameCtl.Value());
        Card.ActUpdate.Invoke();
        Observer.Observe('name-after-update', Card.NameCtl.Value());
        Card.Close();
        Observer.Expect('name-before', 'Gamma');
        Observer.Expect('name-before-update', 'Gamma');
        Observer.Expect('name-after-update', 'Changed behind');
        Observer.Verify();
    end;

    [Test]
    procedure Close_FromAction_Triggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Card.GoToKey('A');
        Log.Reset();
        Card.ActClose.Invoke();
        Observer.Observe('log-after-currpage-close', Log.Dump());
        Observer.Expect('log-after-currpage-close', 'OnAfterGetRecord(A);OnQueryClosePage(OK);OnClosePage;OnAfterGetRecord(A)');
        Observer.Verify();
    end;

    [Test]
    procedure Close_TestPageClose_Triggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Log.Reset();
        Card.Close();
        Observer.Observe('log-after-testpage-close', Log.Dump());
        Observer.Expect('log-after-testpage-close', 'OnQueryClosePage(OK);OnClosePage');
        Observer.Verify();
    end;

    [Test]
    procedure Close_ThenUseTestPage()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Card.ActClose.Invoke();
        asserterror Observer.Observe('name-after-close', Card.NameCtl.Value());
        Observer.ObserveError('value-after-currpage-close');
        asserterror Card.ActUpdate.Invoke();
        Observer.ObserveError('invoke-after-currpage-close');
        asserterror Card.Close();
        Observer.ObserveError('close-after-currpage-close');
        Observer.Expect('value-after-currpage-close|text', 'The TestPage is not open.');
        Observer.Expect('value-after-currpage-close|code', 'TestPageNotOpened');
        Observer.Expect('invoke-after-currpage-close|text', 'The TestPage is not open.');
        Observer.Expect('invoke-after-currpage-close|code', 'TestPageNotOpened');
        Observer.Expect('close-after-currpage-close|text', 'The TestPage is not open.');
        Observer.Expect('close-after-currpage-close|code', 'TestPageNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure Editable_ReadInTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.ActEditRead.Invoke();
        Card.ActEditF.Invoke();
        Card.ActEditRead.Invoke();
        Card.ActEditT.Invoke();
        Card.ActEditRead.Invoke();
        Card.Close();
        Observer.Observe('log', Log.Dump());
        Log.Reset();
        Card.OpenView();
        Card.ActEditRead.Invoke();
        Card.ActEditT.Invoke();
        Card.ActEditRead.Invoke();
        Card.Close();
        Observer.Observe('log-view', Log.Dump());
        Observer.Expect('log', 'OnOpenPage;OnAfterGetRecord(A);OnAfterGetRecord(A);Editable=Yes;OnAfterGetRecord(A);OnAfterGetRecord(A);OnAfterGetRecord(A);OnAfterGetRecord(A);OnAfterGetRecord(A);OnAfterGetRecord(A);Editable=Yes;OnAfterGetRecord(A);OnAfterGetRecord(A);OnAfterGetRecord(A);OnAfterGetRecord(A);OnAfterGetRecord(A);OnAfterGetRecord(A);Editable=Yes;OnAfterGetRecord(A);OnAfterGetRecord(A);OnQueryClosePage(OK);OnClosePage');
        Observer.Expect('log-view', 'OnOpenPage;OnAfterGetRecord(A);OnAfterGetRecord(A);Editable=No;OnAfterGetRecord(A);OnAfterGetRecord(A);OnAfterGetRecord(A);OnAfterGetRecord(A);OnAfterGetRecord(A);OnAfterGetRecord(A);Editable=No;OnAfterGetRecord(A);OnAfterGetRecord(A);OnQueryClosePage(OK);OnClosePage');
        Observer.Verify();
    end;

    [Test]
    procedure SaveRecord_StoresPendingEdit()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Item: Record "LT P82 Item";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('A');
        Card.NameCtl.SetValue('Saved by action');
        Item.Get('A');
        Observer.Observe('stored-before', Item.Name);
        Card.ActSave.Invoke();
        Item.Get('A');
        Observer.Observe('stored-after', Item.Name);
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Observer.Expect('stored-before', 'Alpha');
        Observer.Expect('stored-after', 'Saved by action');
        Observer.Expect('log', 'OnOpenPage;OnAfterGetRecord(A);OnAfterGetRecord(A);OnAfterGetRecord(A);saved;OnAfterGetRecord(A)');
        Observer.Verify();
    end;

    [Test]
    procedure SaveRecord_InViewMode()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Card.ActSave.Invoke();
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Observer.Expect('log', 'OnOpenPage;OnAfterGetRecord(A);OnAfterGetRecord(A);saved;OnAfterGetRecord(A)');
        Observer.Verify();
    end;

    [Test]
    procedure SaveRecord_NewRecordWithoutKey()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P82 Item";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenNew();
        Card.NameCtl.SetValue('No key yet');
        Card.ActSave.Invoke();
        Observer.Observe('save-without-key', 'no error');
        Observer.Observe('count', Format(Item.Count()));
        Observer.Expect('save-without-key', 'no error');
        Observer.Expect('count', '4');
        Observer.Verify();
    end;

    [Test]
    procedure SetSelectionFilter_OnTheCurrentRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        List: TestPage "LT P82 List";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('log-open', Log.Dump());
        Log.Reset();
        List.First();
        List.ActSelFilter.Invoke();
        List.Next();
        List.ActSelFilter.Invoke();
        List.Last();
        List.ActSelFilter.Invoke();
        Observer.Observe('log', Log.Dump());
        List.Close();
        Observer.Expect('log-open', 'List OnOpenPage filter=');
        Observer.Expect('log', 'sel=1 filter=A;sel=1 filter=B;sel=1 filter=C');
        Observer.Verify();
    end;

    [Test]
    procedure SetSelectionFilter_WithPageFilter()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        List: TestPage "LT P82 List";
    begin
        Seed();
        List.OpenView();
        List.Filter.SetFilter(Qty, '>=2');
        List.First();
        List.ActSelFilter.Invoke();
        Observer.Observe('log', Log.Dump());
        List.Close();
        Observer.Expect('log', 'List OnOpenPage filter=;sel=1 filter=B');
        Observer.Verify();
    end;

    [Test]
    procedure SetSelectionFilter_EmptyPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Item: Record "LT P82 Item";
        List: TestPage "LT P82 List";
    begin
        Item.DeleteAll();
        Log.Reset();
        List.OpenView();
        List.ActSelFilter.Invoke();
        Observer.Observe('log', Log.Dump());
        List.Close();
        Observer.Expect('log', 'List OnOpenPage filter=;sel=0 filter=''''');
        Observer.Verify();
    end;

    [Test]
    procedure ObjectId_WithAndWithoutName()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Card.ActObjId.Invoke();
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Observer.Expect('log', 'OnOpenPage;OnAfterGetRecord(A);OnAfterGetRecord(A);id1=Page LT P82 Card Caption;id0=Page 71187;OnAfterGetRecord(A);OnAfterGetRecord(A)');
        Observer.Verify();
    end;

    [Test]
    procedure Caption_ReadAndAssign()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('testpage-caption-before', Card.Caption());
        Card.ActCaption.Invoke();
        Card.ActSetCaption.Invoke();
        Observer.Observe('testpage-caption-after', Card.Caption());
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Card.OpenView();
        Observer.Observe('testpage-caption-reopened', Card.Caption());
        Card.Close();
        Observer.Expect('testpage-caption-before', 'LT P82 Card Caption - A');
        Observer.Expect('testpage-caption-after', 'Changed caption - A');
        Observer.Expect('log', 'OnOpenPage;OnAfterGetRecord(A);OnAfterGetRecord(A);caption=LT P82 Card Caption;OnAfterGetRecord(A);OnAfterGetRecord(A);OnAfterGetRecord(A);caption=Changed caption;OnAfterGetRecord(A);OnAfterGetRecord(A)');
        Observer.Expect('testpage-caption-reopened', 'LT P82 Card Caption - A');
        Observer.Verify();
    end;

    [Test]
    procedure Caption_List_Open()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P82 List";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('list-caption', List.Caption());
        List.Close();
        List.OpenEdit();
        Observer.Observe('list-caption-edit', List.Caption());
        List.Close();
        Observer.Expect('list-caption', 'LT P82 List Caption');
        Observer.Expect('list-caption-edit', 'LT P82 List Caption');
        Observer.Verify();
    end;

    [Test]
    procedure LookupMode_ReadInAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        List: TestPage "LT P82 List";
    begin
        Seed();
        List.OpenView();
        List.ActLookupMode.Invoke();
        List.Close();
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'List OnOpenPage filter=;LookupMode=No');
        Observer.Verify();
    end;

    [Test]
    procedure ActionError_Surfaces()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Card.GoToKey('B');
        asserterror Card.ActErr.Invoke();
        Observer.ObserveError('action-error');
        Observer.Observe('no-after', Card.NoCtl.Value());
        Card.Close();
        Observer.Expect('action-error|text', 'P82 action error B');
        Observer.Expect('action-error|code', 'TestWrapped:Dialog');
        Observer.Expect('no-after', 'B');
        Observer.Verify();
    end;

    [Test]
    procedure OnQueryClosePage_CloseActionText()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.Close();
        Observer.Observe('log-edit', Log.Dump());
        Log.Reset();
        Card.OpenNew();
        Card.NoCtl.SetValue('QC1');
        Card.Close();
        Observer.Observe('log-new', Log.Dump());
        Observer.Expect('log-edit', 'OnOpenPage;OnAfterGetRecord(A);OnQueryClosePage(OK);OnClosePage');
        Observer.Expect('log-new', 'OnOpenPage;OnQueryClosePage(OK);OnClosePage');
        Observer.Verify();
    end;
}
