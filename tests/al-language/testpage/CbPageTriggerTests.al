// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT CB Row / Empty / Log / Card / List / Navigate / Role Center (CbFixtures.al)
// Probe: corpus issue #667 items 25 to 32 (page triggers): a page-global Boolean handed to Rec in OnAfterGetCurrRecord as the table's
//        OnValidate sees it (the repro of microsoft/AL#7345); Find on an empty table in OnNewRecord under OpenNew; which triggers run around
//        an action Invoke on a NavigatePage, a Card and a List; a TestPage on a Role Center; AssistEdit in view mode; an error raised in
//        a table field OnLookup.
// Probe: written against a local BC 29.0 service tier; every literal asserted below is what that tier produced. 27.5 and 28.5 by the CI matrix.
// BC versions: 27 to 29 (CI matrix)

codeunit 84169 "LT CB Page Trigger Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT CB Log";

    local procedure Seed()
    var
        Row: Record "LT CB Row";
        Empty: Record "LT CB Empty";
    begin
        Row.DeleteAll();
        Empty.DeleteAll();
        Row.Init();
        Row."No." := 'R1';
        Row.Name := 'One';
        Row.Insert();
        Row.Init();
        Row."No." := 'R2';
        Row.Name := 'Two';
        Row.Insert();
        Log.SetNewRecordMode(0);
        Log.Take();
    end;

    // ---------- item 25: page global handed to Rec in OnAfterGetCurrRecord, read in the table's OnValidate ----------

    [Test]
    procedure ListPage_FlagFromOnAfterGetCurrRecord_InTableOnValidate()
    var
        Observer: Codeunit "Probe Observer";
        ListPage: Page "LT CB List";
        List: TestPage "LT CB List";
    begin
        Seed();
        List.Trap();
        ListPage.SetPageFlagOnPage(true);
        ListPage.Run();
        List.First();
        Log.Take();
        List.ShowFlag.Invoke();
        Observer.Observe('action_existing', Log.Take());
        List.NameCtl.SetValue('Changed');
        Observer.Observe('validate_existing', Log.Take());
        List.New();
        List.NoCtl.SetValue('R3');
        Log.Take();
        List.NameCtl.SetValue('Three');
        Observer.Observe('validate_new', Log.Take());
        List.Close();
        Observer.Expect('action_existing', 'list ShowFlag rec flag=Yes;');
        Observer.Expect('validate_existing', 'table Name.OnValidate flag=No;');
        Observer.Expect('validate_new', 'table Name.OnValidate flag=No;');
        Observer.Verify();
    end;

    // ---------- item 27: Find on an empty table in OnNewRecord, page opened with OpenNew ----------

    [TryFunction]
    local procedure TryOpenNew(var Card: TestPage "LT CB Card")
    begin
        Card.OpenNew();
    end;

    local procedure OpenNewWithMode(Mode: Integer; Name: Text; var Observer: Codeunit "Probe Observer")
    var
        Card: TestPage "LT CB Card";
    begin
        Seed();
        Log.SetNewRecordMode(Mode);
        ClearLastError();
        Observer.Observe(Name + '_ok', Format(TryOpenNew(Card)));
        Observer.ObserveError(Name);
        Observer.Observe(Name + '_log', Log.Take());
        Log.SetNewRecordMode(0);
    end;

    [Test]
    procedure OpenNew_OnNewRecordFindsInEmptyTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OpenNewWithMode(1, 'findfirst', Observer);
        OpenNewWithMode(2, 'find', Observer);
        OpenNewWithMode(3, 'recfind', Observer);
        OpenNewWithMode(4, 'iffind', Observer);
        Observer.Expect('findfirst_ok', 'Yes');
        Observer.Expect('findfirst|text', 'The LT CB Empty table is empty.');
        Observer.Expect('findfirst|code', 'DB:TableIsEmpty');
        Observer.Expect('findfirst_log', 'card OnNewRecord FindFirst;card OnNewRecord FindFirst;');
        Observer.Expect('find_ok', 'Yes');
        Observer.Expect('find|text', 'The LT CB Empty does not exist. Identification fields and values: No.=''''');
        Observer.Expect('find|code', 'DB:RecordNotFound');
        Observer.Expect('find_log', 'card OnNewRecord Find;card OnNewRecord Find;');
        Observer.Expect('recfind_ok', 'Yes');
        Observer.Expect('recfind|text', 'The LT CB Row does not exist. Identification fields and values: No.=''''');
        Observer.Expect('recfind|code', 'DB:RecordNotFound');
        Observer.Expect('recfind_log', 'card OnNewRecord Rec.Find;card OnNewRecord Rec.Find;');
        Observer.Expect('iffind_ok', 'Yes');
        Observer.Expect('iffind|text', '');
        Observer.Expect('iffind|code', '');
        Observer.Expect('iffind_log', 'card OnNewRecord if Find=No;card OnAfterGetCurrRecord ;');
        Observer.Verify();
    end;

    // ---------- item 28: triggers around an action Invoke on a NavigatePage, a Card and a List ----------

    [Test]
    procedure NavigatePage_ActionInvoke_TriggerOrder()
    var
        Observer: Codeunit "Probe Observer";
        Nav: TestPage "LT CB Navigate";
    begin
        Seed();
        Nav.OpenView();
        Observer.Observe('open', Log.Take());
        Nav.Act.Invoke();
        Observer.Observe('invoke1', Log.Take());
        Nav.Act.Invoke();
        Observer.Observe('invoke2', Log.Take());
        Nav.Close();
        Observer.Expect('open', 'nav OnAfterGetRecord R1;nav OnAfterGetCurrRecord R1;');
        Observer.Expect('invoke1', 'nav OnAfterGetRecord R1;nav OnAction R1;nav OnAfterGetRecord R1;nav OnAfterGetRecord R1;nav OnAfterGetCurrRecord R1;');
        Observer.Expect('invoke2', 'nav OnAfterGetRecord R1;nav OnAction R1;nav OnAfterGetRecord R1;nav OnAfterGetRecord R1;nav OnAfterGetCurrRecord R1;');
        Observer.Verify();
    end;

    [Test]
    procedure CardPage_ActionInvoke_TriggerOrder()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT CB Card";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('open', Log.Take());
        Card.Act.Invoke();
        Observer.Observe('invoke1', Log.Take());
        Card.Act.Invoke();
        Observer.Observe('invoke2', Log.Take());
        Card.Close();
        Observer.Expect('open', 'card OnAfterGetRecord R1;card OnAfterGetCurrRecord R1;');
        Observer.Expect('invoke1', 'card OnAfterGetRecord R1;card OnAction R1;card OnAfterGetRecord R1;card OnAfterGetRecord R1;card OnAfterGetCurrRecord R1;');
        Observer.Expect('invoke2', 'card OnAfterGetRecord R1;card OnAction R1;card OnAfterGetRecord R1;card OnAfterGetRecord R1;card OnAfterGetCurrRecord R1;');
        Observer.Verify();
    end;

    [Test]
    procedure ListPage_ActionInvoke_TriggerOrder()
    var
        Observer: Codeunit "Probe Observer";
        ListPage: Page "LT CB List";
        List: TestPage "LT CB List";
    begin
        Seed();
        List.Trap();
        ListPage.SetLogTriggers(true);
        ListPage.Run();
        Observer.Observe('open', Log.Take());
        List.Act.Invoke();
        Observer.Observe('invoke1', Log.Take());
        List.Next();
        Observer.Observe('next', Log.Take());
        List.Act.Invoke();
        Observer.Observe('invoke2', Log.Take());
        List.Close();
        Observer.Expect('open', 'list OnAfterGetRecord R1;list OnAfterGetRecord R2;list OnAfterGetRecord R1;list OnAfterGetRecord R1;list OnAfterGetCurrRecord R1;');
        Observer.Expect('invoke1', 'list OnAfterGetRecord R1;list OnAction R1;list OnAfterGetRecord R1;list OnAfterGetRecord R1;list OnAfterGetRecord R2;list OnAfterGetRecord R1;list OnAfterGetRecord R1;list OnAfterGetCurrRecord R1;');
        Observer.Expect('next', 'list OnAfterGetRecord R2;list OnAfterGetRecord R2;list OnAfterGetCurrRecord R2;');
        Observer.Expect('invoke2', 'list OnAfterGetRecord R2;list OnAction R2;list OnAfterGetRecord R2;list OnAfterGetRecord R2;list OnAfterGetRecord R1;list OnAfterGetRecord R2;list OnAfterGetRecord R2;list OnAfterGetCurrRecord R2;');
        Observer.Verify();
    end;

    // ---------- item 29: a TestPage on a Role Center; AssistEdit in view mode ----------

    [TryFunction]
    local procedure TryOpenRoleCenter(var Rc: TestPage "LT CB Role Center")
    begin
        Rc.OpenView();
    end;

    [TryFunction]
    local procedure TryInvokeRoleCenterAction(var Rc: TestPage "LT CB Role Center")
    begin
        Rc.RcAct.Invoke();
    end;

    [PageHandler]
    procedure CardPageHandler(var Pg: TestPage "LT CB Card")
    begin
        Log.Add('card handler');
    end;

    [Test]
    [HandlerFunctions('CardPageHandler')]
    procedure RoleCenter_TestPage_OpenAndInvoke()
    var
        Observer: Codeunit "Probe Observer";
        Rc: TestPage "LT CB Role Center";
    begin
        Seed();
        Log.Take();
        ClearLastError();
        Observer.Observe('open_ok', Format(TryOpenRoleCenter(Rc)));
        Observer.ObserveError('open');
        Observer.Observe('invoke_ok', Format(TryInvokeRoleCenterAction(Rc)));
        Observer.ObserveError('invoke');
        Observer.Observe('log', Log.Take());
        Observer.Expect('open_ok', 'Yes');
        Observer.Expect('open|text', '');
        Observer.Expect('open|code', '');
        Observer.Expect('invoke_ok', 'Yes');
        Observer.Expect('invoke|text', '');
        Observer.Expect('invoke|code', '');
        Observer.Expect('log', 'card OnAfterGetRecord R1;card OnAfterGetCurrRecord R1;card handler;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryAssistEdit(var Card: TestPage "LT CB Card")
    begin
        Card.AssistCtl.AssistEdit();
    end;

    [Test]
    procedure AssistEdit_InViewMode()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT CB Card";
    begin
        Seed();
        Card.OpenView();
        Card.GoToKey('R1');
        Log.Take();
        ClearLastError();
        Observer.Observe('view_ok', Format(TryAssistEdit(Card)));
        Observer.ObserveError('view');
        Observer.Observe('view_log', Log.Take());
        Card.Close();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Log.Take();
        Observer.Observe('edit_ok', Format(TryAssistEdit(Card)));
        Observer.ObserveError('edit');
        Observer.Observe('edit_log', Log.Take());
        Card.Close();
        Observer.Expect('view_ok', 'Yes');
        Observer.Expect('view|text', '');
        Observer.Expect('view|code', '');
        Observer.Expect('view_log', 'page AssistCtl.OnAssistEdit editable=No;card OnAfterGetRecord R1;card OnAfterGetCurrRecord R1;');
        Observer.Expect('edit_ok', 'Yes');
        Observer.Expect('edit|text', '');
        Observer.Expect('edit|code', '');
        Observer.Expect('edit_log', 'page AssistCtl.OnAssistEdit editable=Yes;card OnAfterGetRecord R1;card OnAfterGetCurrRecord R1;');
        Observer.Verify();
    end;

    // ---------- item 32: an error raised in a table field OnLookup, reached through TestPage Lookup() ----------

    [TryFunction]
    local procedure TryLookupErr(var Card: TestPage "LT CB Card")
    begin
        Card.LookupErrCtl.Lookup();
    end;

    [Test]
    procedure TableOnLookup_RaisesError_ThroughTestPage()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT CB Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.LookupErrCtl.SetValue('KEEP');
        Log.Take();
        ClearLastError();
        Observer.Observe('ok', Format(TryLookupErr(Card)));
        Observer.ObserveError('lookup');
        Observer.Observe('log', Log.Take());
        Observer.Observe('value_after', Card.LookupErrCtl.Value());
        Card.Close();
        Observer.Expect('ok', 'No');
        Observer.Expect('lookup|text', 'LT CB table lookup failed');
        Observer.Expect('lookup|code', 'TestWrapped:Dialog');
        Observer.Expect('log', 'table LookupErr.OnLookup;');
        Observer.Expect('value_after', 'KEEP');
        Observer.Verify();
    end;
}
