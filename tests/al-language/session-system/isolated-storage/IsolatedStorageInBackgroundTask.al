// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/isolatedstorage/isolatedstorage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT CN TF Row" (84884, record/crud/CnTransferFieldsModify.al) and page "LT CN BgTask Card"
//   (84898, session-system/CnIsolatedStorageLeads.al); own worker codeunit 75105, pages 75106-75107, test codeunits 75108-75114
// Probe (observe only): al-runner issue 7576. CnIsolatedStorageLeads.al pins, for a page background task worker: Get and Contains of a missing key
//   with the result used (false), Get of a key the test wrote and did not commit (false), and Get of a key the test wrote and committed
//   (NDBCS:LockTimeout). The report measured on BC 29 that the lock timeout does not depend on the key, also happens when an earlier test of the
//   codeunit wrote, and that Get as a statement of a missing key raises DB:RecordNotFound when nothing in the codeunit wrote Isolated Storage.
//   This probe measures, on every version, for a worker started with TestPage.RunPageBackgroundTask:
//     75108 nothing in the codeunit writes Isolated Storage: function form, statement form (DataScope Module and Company)
//     75109 the test wrote a key and did not commit: the same key, another key, statement form
//     75110 the test wrote a key and committed: another key, Contains only, statement form of another key
//     75111 an earlier test of the codeunit wrote a key and committed: the same key, another key, after a committed Delete
//     75112 an earlier test of the codeunit wrote a key and did not commit: the same key, another key, statement form (in one test)
//     75113 the test committed a row of another table and wrote no Isolated Storage (control)
//   and for a task enqueued by a FactBox with CurrPage.EnqueueBackgroundTask (the reported pages), whose outcome reaches
//   OnPageBackgroundTaskCompleted or OnPageBackgroundTaskError and is sent as a notification:
//     75108 a missing key as a statement when nothing wrote;  75114 a key the test wrote and committed, and a key nobody wrote in a later test.
//   A lock timeout takes about 10 seconds per task. Keys start with LTISB; the tests that commit a key delete it again and commit at their end.
//   The tests of a codeunit depend on their order (the default order). The first test of 75111 and of 75112 only writes; it asserts the
//   return value of Set (pinned in CnIsolatedStorageLeads.al) and passes, so its write stays for the tests after it.
// BC versions: 27, 28, 29

codeunit 75105 "LT ISB Worker"
{
    trigger OnRun()
    var
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Op: Text;
        StorageKey: Text;
        Value: Text;
        Scope: DataScope;
    begin
        Params := Page.GetBackgroundParameters();
        Op := Params.Get('Op');
        StorageKey := Params.Get('Key');
        if Params.Get('Scope') = 'Company' then
            Scope := DataScope::Company
        else
            Scope := DataScope::Module;
        case Op of
            'function':
                begin
                    Results.Add('Contains', Format(IsolatedStorage.Contains(StorageKey, Scope), 0, 9));
                    Results.Add('Ret', Format(IsolatedStorage.Get(StorageKey, Scope, Value), 0, 9));
                    Results.Add('Value', Value);
                end;
            'contains':
                Results.Add('Contains', Format(IsolatedStorage.Contains(StorageKey, Scope), 0, 9));
            'statement':
                begin
                    IsolatedStorage.Get(StorageKey, Scope, Value);
                    Results.Add('Value', Value);
                end;
            'contains then statement':
                begin
                    Results.Add('Contains', Format(IsolatedStorage.Contains(StorageKey, Scope), 0, 9));
                    IsolatedStorage.Get(StorageKey, Scope, Value);
                    Results.Add('Value', Value);
                end;
        end;
        Page.SetBackgroundTaskResult(Results);
    end;
}

page 75106 "LT ISB Store Part"
{
    PageType = CardPart;
    SourceTable = "LT CN TF Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }

    var
        TaskId: Integer;

    trigger OnAfterGetCurrRecord()
    var
        Parameters: Dictionary of [Text, Text];
    begin
        if Rec.Id = 0 then
            exit;
        Parameters.Add('Op', 'contains then statement');
        Parameters.Add('Key', Rec.Name);
        Parameters.Add('Scope', 'Company');
        CurrPage.EnqueueBackgroundTask(TaskId, Codeunit::"LT ISB Worker", Parameters);
    end;

    trigger OnPageBackgroundTaskCompleted(CompletedTaskId: Integer; Results: Dictionary of [Text, Text])
    var
        Done: Notification;
    begin
        Done.Message := StrSubstNo('completed contains [%1] value [%2]', Results.Get('Contains'), Results.Get('Value'));
        Done.Send();
    end;

    trigger OnPageBackgroundTaskError(ErrorTaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    var
        Failed: Notification;
    begin
        Failed.Message := StrSubstNo('error [%1] [%2]', ErrorCode, ErrorText);
        Failed.Send();
        IsHandled := true;
    end;
}

page 75107 "LT ISB Store Host"
{
    PageType = List;
    SourceTable = "LT CN TF Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part(Details; "LT ISB Store Part")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
        }
    }
}

codeunit 75108 "LT ISB No Write"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        NotificationText: Text;

    local procedure OpenHostOn(RowId: Integer; StorageKey: Text[30])
    var
        Row: Record "LT CN TF Row";
        Host: TestPage "LT ISB Store Host";
    begin
        if Row.Get(RowId) then
            Row.Delete();
        Row.Init();
        Row.Id := RowId;
        Row.Name := StorageKey;
        Row.Insert();
        Commit();
        NotificationText := '';
        Host.OpenView();
        Host.GoToRecord(Row);
        Host.Close();
        Row.Delete();
        Commit();
    end;

    [SendNotificationHandler]
    procedure RecordNotification(var Sent: Notification): Boolean
    begin
        NotificationText += Sent.Message + ';';
    end;

    local procedure RunWorker(var Observer: Codeunit "Probe Observer"; Name: Text; Op: Text; StorageKey: Text; Scope: Text)
    var
        Card: TestPage "LT CN BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        K: Text;
        Answer: Text;
    begin
        Params.Add('Op', Op);
        Params.Add('Key', StorageKey);
        Params.Add('Scope', Scope);
        Card.OpenView();
        ClearLastError();
        if TryRun(Card, Params, Results) then begin
            foreach K in Results.Keys() do
                Answer += K + '=' + Results.Get(K) + ' ';
            Observer.Observe(Name, 'ok ' + Answer);
        end else
            Observer.ObserveError(Name);
        Card.Close();
    end;

    [TryFunction]
    local procedure TryRun(var Card: TestPage "LT CN BgTask Card"; Params: Dictionary of [Text, Text]; var Results: Dictionary of [Text, Text])
    begin
        Results := Card.RunPageBackgroundTask(Codeunit::"LT ISB Worker", Params, false);
    end;

    [Test]
    procedure NoWrite_FunctionForm_MissingKey()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        RunWorker(Observer, 'function form, Module', 'function', 'LTISBnobody', 'Module');
        RunWorker(Observer, 'function form, Company', 'function', 'LTISBnobody', 'Company');
        Observer.Expect('function form, Module', 'ok Contains=false Ret=false Value= ');
        Observer.Expect('function form, Company', 'ok Contains=false Ret=false Value= ');
        Observer.Verify();
    end;

    [Test]
    procedure NoWrite_StatementForm_MissingKey_Module()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        RunWorker(Observer, 'statement form, Module', 'statement', 'LTISBnobody', 'Module');
        Observer.Expect('statement form, Module|text', 'The Isolated Storage does not exist. Identification fields and values: App Id=''{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}'',Scope=''Module'',Company Name='''',User Id=''{00000000-0000-0000-0000-000000000000}'',Key=''LTISBnobody''');
        Observer.Expect('statement form, Module|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure NoWrite_StatementForm_MissingKey_Company()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        RunWorker(Observer, 'statement form, Company', 'statement', 'LTISBnobody', 'Company');
        RunWorker(Observer, 'Contains then statement form, Company', 'contains then statement', 'LTISBnobody', 'Company');
        Observer.Expect('statement form, Company|text', 'The Isolated Storage does not exist. Identification fields and values: App Id=''{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}'',Scope=''Company'',Company Name=''<Company>'',User Id=''{00000000-0000-0000-0000-000000000000}'',Key=''LTISBnobody''');
        Observer.Expect('statement form, Company|code', 'DB:RecordNotFound');
        Observer.Expect('Contains then statement form, Company|text', 'The Isolated Storage does not exist. Identification fields and values: App Id=''{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}'',Scope=''Company'',Company Name=''<Company>'',User Id=''{00000000-0000-0000-0000-000000000000}'',Key=''LTISBnobody''');
        Observer.Expect('Contains then statement form, Company|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RecordNotification')]
    procedure NoWrite_EnqueuedTask_StatementForm_MissingKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OpenHostOn(751081, 'LTISBnobody');
        Observer.Observe('notifications', NotificationText);
        Observer.Expect('notifications', 'error [DB:RecordNotFound] [The Isolated Storage does not exist. Identification fields and values: App Id=''{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}'',Scope=''Company'',Company Name=''<Company>'',User Id=''{00000000-0000-0000-0000-000000000000}'',Key=''LTISBnobody''];');
        Observer.Verify();
    end;
}

codeunit 75109 "LT ISB Written In Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure RunWorker(var Observer: Codeunit "Probe Observer"; Name: Text; Op: Text; StorageKey: Text; Scope: Text)
    var
        Card: TestPage "LT CN BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        K: Text;
        Answer: Text;
    begin
        Params.Add('Op', Op);
        Params.Add('Key', StorageKey);
        Params.Add('Scope', Scope);
        Card.OpenView();
        ClearLastError();
        if TryRun(Card, Params, Results) then begin
            foreach K in Results.Keys() do
                Answer += K + '=' + Results.Get(K) + ' ';
            Observer.Observe(Name, 'ok ' + Answer);
        end else
            Observer.ObserveError(Name);
        Card.Close();
    end;

    [TryFunction]
    local procedure TryRun(var Card: TestPage "LT CN BgTask Card"; Params: Dictionary of [Text, Text]; var Results: Dictionary of [Text, Text])
    begin
        Results := Card.RunPageBackgroundTask(Codeunit::"LT ISB Worker", Params, false);
    end;

    [Test]
    procedure WrittenNotCommitted_FunctionForm_SameKey()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        Observer.Observe('caller set', Format(IsolatedStorage.Set('LTISBk1', 'fromcaller', DataScope::Module), 0, 9));
        RunWorker(Observer, 'same key', 'function', 'LTISBk1', 'Module');
        Observer.Expect('caller set', 'true');
        Observer.Expect('same key', 'ok Contains=false Ret=false Value= ');
        Observer.Verify();
    end;

    [Test]
    procedure WrittenNotCommitted_FunctionForm_OtherKey()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        Observer.Observe('caller set', Format(IsolatedStorage.Set('LTISBk1', 'fromcaller', DataScope::Module), 0, 9));
        RunWorker(Observer, 'other key', 'function', 'LTISBk2', 'Module');
        Observer.Expect('caller set', 'true');
        Observer.Expect('other key', 'ok Contains=false Ret=false Value= ');
        Observer.Verify();
    end;

    [Test]
    procedure WrittenNotCommitted_StatementForm()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        Observer.Observe('caller set', Format(IsolatedStorage.Set('LTISBk1', 'fromcaller', DataScope::Module), 0, 9));
        RunWorker(Observer, 'statement, same key', 'statement', 'LTISBk1', 'Module');
        RunWorker(Observer, 'statement, other key', 'statement', 'LTISBk2', 'Module');
        Observer.Expect('caller set', 'true');
        Observer.Expect('statement, same key|text', 'The Isolated Storage does not exist. Identification fields and values: App Id=''{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}'',Scope=''Module'',Company Name='''',User Id=''{00000000-0000-0000-0000-000000000000}'',Key=''LTISBk1''');
        Observer.Expect('statement, same key|code', 'DB:RecordNotFound');
        Observer.Expect('statement, other key|text', 'The Isolated Storage does not exist. Identification fields and values: App Id=''{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}'',Scope=''Module'',Company Name='''',User Id=''{00000000-0000-0000-0000-000000000000}'',Key=''LTISBk2''');
        Observer.Expect('statement, other key|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;
}

codeunit 75110 "LT ISB Committed In Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure RunWorker(var Observer: Codeunit "Probe Observer"; Name: Text; Op: Text; StorageKey: Text; Scope: Text)
    var
        Card: TestPage "LT CN BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        K: Text;
        Answer: Text;
    begin
        Params.Add('Op', Op);
        Params.Add('Key', StorageKey);
        Params.Add('Scope', Scope);
        Card.OpenView();
        ClearLastError();
        if TryRun(Card, Params, Results) then begin
            foreach K in Results.Keys() do
                Answer += K + '=' + Results.Get(K) + ' ';
            Observer.Observe(Name, 'ok ' + Answer);
        end else
            Observer.ObserveError(Name);
        Card.Close();
    end;

    [TryFunction]
    local procedure TryRun(var Card: TestPage "LT CN BgTask Card"; Params: Dictionary of [Text, Text]; var Results: Dictionary of [Text, Text])
    begin
        Results := Card.RunPageBackgroundTask(Codeunit::"LT ISB Worker", Params, false);
    end;

    [Test]
    procedure WrittenCommitted_FunctionForm_OtherKey()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        Observer.Observe('caller set', Format(IsolatedStorage.Set('LTISBk1', 'fromcaller', DataScope::Module), 0, 9));
        Commit();
        RunWorker(Observer, 'other key', 'function', 'LTISBk2', 'Module');
        IsolatedStorage.Delete('LTISBk1', DataScope::Module);
        Commit();
        Observer.Expect('caller set', 'true');
        Observer.Expect('other key', 'ok Contains=false Ret=false Value= ');
        Observer.Verify();
    end;

    [Test]
    procedure WrittenCommitted_ContainsOnly_SameKey()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        Observer.Observe('caller set', Format(IsolatedStorage.Set('LTISBk1', 'fromcaller', DataScope::Module), 0, 9));
        Commit();
        RunWorker(Observer, 'contains, same key', 'contains', 'LTISBk1', 'Module');
        IsolatedStorage.Delete('LTISBk1', DataScope::Module);
        Commit();
        Observer.Expect('caller set', 'true');
        Observer.Expect('contains, same key', 'ok Contains=true ');
        Observer.Verify();
    end;

    [Test]
    procedure WrittenCommitted_StatementForm_OtherKey()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        Observer.Observe('caller set', Format(IsolatedStorage.Set('LTISBk1', 'fromcaller', DataScope::Module), 0, 9));
        Commit();
        RunWorker(Observer, 'statement, other key', 'statement', 'LTISBk2', 'Module');
        IsolatedStorage.Delete('LTISBk1', DataScope::Module);
        Commit();
        Observer.Expect('caller set', 'true');
        Observer.Expect('statement, other key|text', 'The Isolated Storage does not exist. Identification fields and values: App Id=''{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}'',Scope=''Module'',Company Name='''',User Id=''{00000000-0000-0000-0000-000000000000}'',Key=''LTISBk2''');
        Observer.Expect('statement, other key|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure WrittenCommitted_OtherScope()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        Observer.Observe('caller set', Format(IsolatedStorage.Set('LTISBk1', 'fromcaller', DataScope::Module), 0, 9));
        Commit();
        RunWorker(Observer, 'function form, Company scope, same key name', 'function', 'LTISBk1', 'Company');
        IsolatedStorage.Delete('LTISBk1', DataScope::Module);
        Commit();
        Observer.Expect('caller set', 'true');
        Observer.Expect('function form, Company scope, same key name', 'ok Contains=false Ret=false Value= ');
        Observer.Verify();
    end;
}

codeunit 75111 "LT ISB Earlier Test Committed"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure RunWorker(var Observer: Codeunit "Probe Observer"; Name: Text; Op: Text; StorageKey: Text; Scope: Text)
    var
        Card: TestPage "LT CN BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        K: Text;
        Answer: Text;
    begin
        Params.Add('Op', Op);
        Params.Add('Key', StorageKey);
        Params.Add('Scope', Scope);
        Card.OpenView();
        ClearLastError();
        if TryRun(Card, Params, Results) then begin
            foreach K in Results.Keys() do
                Answer += K + '=' + Results.Get(K) + ' ';
            Observer.Observe(Name, 'ok ' + Answer);
        end else
            Observer.ObserveError(Name);
        Card.Close();
    end;

    [TryFunction]
    local procedure TryRun(var Card: TestPage "LT CN BgTask Card"; Params: Dictionary of [Text, Text]; var Results: Dictionary of [Text, Text])
    begin
        Results := Card.RunPageBackgroundTask(Codeunit::"LT ISB Worker", Params, false);
    end;

    [Test]
    procedure EarlierCommitted_1_WriteAndCommit()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        Observer.Observe('caller set', Format(IsolatedStorage.Set('LTISBk1', 'fromcaller', DataScope::Module), 0, 9));
        Commit();
        Observer.Expect('caller set', 'true');
        Observer.Verify();
    end;

    [Test]
    procedure EarlierCommitted_2_FunctionForm_SameKey()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        RunWorker(Observer, 'same key', 'function', 'LTISBk1', 'Module');
        Observer.Expect('same key|text', 'We can''t save your changes right now, because a record in table ''Isolated Storage'' is being updated in a transaction done by another session.\\You''ll have to wait until the other transaction has completed, which may take a while. Please try again later.');
        Observer.Expect('same key|code', 'NDBCS:LockTimeout');
        Observer.Verify();
    end;

    [Test]
    procedure EarlierCommitted_3_FunctionForm_OtherKey()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        RunWorker(Observer, 'other key', 'function', 'LTISBk2', 'Module');
        Observer.Expect('other key', 'ok Contains=false Ret=false Value= ');
        Observer.Verify();
    end;

    [Test]
    procedure EarlierCommitted_4_StatementForm_OtherKey()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        RunWorker(Observer, 'statement, other key', 'statement', 'LTISBk2', 'Module');
        Observer.Expect('statement, other key|text', 'The Isolated Storage does not exist. Identification fields and values: App Id=''{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}'',Scope=''Module'',Company Name='''',User Id=''{00000000-0000-0000-0000-000000000000}'',Key=''LTISBk2''');
        Observer.Expect('statement, other key|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure EarlierCommitted_5_AfterCommittedDelete()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        Observer.Observe('caller delete', Format(IsolatedStorage.Delete('LTISBk1', DataScope::Module), 0, 9));
        Commit();
        RunWorker(Observer, 'deleted key', 'function', 'LTISBk1', 'Module');
        Observer.Expect('caller delete', 'true');
        Observer.Expect('deleted key', 'ok Contains=false Ret=false Value= ');
        Observer.Verify();
    end;
}

codeunit 75112 "LT ISB Earlier Uncommitted"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure RunWorker(var Observer: Codeunit "Probe Observer"; Name: Text; Op: Text; StorageKey: Text; Scope: Text)
    var
        Card: TestPage "LT CN BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        K: Text;
        Answer: Text;
    begin
        Params.Add('Op', Op);
        Params.Add('Key', StorageKey);
        Params.Add('Scope', Scope);
        Card.OpenView();
        ClearLastError();
        if TryRun(Card, Params, Results) then begin
            foreach K in Results.Keys() do
                Answer += K + '=' + Results.Get(K) + ' ';
            Observer.Observe(Name, 'ok ' + Answer);
        end else
            Observer.ObserveError(Name);
        Card.Close();
    end;

    [TryFunction]
    local procedure TryRun(var Card: TestPage "LT CN BgTask Card"; Params: Dictionary of [Text, Text]; var Results: Dictionary of [Text, Text])
    begin
        Results := Card.RunPageBackgroundTask(Codeunit::"LT ISB Worker", Params, false);
    end;

    [Test]
    procedure EarlierUncommitted_1_Write()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        // Asserted, not observed: a failing test would roll the write back, and the next tests need it in the codeunit's transaction.
        Observer.Observe('caller set', Format(IsolatedStorage.Set('LTISBk3', 'fromcaller', DataScope::Module), 0, 9));
        Observer.Expect('caller set', 'true');
        Observer.Verify();
    end;

    [Test]
    procedure EarlierUncommitted_2_SameKeyOtherKeyStatement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        Observer.Observe('caller still has the key', Format(IsolatedStorage.Contains('LTISBk3', DataScope::Module), 0, 9));
        RunWorker(Observer, 'same key', 'function', 'LTISBk3', 'Module');
        RunWorker(Observer, 'other key', 'function', 'LTISBk2', 'Module');
        RunWorker(Observer, 'statement, other key', 'statement', 'LTISBk2', 'Module');
        Observer.Expect('caller still has the key', 'true');
        Observer.Expect('same key|text', 'We can''t save your changes right now, because a record in table ''Isolated Storage'' is being updated in a transaction done by another session.\\You''ll have to wait until the other transaction has completed, which may take a while. Please try again later.');
        Observer.Expect('same key|code', 'NDBCS:LockTimeout');
        Observer.Expect('other key', 'ok Contains=false Ret=false Value= ');
        Observer.Expect('statement, other key|text', 'The Isolated Storage does not exist. Identification fields and values: App Id=''{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}'',Scope=''Module'',Company Name='''',User Id=''{00000000-0000-0000-0000-000000000000}'',Key=''LTISBk2''');
        Observer.Expect('statement, other key|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;
}

codeunit 75113 "LT ISB Other Table Committed"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure RunWorker(var Observer: Codeunit "Probe Observer"; Name: Text; Op: Text; StorageKey: Text; Scope: Text)
    var
        Card: TestPage "LT CN BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        K: Text;
        Answer: Text;
    begin
        Params.Add('Op', Op);
        Params.Add('Key', StorageKey);
        Params.Add('Scope', Scope);
        Card.OpenView();
        ClearLastError();
        if TryRun(Card, Params, Results) then begin
            foreach K in Results.Keys() do
                Answer += K + '=' + Results.Get(K) + ' ';
            Observer.Observe(Name, 'ok ' + Answer);
        end else
            Observer.ObserveError(Name);
        Card.Close();
    end;

    [TryFunction]
    local procedure TryRun(var Card: TestPage "LT CN BgTask Card"; Params: Dictionary of [Text, Text]; var Results: Dictionary of [Text, Text])
    begin
        Results := Card.RunPageBackgroundTask(Codeunit::"LT ISB Worker", Params, false);
    end;

    [Test]
    procedure OtherTableCommitted_FunctionForm_MissingKey()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        if Row.Get(751130) then
            Row.Delete();
        Row.Init();
        Row.Id := 751130;
        Row.Insert();
        Commit();
        RunWorker(Observer, 'function form', 'function', 'LTISBnobody', 'Module');
        Row.Delete();
        Commit();
        Observer.Expect('function form', 'ok Contains=false Ret=false Value= ');
        Observer.Verify();
    end;

    [Test]
    procedure OtherTableCommitted_StatementForm_MissingKey()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        if Row.Get(751130) then
            Row.Delete();
        Row.Init();
        Row.Id := 751130;
        Row.Insert();
        Commit();
        RunWorker(Observer, 'statement form', 'statement', 'LTISBnobody', 'Module');
        Row.Delete();
        Commit();
        Observer.Expect('statement form|text', 'The Isolated Storage does not exist. Identification fields and values: App Id=''{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}'',Scope=''Module'',Company Name='''',User Id=''{00000000-0000-0000-0000-000000000000}'',Key=''LTISBnobody''');
        Observer.Expect('statement form|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure OtherTableCommitted_CallerOnlyReadsIsolatedStorage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        Observer.Observe('caller contains', Format(IsolatedStorage.Contains('LTISBnobody', DataScope::Module), 0, 9));
        Commit();
        RunWorker(Observer, 'function form', 'function', 'LTISBnobody', 'Module');
        Observer.Expect('caller contains', 'false');
        Observer.Expect('function form', 'ok Contains=false Ret=false Value= ');
        Observer.Verify();
    end;
}

codeunit 75114 "LT ISB Enqueued After Write"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        NotificationText: Text;

    local procedure OpenHostOn(RowId: Integer; StorageKey: Text[30])
    var
        Row: Record "LT CN TF Row";
        Host: TestPage "LT ISB Store Host";
    begin
        if Row.Get(RowId) then
            Row.Delete();
        Row.Init();
        Row.Id := RowId;
        Row.Name := StorageKey;
        Row.Insert();
        Commit();
        NotificationText := '';
        Host.OpenView();
        Host.GoToRecord(Row);
        Host.Close();
        Row.Delete();
        Commit();
    end;

    [SendNotificationHandler]
    procedure RecordNotification(var Sent: Notification): Boolean
    begin
        NotificationText += Sent.Message + ';';
    end;

    [Test]
    [HandlerFunctions('RecordNotification')]
    procedure Enqueued_1_KeyTheTestWroteAndCommitted()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('caller set', Format(IsolatedStorage.Set('LTISBk4', 'committed value', DataScope::Company), 0, 9));
        Commit();
        OpenHostOn(751141, 'LTISBk4');
        Observer.Observe('notifications', NotificationText);
        Observer.Expect('caller set', 'true');
        Observer.Expect('notifications', 'error [NDBCS:LockTimeout] [We can''t save your changes right now, because a record in table ''Isolated Storage'' is being updated in a transaction done by another session.\\You''ll have to wait until the other transaction has completed, which may take a while. Please try again later.];');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RecordNotification')]
    procedure Enqueued_2_KeyNobodyWrote_AfterTheEarlierTestWrote()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OpenHostOn(751142, 'LTISBnobody');
        Observer.Observe('notifications', NotificationText);
        Observer.Expect('notifications', 'error [DB:RecordNotFound] [The Isolated Storage does not exist. Identification fields and values: App Id=''{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}'',Scope=''Company'',Company Name=''<Company>'',User Id=''{00000000-0000-0000-0000-000000000000}'',Key=''LTISBnobody''];');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RecordNotification')]
    procedure Enqueued_3_AfterCommittedDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('caller delete', Format(IsolatedStorage.Delete('LTISBk4', DataScope::Company), 0, 9));
        Commit();
        OpenHostOn(751143, 'LTISBk4');
        Observer.Observe('notifications', NotificationText);
        Observer.Expect('caller delete', 'true');
        Observer.Expect('notifications', 'error [DB:RecordNotFound] [The Isolated Storage does not exist. Identification fields and values: App Id=''{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}'',Scope=''Company'',Company Name=''<Company>'',User Id=''{00000000-0000-0000-0000-000000000000}'',Key=''LTISBk4''];');
        Observer.Verify();
    end;
}
