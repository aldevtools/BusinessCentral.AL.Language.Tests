// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-requiredtestisolation-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: MEASURED-PLACEHOLDER
// Object ids 87400-87413.
// BC versions: 27.5, 28.5, 29.0

// local object: the rows are written by this file's login subscriber and must outlive the test codeunit that wrote them
table 87400 "LGN DLW Login Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; "Session Id"; Integer) { }
        field(3; Kind; Code[10]) { }
        field(4; "Marks Seen"; Integer) { }
        field(5; "Call No."; Integer) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

// local object: what one test codeunit leaves for the next one; it must be committed and read by a later codeunit
table 87401 "LGN DLW Mark"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Code[30]) { }
        field(2; Value; Integer) { }
        field(3; At; DateTime) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}

// local object: the subscribers exist to be run by the login of each test codeunit's session; when they run is the subject.
// They write only in a Web session (the test session; not in background sessions) and never fail.
codeunit 87402 "LGN DLW Login Subs"
{
    local procedure Note(EventKind: Code[10])
    var
        Row: Record "LGN DLW Login Row";
        Mark: Record "LGN DLW Mark";
        Counter: Codeunit "LGN DLW Login Count";
    begin
        if CurrentClientType() <> ClientType::Web then
            exit;
        Row.Init();
        Row."Call No." := Counter.Add(EventKind);
        Row."Session Id" := SessionId();
        Row.Kind := EventKind;
        Row."Marks Seen" := Mark.Count();
        Row.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure AfterLogin()
    begin
        Note('LOGIN');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterAssistedSetup', '', false, false)]
    local procedure RegisterAssistedSetup()
    begin
        Note('REGISTER');
    end;
}

// singleinstance-shared-on-purpose: the subject is how often the login runs in the one session the test runner uses for several
// test codeunits; the counter is the session's memory of it and is never reset, and every test reads it relative to a mark.
codeunit 87412 "LGN DLW Login Count"
{
    SingleInstance = true;

    var
        LoginCalls: Integer;
        RegisterCalls: Integer;

    procedure Add(EventKind: Code[10]): Integer
    begin
        if EventKind = 'LOGIN' then begin
            LoginCalls += 1;
            exit(LoginCalls);
        end;
        RegisterCalls += 1;
        exit(RegisterCalls);
    end;

    procedure Calls(EventKind: Code[10]): Integer
    begin
        if EventKind = 'LOGIN' then
            exit(LoginCalls);
        exit(RegisterCalls);
    end;
}

// The reads and writes every test codeunit of this file shares.
codeunit 87403 "LGN DLW Probe"
{
    procedure LiveCalls(EventKind: Code[10]): Integer
    var
        Counter: Codeunit "LGN DLW Login Count";
    begin
        exit(Counter.Calls(EventKind));
    end;

    procedure AllRows(): Integer
    var
        Row: Record "LGN DLW Login Row";
    begin
        exit(Row.Count());
    end;

    procedure RowsAfter(EntryNo: Integer): Integer
    var
        Row: Record "LGN DLW Login Row";
    begin
        Row.SetFilter("Entry No.", '>%1', EntryNo);
        exit(Row.Count());
    end;

    procedure OwnCount(EventKind: Code[10]): Integer
    begin
        exit(SessionCount(SessionId(), EventKind));
    end;

    procedure SessionCount(SessionNo: Integer; EventKind: Code[10]): Integer
    var
        Row: Record "LGN DLW Login Row";
    begin
        Row.SetRange("Session Id", SessionNo);
        if EventKind <> '' then
            Row.SetRange(Kind, EventKind);
        exit(Row.Count());
    end;

    procedure OtherSessionsCount(): Integer
    var
        Row: Record "LGN DLW Login Row";
    begin
        Row.SetFilter("Session Id", '<>%1', SessionId());
        exit(Row.Count());
    end;

    procedure MaxEntry(): Integer
    var
        Row: Record "LGN DLW Login Row";
    begin
        if Row.FindLast() then
            exit(Row."Entry No.");
        exit(0);
    end;

    // Rows written after the entry, by sessions other than this one.
    procedure OthersAfter(EntryNo: Integer): Integer
    var
        Row: Record "LGN DLW Login Row";
    begin
        Row.SetFilter("Entry No.", '>%1', EntryNo);
        Row.SetFilter("Session Id", '<>%1', SessionId());
        exit(Row.Count());
    end;

    // Marks Seen of the newest login row; -1 without one.
    procedure NewestMarksSeen(): Integer
    var
        Row: Record "LGN DLW Login Row";
    begin
        Row.SetRange(Kind, 'LOGIN');
        if Row.FindLast() then
            exit(Row."Marks Seen");
        exit(-1);
    end;

    procedure DeleteAllRows()
    var
        Row: Record "LGN DLW Login Row";
    begin
        Row.DeleteAll();
    end;

    // What changed since the snapshot of a Disabled codeunit (SnapA): the session, the login and registration calls raised in this
    // session since then (the SingleInstance counter), the rows the login wrote since then, and the rows of the snapshot that are gone.
    procedure ObserveSince(var Observer: Codeunit "Probe Observer"; Prefix: Code[10])
    begin
        Observer.Observe('snapshot found', Format(Has(Prefix + ' MAX')));
        Observer.Observe('same session as the snapshot', Format(SessionId() = Get(Prefix + ' S')));
        Observer.Observe('OnAfterLogin calls since the snapshot', Format(LiveCalls('LOGIN') - Get(Prefix + ' CALLS')));
        Observer.Observe('OnRegisterAssistedSetup calls since the snapshot', Format(LiveCalls('REGISTER') - Get(Prefix + ' REGS')));
        Observer.Observe('rows written since the snapshot', Format(RowsAfter(Get(Prefix + ' MAX'))));
        Observer.Observe('rows of the snapshot gone', Format(Get(Prefix + ' ROWS') - (AllRows() - RowsAfter(Get(Prefix + ' MAX')))));
    end;

    procedure Put(MarkKey: Code[30]; NewValue: Integer)
    var
        Mark: Record "LGN DLW Mark";
    begin
        if Mark.Get(MarkKey) then begin
            Mark.Value := NewValue;
            Mark.Modify();
        end else begin
            Mark."Key" := MarkKey;
            Mark.Value := NewValue;
            Mark.Insert();
        end;
    end;

    procedure PutBool(MarkKey: Code[30]; NewValue: Boolean)
    begin
        if NewValue then
            Put(MarkKey, 1)
        else
            Put(MarkKey, 0);
    end;

    // Writes the mark, then stores in it the number of marks there are after it was written.
    procedure PutMarkCount(MarkKey: Code[30])
    var
        Mark: Record "LGN DLW Mark";
    begin
        Put(MarkKey, 0);
        Put(MarkKey, Mark.Count());
    end;

    procedure PutNow(MarkKey: Code[30])
    var
        Mark: Record "LGN DLW Mark";
    begin
        Put(MarkKey, 0);
        Mark.Get(MarkKey);
        Mark.At := CurrentDateTime();
        Mark.Modify();
    end;

    // The value of the mark; -1 when it does not exist.
    procedure Get(MarkKey: Code[30]): Integer
    var
        Mark: Record "LGN DLW Mark";
    begin
        if Mark.Get(MarkKey) then
            exit(Mark.Value);
        exit(-1);
    end;

    procedure Has(MarkKey: Code[30]): Boolean
    var
        Mark: Record "LGN DLW Mark";
    begin
        exit(Mark.Get(MarkKey));
    end;

    procedure GetAt(MarkKey: Code[30]): DateTime
    var
        Mark: Record "LGN DLW Mark";
    begin
        if Mark.Get(MarkKey) then
            exit(Mark.At);
        exit(0DT);
    end;

    // Snapshot of a Disabled A codeunit, taken in its first test (which never fails).
    procedure SnapA(Prefix: Code[10])
    begin
        Put(Prefix + ' S', SessionId());
        Put(Prefix + ' CALLS', LiveCalls('LOGIN'));
        Put(Prefix + ' REGS', LiveCalls('REGISTER'));
        Put(Prefix + ' ROWS', AllRows());
        Put(Prefix + ' MAX', MaxEntry());
        Put(Prefix + ' T1', 1);
        Put(Prefix + ' T2', 2);
    end;

    // Last test of a Disabled A codeunit: the number of marks it leaves, the time, then one minute and a second of waiting, so the
    // next session's login is not within the one minute in which "User Login Time Tracker" skips the update of User Login.
    procedure EndA(Prefix: Code[10])
    begin
        PutNow(Prefix + ' END');
        PutMarkCount(Prefix + ' MARKS');
        Sleep(61000);
    end;
}


// The anchor: a Disabled codeunit whose snapshot the two control codeunits compare with.
codeunit 87404 "LGN DLW Anchor"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    var
        Probe: Codeunit "LGN DLW Probe";

    [Test]
    procedure DLW_Anchor_Snap()
    begin
        Probe.SnapA('A0');
    end;

    [Test]
    procedure DLW_Anchor_Session()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('login rows of this session', Format(Probe.SessionCount(SessionId(), 'LOGIN')));
        Observer.Observe('registration rows of this session', Format(Probe.SessionCount(SessionId(), 'REGISTER')));
        Observer.Observe('OnAfterLogin calls in this session', Format(Probe.Get('A0 CALLS')));
        Observer.Observe('OnRegisterAssistedSetup calls in this session', Format(Probe.Get('A0 REGS')));
        Observer.Finish();
    end;
}

// Cell 6, control: two codeunits under Codeunit isolation after the anchor.
codeunit 87405 "LGN DLW Ctl A"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Probe: Codeunit "LGN DLW Probe";

    [Test]
    procedure DLW_CtlA_SinceAnchor()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveSince(Observer, 'A0');
        Observer.Finish();
    end;
}

codeunit 87406 "LGN DLW Ctl B"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Probe: Codeunit "LGN DLW Probe";

    [Test]
    procedure DLW_CtlB_SinceAnchor()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveSince(Observer, 'A0');
        Observer.Finish();
    end;
}

// Cells 1, 4 and 5: Disabled A, then Disabled B.
codeunit 87407 "LGN DLW G1 A"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    var
        Probe: Codeunit "LGN DLW Probe";

    [Test]
    procedure DLW_G1A_Snap()
    begin
        Probe.SnapA('G1A');
    end;

    [Test]
    procedure DLW_G1A_SinceAnchor()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveSince(Observer, 'A0');
        Observer.Finish();
    end;

    [Test]
    procedure DLW_G1A_End()
    begin
        Probe.EndA('G1A');
    end;
}

codeunit 87408 "LGN DLW G1 B"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    var
        Probe: Codeunit "LGN DLW Probe";

    [Test]
    procedure DLW_G1B_AfterDisabledA()
    var
        Observer: Codeunit "Probe Observer";
        Checklist: Codeunit Checklist;
        UserLoginTimeTracker: Codeunit "User Login Time Tracker";
    begin
        Probe.ObserveSince(Observer, 'G1A');
        Observer.Observe('newest login row saw every mark A left', Format(Probe.NewestMarksSeen() >= Probe.Get('G1A MARKS')));
        Observer.Observe('User Login updated after A ended', Format(UserLoginTimeTracker.UserLoggedInSinceDateTime(Probe.GetAt('G1A END'))));
        Observer.Observe('ShouldInitializeChecklist(false)', Format(Checklist.ShouldInitializeChecklist(false)));
        Observer.Finish();
    end;
}

// Cell 2: Disabled A, then B under Codeunit isolation.
codeunit 87409 "LGN DLW G2 A"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    var
        Probe: Codeunit "LGN DLW Probe";

    [Test]
    procedure DLW_G2A_Snap()
    begin
        Probe.SnapA('G2A');
    end;

    [Test]
    procedure DLW_G2A_SinceG1A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveSince(Observer, 'G1A');
        Observer.Finish();
    end;

    [Test]
    procedure DLW_G2A_End()
    begin
        Probe.EndA('G2A');
    end;
}

codeunit 87410 "LGN DLW G2 B"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Probe: Codeunit "LGN DLW Probe";

    [Test]
    procedure DLW_G2B_AfterDisabledA()
    var
        Observer: Codeunit "Probe Observer";
        Checklist: Codeunit Checklist;
        UserLoginTimeTracker: Codeunit "User Login Time Tracker";
    begin
        Probe.ObserveSince(Observer, 'G2A');
        Observer.Observe('newest login row saw every mark A left', Format(Probe.NewestMarksSeen() >= Probe.Get('G2A MARKS')));
        Observer.Observe('User Login updated after A ended', Format(UserLoginTimeTracker.UserLoggedInSinceDateTime(Probe.GetAt('G2A END'))));
        Observer.Observe('ShouldInitializeChecklist(false)', Format(Checklist.ShouldInitializeChecklist(false)));
        Observer.Finish();
    end;
}

// Cell 3: a Disabled codeunit deletes the login's rows, then the next codeunit reads them.
codeunit 87411 "LGN DLW G3 A"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    var
        Probe: Codeunit "LGN DLW Probe";

    [Test]
    procedure DLW_G3A_Snap()
    begin
        Probe.SnapA('G3A');
    end;

    [Test]
    procedure DLW_G3A_SinceG2A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveSince(Observer, 'G2A');
        Observer.Finish();
    end;

    [Test]
    procedure DLW_G3A_Delete()
    begin
        Probe.DeleteAllRows();
        Probe.Put('G3A AFTER DELETE', Probe.AllRows());
    end;

    [Test]
    procedure DLW_G3A_DeletedInNextTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows right after the delete', Format(Probe.Get('G3A AFTER DELETE')));
        Observer.Observe('rows in the next test', Format(Probe.AllRows()));
        Observer.Finish();
    end;
}

codeunit 87413 "LGN DLW G3 B"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    var
        Probe: Codeunit "LGN DLW Probe";

    [Test]
    procedure DLW_G3B_AfterDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows', Format(Probe.AllRows()));
        Observer.Observe('OnAfterLogin calls since A snapshot', Format(Probe.LiveCalls('LOGIN') - Probe.Get('G3A CALLS')));
        Observer.Observe('same session as A', Format(SessionId() = Probe.Get('G3A S')));
        Observer.Finish();
    end;
}
