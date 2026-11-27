// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-requiredtestisolation-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: MEASURED-PLACEHOLDER
// Object ids 87400-87411.
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
    begin
        if CurrentClientType() <> ClientType::Web then
            exit;
        Row.Init();
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

// The reads and writes every test codeunit of this file shares.
codeunit 87403 "LGN DLW Probe"
{
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

    // Marks Seen of this session's first login row; -1 without one.
    procedure OwnMarksSeen(): Integer
    var
        Row: Record "LGN DLW Login Row";
    begin
        Row.SetRange("Session Id", SessionId());
        Row.SetRange(Kind, 'LOGIN');
        if Row.FindFirst() then
            exit(Row."Marks Seen");
        exit(-1);
    end;

    procedure DeleteOwnRows()
    var
        Row: Record "LGN DLW Login Row";
    begin
        Row.SetRange("Session Id", SessionId());
        Row.DeleteAll();
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
        Put(Prefix + ' LOGIN', OwnCount('LOGIN'));
        Put(Prefix + ' REG', OwnCount('REGISTER'));
        Put(Prefix + ' OTHER', OtherSessionsCount());
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

codeunit 87404 "LGN DLW Ctl A"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Probe: Codeunit "LGN DLW Probe";

    [Test]
    procedure DLW_CtlA_OwnLogin()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('login rows of this session', Format(Probe.OwnCount('LOGIN')));
        Observer.Observe('register rows of this session', Format(Probe.OwnCount('REGISTER')));
        Observer.Observe('rows of other sessions', Format(Probe.OtherSessionsCount()));
        Observer.Finish();
    end;
}

codeunit 87405 "LGN DLW Ctl B"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Probe: Codeunit "LGN DLW Probe";

    [Test]
    procedure DLW_CtlB_OwnLogin()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('login rows of this session', Format(Probe.OwnCount('LOGIN')));
        Observer.Observe('register rows of this session', Format(Probe.OwnCount('REGISTER')));
        Observer.Observe('rows of other sessions', Format(Probe.OtherSessionsCount()));
        Observer.Finish();
    end;
}

codeunit 87406 "LGN DLW G1 A"
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
    procedure DLW_G1A_OwnLogin()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('login rows of this session', Format(Probe.Get('G1A LOGIN')));
        Observer.Observe('register rows of this session', Format(Probe.Get('G1A REG')));
        Observer.Observe('rows of other sessions (Ctl A and Ctl B)', Format(Probe.Get('G1A OTHER')));
        Observer.Finish();
    end;

    [Test]
    procedure DLW_G1A_End()
    begin
        Probe.EndA('G1A');
    end;
}

codeunit 87407 "LGN DLW G1 B"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    var
        Probe: Codeunit "LGN DLW Probe";

    [Test]
    procedure DLW_G1B_Snap()
    var
        Checklist: Codeunit Checklist;
        UserLoginTimeTracker: Codeunit "User Login Time Tracker";
    begin
        Probe.PutBool('G1B A MARKS FOUND', Probe.Has('G1A MARKS'));
        Probe.PutBool('G1B SAME SESSION', SessionId() = Probe.Get('G1A S'));
        Probe.Put('G1B A LOGIN', Probe.SessionCount(Probe.Get('G1A S'), 'LOGIN'));
        Probe.Put('G1B LOGIN', Probe.OwnCount('LOGIN'));
        Probe.Put('G1B REG', Probe.OwnCount('REGISTER'));
        Probe.Put('G1B OTHERS AFTER A', Probe.OthersAfter(Probe.Get('G1A MAX')));
        Probe.Put('G1B SEEN MINUS A', Probe.OwnMarksSeen() - Probe.Get('G1A MARKS'));
        Probe.PutBool('G1B SINCE A END', UserLoginTimeTracker.UserLoggedInSinceDateTime(Probe.GetAt('G1A END')));
        Probe.PutBool('G1B CHECKLIST', Checklist.ShouldInitializeChecklist(false));
    end;

    [Test]
    procedure DLW_G1B_AfterDisabledA()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('marks of A found', Format(Probe.Get('G1B A MARKS FOUND')));
        Observer.Observe('same session as A', Format(Probe.Get('G1B SAME SESSION')));
        Observer.Observe('login rows of A session', Format(Probe.Get('G1B A LOGIN')));
        Observer.Observe('login rows of this session', Format(Probe.Get('G1B LOGIN')));
        Observer.Observe('register rows of this session', Format(Probe.Get('G1B REG')));
        Observer.Observe('rows of other sessions after A snapshot', Format(Probe.Get('G1B OTHERS AFTER A')));
        Observer.Observe('marks seen by login minus marks A left', Format(Probe.Get('G1B SEEN MINUS A')));
        Observer.Observe('user login updated after A end', Format(Probe.Get('G1B SINCE A END')));
        Observer.Observe('ShouldInitializeChecklist(false)', Format(Probe.Get('G1B CHECKLIST')));
        Observer.Finish();
    end;
}

codeunit 87408 "LGN DLW G2 A"
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
    procedure DLW_G2A_OwnLogin()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('login rows of this session', Format(Probe.Get('G2A LOGIN')));
        Observer.Observe('register rows of this session', Format(Probe.Get('G2A REG')));
        Observer.Observe('login rows of G1 B session still there', Format(Probe.OthersAfter(Probe.Get('G1A MAX'))));
        Observer.Finish();
    end;

    [Test]
    procedure DLW_G2A_End()
    begin
        Probe.EndA('G2A');
    end;
}

codeunit 87409 "LGN DLW G2 B"
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
        Observer.Observe('marks of A found', Format(Probe.Has('G2A MARKS')));
        Observer.Observe('same session as A', Format(SessionId() = Probe.Get('G2A S')));
        Observer.Observe('login rows of A session', Format(Probe.SessionCount(Probe.Get('G2A S'), 'LOGIN')));
        Observer.Observe('login rows of this session', Format(Probe.OwnCount('LOGIN')));
        Observer.Observe('register rows of this session', Format(Probe.OwnCount('REGISTER')));
        Observer.Observe('rows of other sessions after A snapshot', Format(Probe.OthersAfter(Probe.Get('G2A MAX'))));
        Observer.Observe('marks seen by login minus marks A left', Format(Probe.OwnMarksSeen() - Probe.Get('G2A MARKS')));
        Observer.Observe('user login updated after A end', Format(UserLoginTimeTracker.UserLoggedInSinceDateTime(Probe.GetAt('G2A END'))));
        Observer.Observe('ShouldInitializeChecklist(false)', Format(Checklist.ShouldInitializeChecklist(false)));
        Observer.Finish();
    end;
}

codeunit 87410 "LGN DLW G3 A"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    var
        Probe: Codeunit "LGN DLW Probe";

    [Test]
    procedure DLW_G3A_SnapAndDelete()
    begin
        Probe.Put('G3A S', SessionId());
        Probe.Put('G3A G2B ROWS', Probe.OthersAfter(Probe.Get('G2A MAX')));
        Probe.Put('G3A LOGIN', Probe.OwnCount('LOGIN'));
        Probe.DeleteOwnRows();
        Probe.Put('G3A AFTER DELETE', Probe.OwnCount(''));
    end;

    [Test]
    procedure DLW_G3A_DeletedOwnLoginRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows of G2 B session (Codeunit isolation after Disabled)', Format(Probe.Get('G3A G2B ROWS')));
        Observer.Observe('login rows of this session before delete', Format(Probe.Get('G3A LOGIN')));
        Observer.Observe('rows of this session after delete', Format(Probe.Get('G3A AFTER DELETE')));
        Observer.Observe('rows of this session in the next test', Format(Probe.OwnCount('')));
        Observer.Finish();
    end;
}

codeunit 87411 "LGN DLW G3 B"
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
        Observer.Observe('rows of A session', Format(Probe.SessionCount(Probe.Get('G3A S'), '')));
        Observer.Observe('login rows of this session', Format(Probe.OwnCount('LOGIN')));
        Observer.Observe('register rows of this session', Format(Probe.OwnCount('REGISTER')));
        Observer.Finish();
    end;
}
