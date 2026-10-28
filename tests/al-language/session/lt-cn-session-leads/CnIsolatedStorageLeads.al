// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/isolatedstorage/isolatedstorage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 84884 (CnTransferFieldsModify.al); self-contained codeunits 84887-84889, 84892-84893, 84899, page 84890, 84898, report 84891
// Probe: corpus issue #669 (writer CN).
//   55 (microsoft/AL#8142): IsolatedStorage.Set, Get, Delete inside a page background task worker, run with TestPage.RunPageBackgroundTask.
//   56 (microsoft/AL#5452): does IsolatedStorage.Set open a write transaction, so that a guarded Codeunit.Run, Page.RunModal or Report.RunModal
//       right after it is refused? And after a Commit?
//   57: the value length limit of IsolatedStorage.SetEncrypted (docs: 215 characters, special characters take more space).
// Keys start with LTCN and are deleted at the start of each test.
// Measured (local BC 29, checked by the CI matrix): the worker of TestPage.RunPageBackgroundTask runs read-only: Set and Delete fail with DB:ReadOnlySession,
//   like a Record.Insert; Get and Contains of a missing key answer false. Set and Delete open a write transaction (Contains does not), so a guarded
//   Codeunit.Run right after Set fails; after a Commit it runs. Page.RunModal and Report.RunModal right after Set run. SetEncrypted keeps 214 ASCII
//   characters and 107 two-byte characters; 216 ASCII and 108 two-byte characters fail with EncryptionDataTooLong (215: Linux suspect, see the procedure).
// BC versions: 27, 28, 29

codeunit 84887 "LT CN BgTask Iso Worker"
{
    trigger OnRun()
    var
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Op: Text;
        Value: Text;
        Row: Record "LT CN TF Row";
    begin
        Params := Page.GetBackgroundParameters();
        Params.Get('Op', Op);
        Results.Add('InWriteTx', Format(Database.IsInWriteTransaction(), 0, 9));
        case Op of
            'set':
                Results.Add('Ret', Format(IsolatedStorage.Set('LTCNbg', 'fromtask', DataScope::Module), 0, 9));
            'get':
                begin
                    Results.Add('Ret', Format(IsolatedStorage.Get('LTCNbg', DataScope::Module, Value), 0, 9));
                    Results.Add('Value', Value);
                end;
            'getmissing':
                begin
                    Results.Add('Contains', Format(IsolatedStorage.Contains('LTCNbgmiss', DataScope::Module), 0, 9));
                    Results.Add('Ret', Format(IsolatedStorage.Get('LTCNbgmiss', DataScope::Module, Value), 0, 9));
                    Results.Add('Value', Value);
                end;
            'delete':
                Results.Add('Ret', Format(IsolatedStorage.Delete('LTCNbg', DataScope::Module), 0, 9));
            'insert':
                begin
                    Row.Init();
                    Row.Id := 77;
                    Row.Name := 'task';
                    Results.Add('Ret', Format(Row.Insert(), 0, 9));
                end;
        end;
        Results.Add('InWriteTxAfter', Format(Database.IsInWriteTransaction(), 0, 9));
        Page.SetBackgroundTaskResult(Results);
    end;
}

page 84898 "LT CN BgTask Card"
{
    PageType = Card;
    SourceTable = "LT CN TF Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }
}

codeunit 84888 "LT CN BgTask Iso"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Clean()
    var
        Row: Record "LT CN TF Row";
    begin
        if IsolatedStorage.Contains('LTCNbg', DataScope::Module) then
            IsolatedStorage.Delete('LTCNbg', DataScope::Module);
        Row.DeleteAll();
        Commit();
    end;

    local procedure RunTask(Op: Text; var Observer: Codeunit "Probe Observer")
    var
        Card: TestPage "LT CN BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        K: Text;
    begin
        Params.Add('Op', Op);
        Card.OpenView();
        Results := Card.RunPageBackgroundTask(Codeunit::"LT CN BgTask Iso Worker", Params, false);
        Card.Close();
        foreach K in Results.Keys() do
            Observer.Observe(Op + ' ' + K, Results.Get(K));
    end;

    // The worker runs in a read-only session: a write to Isolated Storage is refused like a write to any table.
    [Test]
    procedure BgTask_IsolatedStorageSet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        asserterror RunTask('set', Observer);
        Observer.ObserveError('set');
        Observer.Observe('contains after', Format(IsolatedStorage.Contains('LTCNbg', DataScope::Module)));
        Observer.Expect('set|text', 'Sorry, the current permissions prevented the action. (TableData 2000000107 Isolated Storage Insert: AL Language Coverage Tests)');
        Observer.Expect('set|code', 'DB:ReadOnlySession');
        Observer.Expect('contains after', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure BgTask_IsolatedStorageDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        IsolatedStorage.Set('LTCNbg', 'seeded', DataScope::Module);
        Commit();
        asserterror RunTask('delete', Observer);
        Observer.ObserveError('delete');
        Observer.Observe('contains after', Format(IsolatedStorage.Contains('LTCNbg', DataScope::Module)));
        Observer.Expect('delete|text', 'Sorry, the current permissions prevented the action. (TableData 2000000107 Isolated Storage Delete: AL Language Coverage Tests)');
        Observer.Expect('delete|code', 'DB:ReadOnlySession');
        Observer.Expect('contains after', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure BgTask_RecordInsert_Control()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        Clean();
        asserterror RunTask('insert', Observer);
        Observer.ObserveError('insert');
        Observer.Observe('row after', Format(Row.Get(77)));
        Observer.Expect('insert|text', 'Sorry, the current permissions prevented the action. (TableData 84884 LT CN TF Row Insert: AL Language Coverage Tests)');
        Observer.Expect('insert|code', 'DB:ReadOnlySession');
        Observer.Expect('row after', 'No');
        Observer.Verify();
    end;
}

// Its own codeunit, and it writes nothing: a Get in the worker of a key the caller wrote in the same test transaction waits on the caller's
// lock and fails with a lock error (seen on BC 29 locally), which depends on the lock timeout and is not asserted.
codeunit 84899 "LT CN BgTask Iso Get"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BgTask_IsolatedStorageGetMissingKey()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT CN BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        K: Text;
    begin
        Params.Add('Op', 'getmissing');
        Card.OpenView();
        Results := Card.RunPageBackgroundTask(Codeunit::"LT CN BgTask Iso Worker", Params, false);
        Card.Close();
        foreach K in Results.Keys() do
            Observer.Observe(K, Results.Get(K));
        Observer.Expect('InWriteTx', 'false');
        Observer.Expect('Contains', 'false');
        Observer.Expect('Ret', 'false');
        Observer.Expect('Value', '');
        Observer.Expect('InWriteTxAfter', 'false');
        Observer.Verify();
    end;
}

codeunit 84889 "LT CN Noop"
{
    trigger OnRun()
    begin
    end;
}

page 84890 "LT CN Modal Page"
{
    PageType = Card;
    UsageCategory = None;
    SourceTable = "LT CN TF Row";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }
}

report 84891 "LT CN Proc Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(N; Integer)
        {
            DataItemTableView = where(Number = const(1));
        }
    }
}

codeunit 84892 "LT CN Iso WriteTx"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ModalSeen: Integer;

    local procedure Clean()
    begin
        if IsolatedStorage.Contains('LTCNtx', DataScope::User) then
            IsolatedStorage.Delete('LTCNtx', DataScope::User);
        if IsolatedStorage.Contains('LTCNtx', DataScope::Module) then
            IsolatedStorage.Delete('LTCNtx', DataScope::Module);
        Commit();
    end;

    [Test]
    procedure IsoSet_OpensWriteTransaction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        Observer.Observe('before', Format(Database.IsInWriteTransaction()));
        IsolatedStorage.Set('LTCNtx', 'v', DataScope::User);
        Observer.Observe('after set user', Format(Database.IsInWriteTransaction()));
        Commit();
        IsolatedStorage.Set('LTCNtx', 'v', DataScope::Module);
        Observer.Observe('after set module', Format(Database.IsInWriteTransaction()));
        Commit();
        IsolatedStorage.Delete('LTCNtx', DataScope::Module);
        Observer.Observe('after delete', Format(Database.IsInWriteTransaction()));
        Commit();
        Observer.Observe('contains', Format(IsolatedStorage.Contains('LTCNtx', DataScope::User)));
        Observer.Observe('after contains', Format(Database.IsInWriteTransaction()));
        Observer.Expect('before', 'No');
        Observer.Expect('after set user', 'Yes');
        Observer.Expect('after set module', 'Yes');
        Observer.Expect('after delete', 'Yes');
        Observer.Expect('contains', 'Yes');
        Observer.Expect('after contains', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure IsoSet_ThenGuardedCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        IsolatedStorage.Set('LTCNtx', 'v', DataScope::User);
        asserterror Observer.Observe('run', Format(Codeunit.Run(Codeunit::"LT CN Noop")));
        Observer.ObserveError('run');
        Observer.Expect('run|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('run|code', 'DB:Ok');
        Observer.Verify();
    end;

    [Test]
    procedure IsoSet_Commit_ThenGuardedCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        IsolatedStorage.Set('LTCNtx', 'v', DataScope::User);
        Commit();
        Observer.Observe('run', Format(Codeunit.Run(Codeunit::"LT CN Noop")));
        Observer.Expect('run', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalHandler')]
    procedure IsoSet_ThenPageRunModal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        ModalSeen := 0;
        IsolatedStorage.Set('LTCNtx', 'v', DataScope::User);
        Observer.Observe('action', Format(Page.RunModal(Page::"LT CN Modal Page")));
        Observer.Observe('handler calls', Format(ModalSeen));
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('handler calls', '1');
        Observer.Verify();
    end;

    [Test]
    procedure IsoSet_ThenReportRunModal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        IsolatedStorage.Set('LTCNtx', 'v', DataScope::User);
        Report.RunModal(Report::"LT CN Proc Report", false);
        Observer.Observe('reached', 'yes');
        Observer.Expect('reached', 'yes');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure ModalHandler(var P: TestPage "LT CN Modal Page")
    begin
        ModalSeen += 1;
    end;
}

codeunit 84893 "LT CN SetEncrypted Len"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Clean()
    begin
        if IsolatedStorage.Contains('LTCNenc', DataScope::Module) then
            IsolatedStorage.Delete('LTCNenc', DataScope::Module);
    end;

    local procedure SetAndReadBack(Value: Text; var Observer: Codeunit "Probe Observer")
    var
        Back: Text;
    begin
        Clean();
        Observer.Observe('ret', Format(IsolatedStorage.SetEncrypted('LTCNenc', Value, DataScope::Module)));
        Observer.Observe('get', Format(IsolatedStorage.Get('LTCNenc', DataScope::Module, Back)));
        Observer.Observe('same back', Format(Back = Value));
        Clean();
    end;

    local procedure SetFails(Value: Text; var Observer: Codeunit "Probe Observer")
    begin
        Clean();
        asserterror IsolatedStorage.SetEncrypted('LTCNenc', Value, DataScope::Module);
        Observer.ObserveError('set');
        Observer.Observe('contains', Format(IsolatedStorage.Contains('LTCNenc', DataScope::Module)));
    end;

    [Test]
    procedure SetEncrypted_EncryptionEnabled()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('encryption enabled', Format(EncryptionEnabled()));
        Observer.Expect('encryption enabled', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SetEncrypted_214Ascii()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetAndReadBack(PadStr('', 214, 'a'), Observer);
        Observer.Expect('ret', 'Yes');
        Observer.Expect('get', 'Yes');
        Observer.Expect('same back', 'Yes');
        Observer.Verify();
    end;

    // Not a test (Linux suspect, queued for the Windows check): on the Linux BC container 215 ASCII characters fail with 'Unknown error',
    // code UnknownEncryption:OpenSslCryptographic (an OpenSSL exception), while 216 and more fail with BC's own length check. The docs give 215 as the limit.
    procedure SetEncrypted_215Ascii()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetFails(PadStr('', 215, 'a'), Observer);
        Observer.Finish();
    end;

    [Test]
    procedure SetEncrypted_216Ascii()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetFails(PadStr('', 216, 'a'), Observer);
        Observer.Expect('set|text', 'Unable to encrypt data. The provided string is too long.');
        Observer.Expect('set|code', 'EncryptionDataTooLong');
        Observer.Expect('contains', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure SetEncrypted_107NonAscii()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetAndReadBack(PadStr('', 107, 'é'), Observer);
        Observer.Expect('ret', 'Yes');
        Observer.Expect('get', 'Yes');
        Observer.Expect('same back', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SetEncrypted_108NonAscii()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetFails(PadStr('', 108, 'é'), Observer);
        Observer.Expect('set|text', 'Unable to encrypt data. The provided string is too long.');
        Observer.Expect('set|code', 'EncryptionDataTooLong');
        Observer.Expect('contains', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Set_Plain_1000Ascii_Control()
    var
        Observer: Codeunit "Probe Observer";
        Back: Text;
    begin
        Clean();
        Observer.Observe('ret', Format(IsolatedStorage.Set('LTCNenc', PadStr('', 1000, 'a'), DataScope::Module)));
        IsolatedStorage.Get('LTCNenc', DataScope::Module, Back);
        Observer.Observe('len back', Format(StrLen(Back)));
        Clean();
        Observer.Expect('ret', 'Yes');
        Observer.Expect('len back', '1000');
        Observer.Verify();
    end;
}

// Writer QB (corpus issue #669 item 55, the Get of a key the caller wrote): the caller writes the key in its test transaction, then the worker
// of a page background task reads it. One codeunit without and one with a Commit() in the caller, each its own transaction.
codeunit 86382 "LT QB BgTask Iso GetLocked"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BgTask_IsolatedStorageGet_KeyWrittenByCaller_QB()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT CN BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        K: Text;
    begin
        Observer.Observe('caller set', Format(IsolatedStorage.Set('LTCNbg', 'fromcaller', DataScope::Module), 0, 9));
        Params.Add('Op', 'get');
        Card.OpenView();
        ClearLastError();
        if TryRun(Card, Params, Results) then
            Observer.Observe('get', 'ok')
        else
            Observer.ObserveError('get');
        foreach K in Results.Keys() do
            Observer.Observe(K, Results.Get(K));
        Card.Close();
        Observer.Expect('caller set', 'true');
        Observer.Expect('get', 'ok');
        Observer.Expect('InWriteTx', 'false');
        Observer.Expect('Ret', 'false');
        Observer.Expect('Value', '');
        Observer.Expect('InWriteTxAfter', 'false');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRun(var Card: TestPage "LT CN BgTask Card"; Params: Dictionary of [Text, Text]; var Results: Dictionary of [Text, Text])
    begin
        Results := Card.RunPageBackgroundTask(Codeunit::"LT CN BgTask Iso Worker", Params, false);
    end;
}

codeunit 86383 "LT QB BgTask Iso GetCommitted"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BgTask_IsolatedStorageGet_KeyWrittenByCallerThenCommit_QB()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT CN BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        K: Text;
    begin
        Observer.Observe('caller set', Format(IsolatedStorage.Set('LTCNbg', 'fromcaller', DataScope::Module), 0, 9));
        Commit();
        Params.Add('Op', 'get');
        Card.OpenView();
        ClearLastError();
        if TryRun(Card, Params, Results) then
            Observer.Observe('get', 'ok')
        else
            Observer.ObserveError('get');
        foreach K in Results.Keys() do
            Observer.Observe(K, Results.Get(K));
        Card.Close();
        Observer.Expect('caller set', 'true');
        Observer.Expect('get|text', 'We can''t save your changes right now, because a record in table ''Isolated Storage'' is being updated in a transaction done by another session.\\You''ll have to wait until the other transaction has completed, which may take a while. Please try again later.');
        Observer.Expect('get|code', 'NDBCS:LockTimeout');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRun(var Card: TestPage "LT CN BgTask Card"; Params: Dictionary of [Text, Text]; var Results: Dictionary of [Text, Text])
    begin
        Results := Card.RunPageBackgroundTask(Codeunit::"LT CN BgTask Iso Worker", Params, false);
    end;
}
