// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/application/system/table/system.environment.active-session
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 88721 reads the table from another object.
// Probe: al-runner issue 5807 (aldevtools/BusinessCentral.AL.Runner). Writes to the platform table Active Session (2000000110): a test copies
//   the row of its own session, gives it another Session ID and inserts it to stand in for a second live session. Pinned here: Insert(false)
//   and Insert(true) of such a copy, Get and Count from another codeunit, Insert of an Init'ed row, Insert of a duplicate key (own key and a second Insert), Modify and
//   Delete of an inserted row, and the rollback of an Insert inside asserterror. Session ids, instance ids and user names belong to the
//   environment, so every observation is a found/not-found answer, a count difference, a value the test wrote itself, or an error text
//   with those numbers replaced by <instance> and <session>. The rows are written in the test's own transaction (test isolation rolls
//   them back). The read-only side is pinned in session/TestActiveSessionTable.al.
// BC versions: 27, 28, 29. Object ids 88720-88721.

codeunit 88720 "LT RV Active Session Writes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure OtherSessionId(Offset: Integer): Integer
    begin
        // Session ids of live sessions are positive: a negative id far from zero belongs to no session.
        exit(-1000000 - Offset);
    end;

    local procedure CopyOwnRow(var ActiveSession: Record "Active Session"; NewSessionId: Integer; NewUserId: Text)
    begin
        ActiveSession.Get(ServiceInstanceId(), SessionId());
        ActiveSession.Validate("Session ID", NewSessionId);
        ActiveSession.Validate("Session Unique ID", CreateGuid());
        ActiveSession.Validate("User ID", CopyStr(NewUserId, 1, MaxStrLen(ActiveSession."User ID")));
    end;

    local procedure Scrubbed(Value: Text; OtherId: Integer): Text
    begin
        Value := Value.Replace(StrSubstNo('''%1''', OtherId), '<other>');
        Value := Value.Replace(StrSubstNo('''%1''', SessionId()), '<session>');
        Value := Value.Replace(StrSubstNo('''%1''', ServiceInstanceId()), '<instance>');
        exit(Value);
    end;

    // al-runner issue 5807: the reporter's shape. Insert(false) of a copy of the own row, then Get from another codeunit.
    [Test]
    procedure RV_ActiveSession_InsertCopy_FoundByGetElsewhere()
    var
        Observer: Codeunit "Probe Observer";
        ActiveSession: Record "Active Session";
        Holder: Codeunit "LT RV Session Holder";
        OtherId: Integer;
        CountBefore: Integer;
    begin
        OtherId := OtherSessionId(1);
        CountBefore := ActiveSession.Count();
        CopyOwnRow(ActiveSession, OtherId, 'LT RV OTHER PLANNER');
        Observer.Observe('insert', Format(ActiveSession.Insert(false)));
        Observer.Observe('holder', Holder.HolderOfSession(ServiceInstanceId(), OtherId));
        Observer.Observe('found by get', Format(Holder.Exists(ServiceInstanceId(), OtherId)));
        Observer.Observe('count difference', Format(Holder.CountAll() - CountBefore));
        Observer.Observe('count of other id', Format(Holder.CountOfSession(OtherId)));
        Observer.Observe('own row still there', Format(Holder.Exists(ServiceInstanceId(), SessionId())));
        Observer.Observe('own row user unchanged', Format(Holder.HolderOfSession(ServiceInstanceId(), SessionId()) = UserId()));
        Observer.Expect('insert', 'Yes');
        Observer.Expect('holder', 'LT RV OTHER PLANNER');
        Observer.Expect('found by get', 'Yes');
        Observer.Expect('count difference', '1');
        Observer.Expect('count of other id', '1');
        Observer.Expect('own row still there', 'Yes');
        Observer.Expect('own row user unchanged', 'Yes');
        Observer.Verify();
    end;

    // Insert(true) of the same kind of copy (a platform table has no AL triggers).
    [Test]
    procedure RV_ActiveSession_InsertTrue_FoundByGet()
    var
        Observer: Codeunit "Probe Observer";
        ActiveSession: Record "Active Session";
        Holder: Codeunit "LT RV Session Holder";
        OtherId: Integer;
    begin
        OtherId := OtherSessionId(2);
        CopyOwnRow(ActiveSession, OtherId, 'LT RV TRUE');
        Observer.Observe('insert', Format(ActiveSession.Insert(true)));
        Observer.Observe('holder', Holder.HolderOfSession(ServiceInstanceId(), OtherId));
        Observer.Expect('insert', 'Yes');
        Observer.Expect('holder', 'LT RV TRUE');
        Observer.Verify();
    end;

    // An Init'ed row with only the key and the user set: what the other columns read back.
    [Test]
    procedure RV_ActiveSession_InsertInitRow_ColumnsReadBack()
    var
        Observer: Codeunit "Probe Observer";
        ActiveSession: Record "Active Session";
        ReadBack: Record "Active Session";
        OtherId: Integer;
    begin
        OtherId := OtherSessionId(3);
        ActiveSession.Init();
        ActiveSession."Server Instance ID" := ServiceInstanceId();
        ActiveSession."Session ID" := OtherId;
        ActiveSession."User ID" := 'LT RV INIT';
        Observer.Observe('exists before', Format(ReadBack.Get(ServiceInstanceId(), OtherId)));
        ClearLastError();
        Observer.Observe('insert', Format(ActiveSession.Insert()));
        Observer.Observe('insert error', Scrubbed(GetLastErrorText(), OtherId));
        Observer.Observe('get', Format(ReadBack.Get(ServiceInstanceId(), OtherId)));
        Observer.Observe('session id', Format(ReadBack."Session ID" = OtherId));
        Observer.Observe('user id', ReadBack."User ID");
        Observer.Observe('user sid null', Format(IsNullGuid(ReadBack."User SID")));
        Observer.Observe('unique id null', Format(IsNullGuid(ReadBack."Session Unique ID")));
        Observer.Observe('login datetime', Format(ReadBack."Login Datetime" = 0DT));
        Observer.Observe('client type', Format(ReadBack."Client Type"));
        Observer.Observe('client computer name', ReadBack."Client Computer Name");
        Observer.Observe('server computer name', ReadBack."Server Computer Name");
        Observer.Observe('server instance name', ReadBack."Server Instance Name");
        Observer.Observe('database name', ReadBack."Database Name");
        Observer.Finish();
    end;

    // Insert of a row whose key is the own session's key, and a second Insert of an inserted row.
    [Test]
    procedure RV_ActiveSession_InsertDuplicateKey_Error()
    var
        Observer: Codeunit "Probe Observer";
        ActiveSession: Record "Active Session";
        Holder: Codeunit "LT RV Session Holder";
        OtherId: Integer;
    begin
        ActiveSession.Get(ServiceInstanceId(), SessionId());
        ActiveSession."User ID" := 'LT RV DUPLICATE';
        ClearLastError();
        Observer.Observe('own key insert', Format(ActiveSession.Insert(false)));
        Observer.Observe('own key insert error', Scrubbed(GetLastErrorText(), 0));
        Observer.Observe('own key rows', Format(Holder.CountOfSession(SessionId())));
        Observer.Observe('own key user unchanged', Format(Holder.HolderOfSession(ServiceInstanceId(), SessionId()) = UserId()));
        OtherId := OtherSessionId(7);
        CopyOwnRow(ActiveSession, OtherId, 'LT RV FIRST');
        ActiveSession.Insert(false);
        ActiveSession."User ID" := 'LT RV SECOND';
        ClearLastError();
        Observer.Observe('second insert', Format(ActiveSession.Insert(false)));
        Observer.Observe('second insert error', Scrubbed(GetLastErrorText(), OtherId));
        Observer.Observe('holder after second', Holder.HolderOfSession(ServiceInstanceId(), OtherId));
        Observer.Observe('rows of other id', Format(Holder.CountOfSession(OtherId)));
        Observer.Finish();
    end;

    // Modify and Delete of an inserted row, read back from another codeunit.
    [Test]
    procedure RV_ActiveSession_ModifyAndDeleteInsertedRow()
    var
        Observer: Codeunit "Probe Observer";
        ActiveSession: Record "Active Session";
        Holder: Codeunit "LT RV Session Holder";
        OtherId: Integer;
    begin
        OtherId := OtherSessionId(4);
        Observer.Observe('exists before', Format(Holder.Exists(ServiceInstanceId(), OtherId)));
        CopyOwnRow(ActiveSession, OtherId, 'LT RV BEFORE');
        ActiveSession.Insert(false);
        Observer.Observe('holder after insert', Holder.HolderOfSession(ServiceInstanceId(), OtherId));
        ActiveSession."User ID" := 'LT RV AFTER';
        ClearLastError();
        Observer.Observe('modify', Format(ActiveSession.Modify(false)));
        Observer.Observe('modify error', Scrubbed(GetLastErrorText(), OtherId));
        Observer.Observe('holder after modify', Holder.HolderOfSession(ServiceInstanceId(), OtherId));
        Observer.Observe('delete', Format(ActiveSession.Delete(false)));
        Observer.Observe('found after delete', Format(Holder.Exists(ServiceInstanceId(), OtherId)));
        Observer.Observe('own row after delete', Format(Holder.Exists(ServiceInstanceId(), SessionId())));
        Observer.Finish();
    end;

    // An Insert inside asserterror is rolled back with the error.
    [Test]
    procedure RV_ActiveSession_InsertRolledBackByAssertError()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT RV Session Holder";
        OtherId: Integer;
    begin
        OtherId := OtherSessionId(5);
        asserterror Holder.InsertCopyThenFail(OtherId, 'LT RV ROLLED BACK');
        Observer.ObserveError('error');
        Observer.Observe('found after rollback', Format(Holder.Exists(ServiceInstanceId(), OtherId)));
        Observer.Expect('error|text', 'LT RV inserted LT RV ROLLED BACK');
        Observer.Expect('error|code', 'Dialog');
        Observer.Expect('found after rollback', 'No');
        Observer.Verify();
    end;

    // The Session virtual table (2000000009) for the id of an inserted Active Session row.
    [Test]
    procedure RV_ActiveSession_InsertedRow_InSessionVirtualTable()
    var
        Observer: Codeunit "Probe Observer";
        ActiveSession: Record "Active Session";
        Session: Record Session;
        OtherId: Integer;
    begin
        OtherId := OtherSessionId(6);
        CopyOwnRow(ActiveSession, OtherId, 'LT RV VIRTUAL');
        ActiveSession.Insert(false);
        Session.SetRange("Connection ID", OtherId);
        Observer.Observe('session rows', Format(Session.Count()));
        Observer.Expect('session rows', '0');
        Observer.Verify();
    end;
}

codeunit 88721 "LT RV Session Holder"
{
    procedure HolderOfSession(InstanceId: Integer; SessId: Integer): Text
    var
        ActiveSession: Record "Active Session";
    begin
        if not ActiveSession.Get(InstanceId, SessId) then
            exit('<none>');
        exit(ActiveSession."User ID");
    end;

    procedure Exists(InstanceId: Integer; SessId: Integer): Boolean
    var
        ActiveSession: Record "Active Session";
    begin
        exit(ActiveSession.Get(InstanceId, SessId));
    end;

    procedure CountAll(): Integer
    var
        ActiveSession: Record "Active Session";
    begin
        exit(ActiveSession.Count());
    end;

    procedure CountOfSession(SessId: Integer): Integer
    var
        ActiveSession: Record "Active Session";
    begin
        ActiveSession.SetRange("Session ID", SessId);
        exit(ActiveSession.Count());
    end;

    procedure InsertCopyThenFail(NewSessionId: Integer; NewUserId: Text)
    var
        ActiveSession: Record "Active Session";
    begin
        ActiveSession.Get(ServiceInstanceId(), SessionId());
        ActiveSession."Session ID" := NewSessionId;
        ActiveSession."Session Unique ID" := CreateGuid();
        ActiveSession."User ID" := CopyStr(NewUserId, 1, MaxStrLen(ActiveSession."User ID"));
        ActiveSession.Insert(false);
        Error('LT RV inserted %1', ActiveSession."User ID");
    end;
}
