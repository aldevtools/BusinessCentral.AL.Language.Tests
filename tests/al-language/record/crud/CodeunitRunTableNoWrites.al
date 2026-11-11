// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 76710..76717
// local object: the TableNo codeunits must write, commit and fail on demand
// Probe (al-runner issue 7795): Codeunit.Run of a TableNo codeunit with a record variable, where the codeunit modifies Rec (and commits,
//   and raises an error), and then the caller writes through the same variable (directly, or through a second TableNo codeunit as an
//   error handler does). Read: what the caller's variable holds after the run (did the codeunit's Modify reach it), the answer of the
//   guarded run, whether the caller's later Modify is written or raises (text and code), and the stored row.
//   Cells: the codeunit does Modify+Commit+Error, Modify+Error, Modify+Commit, Modify; the run guarded (`if Codeunit.Run`) and not
//   (inside asserterror).
// Second part: a buffer made stale by its own write (Insert or Modify, then another variable's Modify and a Commit), then in the
//   open transaction a read under ReadIsolation of ANOTHER row of the table (no contact with the buffer's row), then the buffer's
//   Modify. ReadIsolation UpdLock, RepeatableRead, ReadCommitted and ReadUncommitted; through Get and through FindSet.
// BC versions: 27, 28, 29

table 76710 "CRT Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Status; Option) { OptionMembers = New,Running,Failed; }
        field(3; Attempts; Integer) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 76717 "CRT Side"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

codeunit 76711 "CRT Cfg"
{
    SingleInstance = true;

    var
        Mode: Text;

    procedure Set(NewMode: Text)
    begin
        Mode := NewMode;
    end;

    procedure Get(): Text
    begin
        exit(Mode);
    end;
}

codeunit 76712 "CRT Runner"
{
    TableNo = "CRT Row";

    trigger OnRun()
    var
        Cfg: Codeunit "CRT Cfg";
    begin
        Rec.Status := Rec.Status::Running;
        Rec.Attempts := 3;
        Rec.Modify();
        if (Cfg.Get() = 'mce') or (Cfg.Get() = 'mc') then
            Commit();
        if (Cfg.Get() = 'mce') or (Cfg.Get() = 'me') then
            Error('the work failed');
    end;
}

codeunit 76713 "CRT Handler"
{
    TableNo = "CRT Row";

    trigger OnRun()
    begin
        Rec.Status := Rec.Status::Failed;
        Rec.Attempts -= 1;
        Rec.Modify();
    end;
}

codeunit 76714 "CRT Codeunit Run Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Cfg: Codeunit "CRT Cfg";

    local procedure Seed(var Row: Record "CRT Row"; Mode: Text)
    var
        Old: Record "CRT Row";
    begin
        Old.DeleteAll();
        Old.Init();
        Old."No." := 'B';
        Old.Insert();
        Row.Init();
        Row."No." := 'A';
        Row.Insert();
        Commit();
        Row.Get('A');
        Row.Status := Row.Status::Running;
        Row.Modify();
        Commit();
        Cfg.Set(Mode);
    end;

    local procedure Buf(Row: Record "CRT Row"): Text
    begin
        exit(Format(Row.Status) + '/' + Format(Row.Attempts));
    end;

    local procedure Stored(): Text
    var
        Check: Record "CRT Row";
    begin
        if not Check.Get('A') then
            exit('gone');
        exit(Buf(Check));
    end;

    local procedure CleanUp()
    var
        Old: Record "CRT Row";
    begin
        Old.DeleteAll();
        Commit();
        Cfg.Set('');
    end;

    // The guarded run, then the handler codeunit on the same variable (the report, for Mode mce).
    local procedure GuardedThenHandler(var Observer: Codeunit "Probe Observer"; Mode: Text)
    var
        Row: Record "CRT Row";
    begin
        Seed(Row, Mode);
        Observer.Observe('run answer', Format(Codeunit.Run(Codeunit::"CRT Runner", Row)));
        Observer.Observe('buffer after run', Buf(Row));
        Observer.Observe('stored after run', Stored());
        asserterror begin
            Codeunit.Run(Codeunit::"CRT Handler", Row);
            Observer.Observe('stored after handler', Stored());
            Observer.Observe('buffer after handler', Buf(Row));
            Error('CRT_NO_ERROR');
        end;
        Observer.ObserveError('handler');
        CleanUp();
        Observer.Finish();
    end;

    // The guarded run, then the caller's own Modify through the same variable.
    local procedure GuardedThenModify(var Observer: Codeunit "Probe Observer"; Mode: Text)
    var
        Row: Record "CRT Row";
    begin
        Seed(Row, Mode);
        Observer.Observe('run answer', Format(Codeunit.Run(Codeunit::"CRT Runner", Row)));
        Observer.Observe('buffer after run', Buf(Row));
        asserterror begin
            Row.Attempts += 10;
            Row.Modify();
            Observer.Observe('stored after modify', Stored());
            Error('CRT_NO_ERROR');
        end;
        Observer.ObserveError('modify');
        CleanUp();
        Observer.Finish();
    end;

    // The run without a return value, inside asserterror, then the handler codeunit on the same variable.
    local procedure UnguardedThenHandler(var Observer: Codeunit "Probe Observer"; Mode: Text)
    var
        Row: Record "CRT Row";
    begin
        Seed(Row, Mode);
        asserterror begin
            Codeunit.Run(Codeunit::"CRT Runner", Row);
            Error('CRT_NO_ERROR');
        end;
        Observer.ObserveError('run');
        Observer.Observe('buffer after run', Buf(Row));
        Observer.Observe('stored after run', Stored());
        asserterror begin
            Codeunit.Run(Codeunit::"CRT Handler", Row);
            Observer.Observe('stored after handler', Stored());
            Error('CRT_NO_ERROR');
        end;
        Observer.ObserveError('handler');
        CleanUp();
        Observer.Finish();
    end;

    [Test]
    procedure Guarded_ModifyCommitError_ThenHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GuardedThenHandler(Observer, 'mce');
    end;

    [Test]
    procedure Guarded_ModifyError_ThenHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GuardedThenHandler(Observer, 'me');
    end;

    [Test]
    procedure Guarded_ModifyCommit_ThenHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GuardedThenHandler(Observer, 'mc');
    end;

    [Test]
    procedure Guarded_Modify_ThenHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GuardedThenHandler(Observer, 'm');
    end;

    [Test]
    procedure Guarded_ModifyCommitError_ThenModify()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GuardedThenModify(Observer, 'mce');
    end;

    [Test]
    procedure Guarded_ModifyError_ThenModify()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GuardedThenModify(Observer, 'me');
    end;

    [Test]
    procedure Guarded_ModifyCommit_ThenModify()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GuardedThenModify(Observer, 'mc');
    end;

    [Test]
    procedure Unguarded_ModifyCommitError_ThenHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UnguardedThenHandler(Observer, 'mce');
    end;

    [Test]
    procedure Unguarded_ModifyError_ThenHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UnguardedThenHandler(Observer, 'me');
    end;

    [Test]
    procedure Unguarded_ModifyCommit_ThenHandler()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CRT Row";
    begin
        Seed(Row, 'mc');
        Codeunit.Run(Codeunit::"CRT Runner", Row);
        Observer.Observe('buffer after run', Buf(Row));
        Observer.Observe('stored after run', Stored());
        asserterror begin
            Codeunit.Run(Codeunit::"CRT Handler", Row);
            Observer.Observe('stored after handler', Stored());
            Error('CRT_NO_ERROR');
        end;
        Observer.ObserveError('handler');
        CleanUp();
        Observer.Finish();
    end;
}

codeunit 76715 "CRT Stale ReadIsolation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Row A written by the buffer itself (OwnWrite: 'insert' or 'modify'), then by another variable, and committed: the buffer is stale.
    local procedure MakeStale(var Row: Record "CRT Row"; OwnWrite: Text)
    var
        Old: Record "CRT Row";
        Other: Record "CRT Row";
    begin
        Old.DeleteAll();
        Old.Init();
        Old."No." := 'B';
        Old.Insert();
        Commit();
        Row.Init();
        Row."No." := 'A';
        if OwnWrite = 'insert' then
            Row.Insert()
        else begin
            Old.Init();
            Old."No." := 'A';
            Old.Insert();
            Commit();
            Row.Get('A');
            Row.Attempts := 1;
            Row.Modify();
        end;
        Commit();
        Other.Get('A');
        Other.Attempts := 5;
        Other.Modify();
        Commit();
    end;

    local procedure ReadOther(Level: Text; Method: Text)
    var
        Reader: Record "CRT Row";
    begin
        if Level = 'none' then
            exit;
        case Level of
            'updlock':
                Reader.ReadIsolation := IsolationLevel::UpdLock;
            'repeatableread':
                Reader.ReadIsolation := IsolationLevel::RepeatableRead;
            'readcommitted':
                Reader.ReadIsolation := IsolationLevel::ReadCommitted;
            'readuncommitted':
                Reader.ReadIsolation := IsolationLevel::ReadUncommitted;
        end;
        if Method = 'get' then
            Reader.Get('B')
        else begin
            Reader.SetRange("No.", 'B');
            Reader.FindSet();
        end;
    end;

    local procedure Cell(var Observer: Codeunit "Probe Observer"; OwnWrite: Text; Level: Text; Method: Text)
    var
        Row: Record "CRT Row";
        Check: Record "CRT Row";
        Old: Record "CRT Row";
    begin
        MakeStale(Row, OwnWrite);
        ReadOther(Level, Method);
        asserterror begin
            Row.Status := Row.Status::Failed;
            Row.Modify();
            Check.Get('A');
            Observer.Observe('stored after modify', Format(Check.Status) + '/' + Format(Check.Attempts));
            Error('CRT_NO_ERROR');
        end;
        Observer.ObserveError('modify');
        Old.DeleteAll();
        Commit();
        Observer.Finish();
    end;

    [Test]
    procedure OwnModify_UpdLock_GetOtherRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'modify', 'updlock', 'get');
    end;

    [Test]
    procedure OwnModify_UpdLock_FindSetOtherRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'modify', 'updlock', 'findset');
    end;

    [Test]
    procedure OwnModify_RepeatableRead_GetOtherRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'modify', 'repeatableread', 'get');
    end;

    [Test]
    procedure OwnModify_ReadCommitted_GetOtherRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'modify', 'readcommitted', 'get');
    end;

    [Test]
    procedure OwnModify_ReadUncommitted_GetOtherRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'modify', 'readuncommitted', 'get');
    end;

    [Test]
    procedure OwnModify_NoRead()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'modify', 'none', 'none');
    end;

    [Test]
    procedure OwnInsert_UpdLock_GetOtherRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'insert', 'updlock', 'get');
    end;

    [Test]
    procedure OwnInsert_UpdLock_FindSetOtherRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'insert', 'updlock', 'findset');
    end;

    [Test]
    procedure OwnInsert_RepeatableRead_GetOtherRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 'insert', 'repeatableread', 'get');
    end;
}

// Third part: a buffer A that inserted its row and wrote it with Modify(true); a partial record B (SetLoadFields) writes the same row; a
// Commit; then the open transaction inserts and modifies ANOTHER row of the table, and reads under ReadIsolation (A's row, another row,
// or nothing); then A's Modify(true). Cells with and without B's write, with and without the other row, and each read.
codeunit 76716 "CRT Stale Other Row Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Cell(var Observer: Codeunit "Probe Observer"; WithB: Boolean; WithOtherRow: Boolean; ReadMode: Text)
    var
        A: Record "CRT Row";
        B: Record "CRT Row";
        C: Record "CRT Row";
        R: Record "CRT Row";
        Check: Record "CRT Row";
        Old: Record "CRT Row";
        Side: Record "CRT Side";
    begin
        Old.DeleteAll();
        Old.Init();
        Old."No." := 'B';
        Old.Insert();
        Side.DeleteAll();
        Side."No." := 'S';
        Side.Insert();
        Commit();
        A.Init();
        A."No." := 'A';
        A.Insert(true);
        A.Attempts := 1;
        A.Modify(true);
        if WithB then begin
            B.SetLoadFields(Status);
            B.Get('A');
            B.Status := B.Status::Failed;
            B.Modify();
        end;
        Commit();
        if WithOtherRow then begin
            C.Init();
            C."No." := 'C';
            C.Insert(true);
            C.Attempts := 9;
            C.Modify(true);
        end;
        case ReadMode of
            'updlock-own':
                begin
                    R.ReadIsolation := IsolationLevel::UpdLock;
                    R.Get('A');
                end;
            'updlock-other':
                begin
                    R.ReadIsolation := IsolationLevel::UpdLock;
                    R.Get('B');
                end;
            'updlock-othertable':
                begin
                    Side.ReadIsolation := IsolationLevel::UpdLock;
                    if Side.FindFirst() then;
                end;
            'repeatableread-own':
                begin
                    R.ReadIsolation := IsolationLevel::RepeatableRead;
                    R.Get('A');
                end;
        end;
        Observer.Observe('buffer before', Format(A.Status) + '/' + Format(A.Attempts));
        asserterror begin
            A.Attempts := 2;
            A.Modify(true);
            Check.Get('A');
            Observer.Observe('stored after modify', Format(Check.Status) + '/' + Format(Check.Attempts));
            Error('CRT_NO_ERROR');
        end;
        Observer.ObserveError('modify');
        Old.DeleteAll();
        Side.DeleteAll();
        Commit();
        Observer.Finish();
    end;

    [Test]
    procedure PartialWrite_OtherRow_UpdLockOtherTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, true, true, 'updlock-othertable');
    end;

    [Test]
    procedure PartialWrite_NoOtherRow_UpdLockOtherTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, true, false, 'updlock-othertable');
    end;

    [Test]
    procedure PartialWrite_OtherRow_UpdLockOwnRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, true, true, 'updlock-own');
    end;

    [Test]
    procedure PartialWrite_OtherRow_NoRead()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, true, true, 'none');
    end;

    [Test]
    procedure PartialWrite_NoOtherRow_UpdLockOwnRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, true, false, 'updlock-own');
    end;

    [Test]
    procedure PartialWrite_OtherRow_UpdLockOtherRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, true, true, 'updlock-other');
    end;

    [Test]
    procedure PartialWrite_NoOtherRow_UpdLockOtherRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, true, false, 'updlock-other');
    end;

    [Test]
    procedure NoPartialWrite_OtherRow_UpdLockOwnRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, false, true, 'updlock-own');
    end;

    [Test]
    procedure PartialWrite_OtherRow_RepeatableReadOwnRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, true, true, 'repeatableread-own');
    end;
}
