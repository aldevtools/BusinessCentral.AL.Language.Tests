// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-fields
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 80000, log codeunit 80001, test codeunit 80002
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: a table's own OnInsert trigger assigns SystemId := CreateGuid() and the caller uses Insert(true) or Insert(true, true): is the new SystemId
// kept in the caller's variable and in the stored row, and does a SystemId the caller set before Insert survive. Insert(false) is the control
// (the trigger does not run). The subscriber form is in record/lt-af-record-events/AfSystemIdBeforeInsert.al.
// BC versions: 27, 28, 29

table 80000 "LT AT Sys Trig"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Note; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    var
        Log: Codeunit "LT AT Sys Log";
    begin
        if not Log.IsArmed() then
            exit;
        Log.Before(SystemId);
        SystemId := CreateGuid();
        Log.Assigned(SystemId);
    end;
}

codeunit 80001 "LT AT Sys Log"
{
    SingleInstance = true;

    var
        Armed: Boolean;
        Seen: Guid;
        Given: Guid;

    procedure Arm()
    var
        NullId: Guid;
    begin
        Armed := true;
        Seen := NullId;
        Given := NullId;
    end;

    procedure Disarm()
    begin
        Armed := false;
    end;

    procedure IsArmed(): Boolean
    begin
        exit(Armed);
    end;

    procedure Before(Id: Guid)
    begin
        Seen := Id;
    end;

    procedure Assigned(Id: Guid)
    begin
        Given := Id;
    end;

    procedure SeenId(): Guid
    begin
        exit(Seen);
    end;

    procedure GivenId(): Guid
    begin
        exit(Given);
    end;
}

codeunit 80002 "LT AT SystemId OnInsert"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT AT Sys Log";

    // Mode 0: Insert(true); 1: Insert(true) after the caller set SystemId; 2: Insert(true, true) after the caller set SystemId;
    // 3: Insert(false) (control: the trigger does not run).
    local procedure Run(var Observer: Codeunit "Probe Observer"; Mode: Integer)
    var
        Row: Record "LT AT Sys Trig";
        Stored: Record "LT AT Sys Trig";
        BySysId: Record "LT AT Sys Trig";
        Preset: Guid;
        Before: Guid;
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Log.Arm();
        Row.Id := 1;
        Row.Note := 'n';
        if Mode in [1, 2] then begin
            Preset := CreateGuid();
            Row.SystemId := Preset;
        end;
        Before := Row.SystemId;
        case Mode of
            0, 1:
                Ok := Row.Insert(true);
            2:
                Ok := Row.Insert(true, true);
            3:
                Ok := Row.Insert(false);
        end;
        Log.Disarm();
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('trigger saw null', Format(IsNullGuid(Log.SeenId())));
        Observer.Observe('trigger saw preset', Format((not IsNullGuid(Preset)) and (Log.SeenId() = Preset)));
        Observer.Observe('trigger ran', Format(not IsNullGuid(Log.GivenId())));
        Observer.Observe('caller = trigger', Format(Row.SystemId = Log.GivenId()));
        Observer.Observe('caller = preset', Format((not IsNullGuid(Preset)) and (Row.SystemId = Preset)));
        Observer.Observe('caller null', Format(IsNullGuid(Row.SystemId)));
        Observer.Observe('caller changed', Format(Row.SystemId <> Before));
        Stored.Get(1);
        Observer.Observe('stored = trigger', Format(Stored.SystemId = Log.GivenId()));
        Observer.Observe('stored = caller', Format(Stored.SystemId = Row.SystemId));
        Observer.Observe('GetBySystemId(caller)', Format(BySysId.GetBySystemId(Row.SystemId)));
    end;

    [Test]
    procedure AT_SystemId_OnInsert_InsertTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 0);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('trigger saw null', 'No');
        Observer.Expect('trigger saw preset', 'No');
        Observer.Expect('trigger ran', 'Yes');
        Observer.Expect('caller = trigger', 'Yes');
        Observer.Expect('caller = preset', 'No');
        Observer.Expect('caller null', 'No');
        Observer.Expect('caller changed', 'Yes');
        Observer.Expect('stored = trigger', 'Yes');
        Observer.Expect('stored = caller', 'Yes');
        Observer.Expect('GetBySystemId(caller)', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AT_SystemId_OnInsert_Preset_InsertTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('trigger saw null', 'No');
        Observer.Expect('trigger saw preset', 'No');
        Observer.Expect('trigger ran', 'Yes');
        Observer.Expect('caller = trigger', 'Yes');
        Observer.Expect('caller = preset', 'No');
        Observer.Expect('caller null', 'No');
        Observer.Expect('caller changed', 'Yes');
        Observer.Expect('stored = trigger', 'Yes');
        Observer.Expect('stored = caller', 'Yes');
        Observer.Expect('GetBySystemId(caller)', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AT_SystemId_OnInsert_Preset_InsertTrueTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('trigger saw null', 'No');
        Observer.Expect('trigger saw preset', 'Yes');
        Observer.Expect('trigger ran', 'Yes');
        Observer.Expect('caller = trigger', 'Yes');
        Observer.Expect('caller = preset', 'No');
        Observer.Expect('caller null', 'No');
        Observer.Expect('caller changed', 'Yes');
        Observer.Expect('stored = trigger', 'Yes');
        Observer.Expect('stored = caller', 'Yes');
        Observer.Expect('GetBySystemId(caller)', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AT_SystemId_OnInsert_InsertFalse_Control()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('trigger saw null', 'Yes');
        Observer.Expect('trigger saw preset', 'No');
        Observer.Expect('trigger ran', 'No');
        Observer.Expect('caller = trigger', 'No');
        Observer.Expect('caller = preset', 'No');
        Observer.Expect('caller null', 'No');
        Observer.Expect('caller changed', 'Yes');
        Observer.Expect('stored = trigger', 'No');
        Observer.Expect('stored = caller', 'Yes');
        Observer.Expect('GetBySystemId(caller)', 'Yes');
        Observer.Verify();
    end;
}
