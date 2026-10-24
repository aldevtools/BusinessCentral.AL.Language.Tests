// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-fields
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in QrSystemIdObjects.al (87285 - 87288)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: a SystemId set during Insert by a table extension's OnBeforeInsert, OnInsert or OnAfterInsert trigger, by an OnAfterInsertEvent
//   subscriber, by the table's OnInsert or an OnBeforeInsertEvent subscriber to the SystemId of a row that already exists, by a table
//   extension trigger on a temporary record and through RecordRef.Insert: is it kept in the caller's variable and in the stored row,
//   without InsertWithSystemId. Already pinned elsewhere: the table's own OnInsert (record/lt-at-partner-gaps/AtSystemIdOnInsert.al) and
//   an OnBeforeInsertEvent subscriber with a new id (record/lt-af-record-events/AfSystemIdBeforeInsert.al).
//   BC (27.5, 28.5, 29.0 alike): an id set by the table extension's OnBeforeInsert or OnInsert (Insert(true), RecordRef.Insert(true), a
//   temporary record) is kept in the variable and the stored row; one set in OnAfterInsert or an OnAfterInsertEvent subscriber changes only
//   the variable (the stored row keeps the platform's id). An id that another row already has makes Insert answer false (no row, no error);
//   as a statement Insert raises 'There is already a record in table <table> that has the same values in a unique index for the following
//   fields: System ID=<id>' / DB:RecordExists.
// BC versions: 27, 28, 29

codeunit 87289 "LT QR SystemId Events"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        State: Codeunit "LT QR Sys State";

    local procedure Run(var Observer: Codeunit "Probe Observer"; Name: Text; Mode: Integer; RunTrigger: Boolean)
    var
        Row: Record "LT QR Sys Row";
        Stored: Record "LT QR Sys Row";
        Wanted: Guid;
        Empty: Guid;
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Wanted := CreateGuid();
        State.Arm(Mode, Wanted);
        Row.Init();
        Row.Id := 1;
        Row.Note := 'n';
        Ok := Row.Insert(RunTrigger);
        State.Arm(0, Empty);
        Observer.Observe(Name + '|insert', Format(Ok));
        Observer.Observe(Name + '|caller keeps', Format(Row.SystemId = Wanted));
        Observer.Observe(Name + '|caller null', Format(IsNullGuid(Row.SystemId)));
        Observer.Observe(Name + '|stored', Format(Stored.Get(1)));
        Observer.Observe(Name + '|stored keeps', Format(Stored.SystemId = Wanted));
        Observer.Observe(Name + '|stored = caller', Format(Stored.SystemId = Row.SystemId));
        Clear(Stored);
        Observer.Observe(Name + '|GetBySystemId(wanted)', Format(Stored.GetBySystemId(Wanted)));
    end;

    [Test]
    procedure QR_TableExt_OnBeforeInsert()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'ext before', 1, true);
        Observer.Expect('ext before|insert', 'Yes');
        Observer.Expect('ext before|caller keeps', 'Yes');
        Observer.Expect('ext before|caller null', 'No');
        Observer.Expect('ext before|stored', 'Yes');
        Observer.Expect('ext before|stored keeps', 'Yes');
        Observer.Expect('ext before|stored = caller', 'Yes');
        Observer.Expect('ext before|GetBySystemId(wanted)', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TableExt_OnInsert()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'ext oninsert', 2, true);
        Observer.Expect('ext oninsert|insert', 'Yes');
        Observer.Expect('ext oninsert|caller keeps', 'Yes');
        Observer.Expect('ext oninsert|caller null', 'No');
        Observer.Expect('ext oninsert|stored', 'Yes');
        Observer.Expect('ext oninsert|stored keeps', 'Yes');
        Observer.Expect('ext oninsert|stored = caller', 'Yes');
        Observer.Expect('ext oninsert|GetBySystemId(wanted)', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TableExt_OnAfterInsert()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'ext after', 3, true);
        Observer.Expect('ext after|insert', 'Yes');
        Observer.Expect('ext after|caller keeps', 'Yes');
        Observer.Expect('ext after|caller null', 'No');
        Observer.Expect('ext after|stored', 'Yes');
        Observer.Expect('ext after|stored keeps', 'No');
        Observer.Expect('ext after|stored = caller', 'No');
        Observer.Expect('ext after|GetBySystemId(wanted)', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TableExt_Triggers_InsertFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'ext before false', 1, false);
        Observer.Expect('ext before false|insert', 'Yes');
        Observer.Expect('ext before false|caller keeps', 'No');
        Observer.Expect('ext before false|caller null', 'No');
        Observer.Expect('ext before false|stored', 'Yes');
        Observer.Expect('ext before false|stored keeps', 'No');
        Observer.Expect('ext before false|stored = caller', 'Yes');
        Observer.Expect('ext before false|GetBySystemId(wanted)', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Subscriber_OnAfterInsertEvent()
    var
        Observer: Codeunit "Probe Observer";
        Subscriber: Codeunit "LT QR Sys Subscriber";
    begin
        BindSubscription(Subscriber);
        Run(Observer, 'sub after', 4, false);
        Run(Observer, 'sub after true', 4, true);
        UnbindSubscription(Subscriber);
        Observer.Expect('sub after|insert', 'Yes');
        Observer.Expect('sub after|caller keeps', 'Yes');
        Observer.Expect('sub after|caller null', 'No');
        Observer.Expect('sub after|stored', 'Yes');
        Observer.Expect('sub after|stored keeps', 'No');
        Observer.Expect('sub after|stored = caller', 'No');
        Observer.Expect('sub after|GetBySystemId(wanted)', 'No');
        Observer.Expect('sub after true|insert', 'Yes');
        Observer.Expect('sub after true|caller keeps', 'Yes');
        Observer.Expect('sub after true|caller null', 'No');
        Observer.Expect('sub after true|stored', 'Yes');
        Observer.Expect('sub after true|stored keeps', 'No');
        Observer.Expect('sub after true|stored = caller', 'No');
        Observer.Expect('sub after true|GetBySystemId(wanted)', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QR_RecordRef_Insert_TableExtOnBeforeInsert()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QR Sys Row";
        RecRef: RecordRef;
        IdRef: FieldRef;
        Wanted: Guid;
        Empty: Guid;
    begin
        Row.DeleteAll();
        Wanted := CreateGuid();
        State.Arm(1, Wanted);
        RecRef.Open(Database::"LT QR Sys Row");
        RecRef.Init();
        IdRef := RecRef.Field(1);
        IdRef.Value := 1;
        Observer.Observe('insert', Format(RecRef.Insert(true)));
        State.Arm(0, Empty);
        IdRef := RecRef.Field(RecRef.SystemIdNo());
        Observer.Observe('recref keeps', Format(Format(IdRef.Value) = Format(Wanted)));
        Observer.Observe('stored keeps', Format(Row.GetBySystemId(Wanted)));
        RecRef.Close();
        Observer.Expect('insert', 'Yes');
        Observer.Expect('recref keeps', 'Yes');
        Observer.Expect('stored keeps', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Temporary_TableExtOnInsert()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "LT QR Sys Row" temporary;
        Wanted: Guid;
        Empty: Guid;
    begin
        Wanted := CreateGuid();
        State.Arm(2, Wanted);
        Temp.Init();
        Temp.Id := 1;
        Observer.Observe('insert', Format(Temp.Insert(true)));
        State.Arm(0, Empty);
        Observer.Observe('caller keeps', Format(Temp.SystemId = Wanted));
        Observer.Observe('caller null', Format(IsNullGuid(Temp.SystemId)));
        Temp.Get(1);
        Observer.Observe('get keeps', Format(Temp.SystemId = Wanted));
        Observer.Observe('get null', Format(IsNullGuid(Temp.SystemId)));
        Observer.Expect('insert', 'Yes');
        Observer.Expect('caller keeps', 'Yes');
        Observer.Expect('caller null', 'No');
        Observer.Expect('get keeps', 'Yes');
        Observer.Expect('get null', 'No');
        Observer.Verify();
    end;

    // Inserts row 2 while the trigger or subscriber gives it the SystemId of row 1, reads the table back (so a pending insert is sent),
    // and then always raises: either the platform's error or the text 'done: ...' with what the reads found.
    local procedure InsertDuplicate(RunTrigger: Boolean; FirstId: Guid)
    var
        Row: Record "LT QR Sys Row";
        ById: Record "LT QR Sys Row";
        Ok: Boolean;
        Found: Boolean;
    begin
        Row.Init();
        Row.Id := 2;
        Ok := Row.Insert(RunTrigger);
        Row.Reset();
        Found := ById.GetBySystemId(FirstId);
        Error('done: insert %1, caller has first id %2, rows %3, GetBySystemId finds %4 id %5', Ok, Row.SystemId = FirstId, Row.Count(), Found, ById.Id);
    end;

    [Test]
    procedure QR_OnInsert_DuplicateOfExistingRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QR Sys Row";
        First: Record "LT QR Sys Row";
        Empty: Guid;
    begin
        Row.DeleteAll();
        First.Init();
        First.Id := 1;
        First.Insert();
        State.Arm(5, First.SystemId);
        asserterror InsertDuplicate(true, First.SystemId);
        State.Arm(0, Empty);
        Observer.ObserveError('duplicate');
        Observer.Expect('duplicate|text', 'done: insert No, caller has first id No, rows 1, GetBySystemId finds Yes id 1');
        Observer.Expect('duplicate|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Subscriber_OnBeforeInsert_DuplicateOfExistingRow()
    var
        Observer: Codeunit "Probe Observer";
        Subscriber: Codeunit "LT QR Sys Subscriber";
        Row: Record "LT QR Sys Row";
        First: Record "LT QR Sys Row";
        Empty: Guid;
    begin
        Row.DeleteAll();
        First.Init();
        First.Id := 1;
        First.Insert();
        BindSubscription(Subscriber);
        State.Arm(6, First.SystemId);
        asserterror InsertDuplicate(false, First.SystemId);
        State.Arm(0, Empty);
        UnbindSubscription(Subscriber);
        Observer.ObserveError('duplicate');
        Observer.Expect('duplicate|text', 'done: insert No, caller has first id No, rows 1, GetBySystemId finds Yes id 1');
        Observer.Expect('duplicate|code', 'Dialog');
        Observer.Verify();
    end;

    // The statement form: Insert without a return value, then the same reads.
    local procedure InsertDuplicateStatement(RunTrigger: Boolean; FirstId: Guid)
    var
        Row: Record "LT QR Sys Row";
        ById: Record "LT QR Sys Row";
        Found: Boolean;
    begin
        Row.Init();
        Row.Id := 2;
        Row.Insert(RunTrigger);
        Row.Reset();
        Found := ById.GetBySystemId(FirstId);
        Error('done: caller has first id %1, rows %2, GetBySystemId finds %3 id %4', Row.SystemId = FirstId, Row.Count(), Found, ById.Id);
    end;

    [Test]
    procedure QR_OnInsert_DuplicateOfExistingRow_Statement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QR Sys Row";
        First: Record "LT QR Sys Row";
        Empty: Guid;
    begin
        Row.DeleteAll();
        First.Init();
        First.Id := 1;
        First.Insert();
        State.Arm(5, First.SystemId);
        asserterror InsertDuplicateStatement(true, First.SystemId);
        State.Arm(0, Empty);
        // The error names the duplicate id; it differs per run, so the text is asserted with that id written as {first id}.
        Observer.Expect('duplicate|text', 'There is already a record in table LT QR Sys Row that has the same values in a unique index for the following fields: System ID=''{first id}''');
        Observer.Expect('duplicate|code', 'DB:RecordExists');
        Observer.Observe('duplicate|text', GetLastErrorText().Replace(Format(First.SystemId), '{first id}'));
        Observer.Observe('duplicate|code', GetLastErrorCode());
        Observer.Verify();
    end;

    [Test]
    procedure QR_Subscriber_OnBeforeInsert_DuplicateOfExistingRow_Statement()
    var
        Observer: Codeunit "Probe Observer";
        Subscriber: Codeunit "LT QR Sys Subscriber";
        Row: Record "LT QR Sys Row";
        First: Record "LT QR Sys Row";
        Empty: Guid;
    begin
        Row.DeleteAll();
        First.Init();
        First.Id := 1;
        First.Insert();
        BindSubscription(Subscriber);
        State.Arm(6, First.SystemId);
        asserterror InsertDuplicateStatement(false, First.SystemId);
        State.Arm(0, Empty);
        UnbindSubscription(Subscriber);
        // The error names the duplicate id; it differs per run, so the text is asserted with that id written as {first id}.
        Observer.Expect('duplicate|text', 'There is already a record in table LT QR Sys Row that has the same values in a unique index for the following fields: System ID=''{first id}''');
        Observer.Expect('duplicate|code', 'DB:RecordExists');
        Observer.Observe('duplicate|text', GetLastErrorText().Replace(Format(First.SystemId), '{first id}'));
        Observer.Observe('duplicate|code', GetLastErrorCode());
        Observer.Verify();
    end;


    // ---- AL Runner issue 5803 (writer RU): Init() or Clear(SystemId) during Insert clears the SystemId the platform gave the row. Objects in
    // RuSystemIdInitObjects.al. Mode 1: the table's OnInsert calls Init(); 2: OnInsert calls Clear(SystemId); 3: an OnBeforeInsertEvent
    // subscriber calls Rec.Init(); 4: an OnAfterInsertEvent subscriber calls Rec.Init(). The caller sets Note := 'caller' before Insert.

    local procedure RuRun(var Observer: Codeunit "Probe Observer"; Name: Text; Mode: Integer; RunTrigger: Boolean; WithSystemId: Boolean)
    var
        Row: Record "LT RU Init Row";
        Stored: Record "LT RU Init Row";
        RuState: Codeunit "LT RU Init State";
        Subscriber: Codeunit "LT RU Init Subscriber";
        Preset: Guid;
        Ok: Boolean;
    begin
        Row.DeleteAll();
        RuState.Arm(Mode);
        BindSubscription(Subscriber);
        Row.Init();
        Row.Id := 1;
        Row.Note := 'caller';
        if WithSystemId then begin
            Preset := CreateGuid();
            Row.SystemId := Preset;
            Ok := Row.Insert(RunTrigger, true);
        end else
            Ok := Row.Insert(RunTrigger);
        UnbindSubscription(Subscriber);
        RuState.Arm(0);
        Observer.Observe(Name + '|insert', Format(Ok));
        RuObserveTrigger(Observer, Name, Preset, WithSystemId);
        Observer.Observe(Name + '|caller null', Format(IsNullGuid(Row.SystemId)));
        Observer.Observe(Name + '|caller note', Row.Note);
        if WithSystemId then
            Observer.Observe(Name + '|caller = preset', Format(Row.SystemId = Preset));
        Observer.Observe(Name + '|stored', Format(Stored.Get(1)));
        Observer.Observe(Name + '|stored null', Format(IsNullGuid(Stored.SystemId)));
        Observer.Observe(Name + '|stored = caller', Format(Stored.SystemId = Row.SystemId));
        Observer.Observe(Name + '|stored note', Stored.Note);
        if WithSystemId then
            Observer.Observe(Name + '|stored = preset', Format(Stored.SystemId = Preset));
        Observer.Observe(Name + '|stored = id before', Format(Stored.SystemId = RuStateIdBefore()));
        Observer.Observe(Name + '|caller = id before', Format(Row.SystemId = RuStateIdBefore()));
    end;

    local procedure RuObserveTrigger(var Observer: Codeunit "Probe Observer"; Name: Text; Preset: Guid; WithSystemId: Boolean)
    var
        RuState: Codeunit "LT RU Init State";
    begin
        Observer.Observe(Name + '|id before null', Format(IsNullGuid(RuState.GetIdBefore())));
        Observer.Observe(Name + '|id after null', Format(IsNullGuid(RuState.GetIdAfter())));
        Observer.Observe(Name + '|note before', RuState.GetNoteBefore());
        Observer.Observe(Name + '|note after', RuState.GetNoteAfter());
        if WithSystemId then
            Observer.Observe(Name + '|id before = preset', Format(RuState.GetIdBefore() = Preset));
    end;

    local procedure RuStateIdBefore(): Guid
    var
        RuState: Codeunit "LT RU Init State";
    begin
        exit(RuState.GetIdBefore());
    end;

    [Test]
    procedure RU_OnInsert_Init_InsertTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RuRun(Observer, 'init', 1, true, false);
        Observer.Finish();
    end;

    [Test]
    procedure RU_OnInsert_Init_InsertTrueWithSystemId()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RuRun(Observer, 'init with id', 1, true, true);
        Observer.Finish();
    end;

    [Test]
    procedure RU_OnInsert_ClearSystemId_InsertTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RuRun(Observer, 'clear', 2, true, false);
        Observer.Finish();
    end;

    [Test]
    procedure RU_OnInsert_ClearSystemId_InsertTrueWithSystemId()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RuRun(Observer, 'clear with id', 2, true, true);
        Observer.Finish();
    end;

    [Test]
    procedure RU_OnBeforeInsertEvent_Init_InsertTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RuRun(Observer, 'ev before', 3, true, false);
        Observer.Finish();
    end;

    [Test]
    procedure RU_OnBeforeInsertEvent_Init_InsertFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RuRun(Observer, 'ev before false', 3, false, false);
        Observer.Finish();
    end;

    [Test]
    procedure RU_OnAfterInsertEvent_Init_InsertTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RuRun(Observer, 'ev after', 4, true, false);
        Observer.Finish();
    end;

    [Test]
    procedure RU_OnInsert_Init_Temporary_InsertTrue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RU Init Row" temporary;
        Stored: Record "LT RU Init Row" temporary;
        RuState: Codeunit "LT RU Init State";
        Ok: Boolean;
    begin
        RuState.Arm(1);
        Row.Init();
        Row.Id := 1;
        Row.Note := 'caller';
        Ok := Row.Insert(true);
        RuState.Arm(0);
        Observer.Observe('temp|insert', Format(Ok));
        Observer.Observe('temp|id before null', Format(IsNullGuid(RuState.GetIdBefore())));
        Observer.Observe('temp|id after null', Format(IsNullGuid(RuState.GetIdAfter())));
        Observer.Observe('temp|caller null', Format(IsNullGuid(Row.SystemId)));
        Observer.Observe('temp|caller = id before', Format(Row.SystemId = RuState.GetIdBefore()));
        Observer.Observe('temp|caller note', Row.Note);
        Stored.Copy(Row, true);
        Observer.Observe('temp|stored', Format(Stored.Get(1)));
        Observer.Observe('temp|stored null', Format(IsNullGuid(Stored.SystemId)));
        Observer.Observe('temp|stored = caller', Format(Stored.SystemId = Row.SystemId));
        Observer.Observe('temp|stored note', Stored.Note);
        Observer.Finish();
    end;
}
