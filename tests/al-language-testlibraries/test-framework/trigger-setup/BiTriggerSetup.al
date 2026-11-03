// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-triggers-and-events
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 81570 - 81573, log 81575, subscriber 81576, test codeunit 81577
// The database trigger setup with Tests-TestLibraries installed, as in a Windows container made with BcContainerHelper.
// Tests-TestLibraries codeunit 130011 "Backup Management" subscribes to Base Application's GlobalTriggerManagement
// .OnAfterGetDatabaseTableTriggerSetup and ASSIGNS all four flags: true for a table id in 1..99999 (and a few others) when
// CompanyName() <> ''. Base Application's GlobalTriggerManagement (codeunit 49) raises that event from its own subscriber to
// "Global Triggers".GetDatabaseTableTriggerSetup. The main corpus app runs without Tests-TestLibraries; there
// events/lt-platform-events-v/PeVFixtures.al saw the inbound flags No on Linux and Yes on Windows.
// Observed here, per own table (each table is written by one test only, so each asks for its setup once):
// - the flags a subscriber to "Global Triggers".GetDatabaseTableTriggerSetup receives (in) and the flags a subscriber to
//   GlobalTriggerManagement.OnAfterGetDatabaseTableTriggerSetup receives (after_in), and in which order the two run;
// - the inbound mask of "Global Triggers".GetGlobalTableTriggerMask;
// - which of OnDatabaseInsert / Modify / Rename / Delete then run for the table, when this app's subscribers
//   leave the flags alone (row 1), set all four false in the "Global Triggers" subscriber (row 2), set all four false in the
//   OnAfter subscriber (row 3), or set only Insert true and the rest false in the "Global Triggers" subscriber (row 4).
// Every write runs with RunTrigger true (tests/al-language/events/lt-table-trigger-setup-calls/TableTriggerSetupCalls.al:
// without it the setup is not asked).
// Probe: observed values; every literal asserted below is what the BC tier produced (corpus CI job test-testlibraries,
// run 39223234414 on BC 29.0; 27.5 and 28.5 by the CI matrix).
// Facts seen: GetGlobalTableTriggerMask is asked first (inbound mask 0); then Base Application's "Global Triggers" subscriber runs
// (with 130011 before this app's OnAfter subscriber, which receives YesYesYesYes), then this app's "Global Triggers" subscriber,
// which receives what the OnAfter chain left (YesYesYesYes, as on Windows per PeVFixtures.al). The last assignment wins.
// BC versions: 27, 28, 29

table 81570 "LT BI TS Row 1"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 81571 "LT BI TS Row 2"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 81572 "LT BI TS Row 3"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 81573 "LT BI TS Row 4"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 81575 "LT BI TS Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

codeunit 81576 "LT BI TS Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure Setup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        L: Codeunit "LT BI TS Log";
        RowNo: Integer;
    begin
        RowNo := RowOf(TableId);
        if RowNo = 0 then
            exit;
        L.Add('setup' + Format(RowNo) + ' in=' + Flags(OnDatabaseInsert, OnDatabaseModify, OnDatabaseDelete, OnDatabaseRename));
        case RowNo of
            2:
                begin
                    OnDatabaseInsert := false;
                    OnDatabaseModify := false;
                    OnDatabaseDelete := false;
                    OnDatabaseRename := false;
                end;
            4:
                begin
                    OnDatabaseInsert := true;
                    OnDatabaseModify := false;
                    OnDatabaseDelete := false;
                    OnDatabaseRename := false;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetDatabaseTableTriggerSetup', '', false, false)]
    local procedure AfterSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        L: Codeunit "LT BI TS Log";
        RowNo: Integer;
    begin
        RowNo := RowOf(TableId);
        if RowNo = 0 then
            exit;
        L.Add('after' + Format(RowNo) + ' in=' + Flags(OnDatabaseInsert, OnDatabaseModify, OnDatabaseDelete, OnDatabaseRename));
        if RowNo = 3 then begin
            OnDatabaseInsert := false;
            OnDatabaseModify := false;
            OnDatabaseDelete := false;
            OnDatabaseRename := false;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetGlobalTableTriggerMask', '', false, false)]
    local procedure Mask(TableId: Integer; var TableTriggerMask: Integer)
    var
        L: Codeunit "LT BI TS Log";
        RowNo: Integer;
    begin
        RowNo := RowOf(TableId);
        if RowNo = 0 then
            exit;
        L.Add('mask' + Format(RowNo) + ' in=' + Format(TableTriggerMask));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure DbInsert(RecRef: RecordRef)
    begin
        LogDb('dbinsert', RecRef.Number);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseModify', '', false, false)]
    local procedure DbModify(RecRef: RecordRef)
    begin
        LogDb('dbmodify', RecRef.Number);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseDelete', '', false, false)]
    local procedure DbDelete(RecRef: RecordRef)
    begin
        LogDb('dbdelete', RecRef.Number);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseRename', '', false, false)]
    local procedure DbRename(RecRef: RecordRef; xRecRef: RecordRef)
    begin
        LogDb('dbrename', RecRef.Number);
    end;

    local procedure LogDb(What: Text; TableId: Integer)
    var
        L: Codeunit "LT BI TS Log";
        RowNo: Integer;
    begin
        RowNo := RowOf(TableId);
        if RowNo = 0 then
            exit;
        L.Add(What + Format(RowNo));
    end;

    local procedure RowOf(TableId: Integer): Integer
    begin
        case TableId of
            Database::"LT BI TS Row 1":
                exit(1);
            Database::"LT BI TS Row 2":
                exit(2);
            Database::"LT BI TS Row 3":
                exit(3);
            Database::"LT BI TS Row 4":
                exit(4);
        end;
        exit(0);
    end;

    local procedure Flags(I: Boolean; M: Boolean; D: Boolean; R: Boolean): Text
    begin
        exit(Format(I) + Format(M) + Format(D) + Format(R));
    end;
}

codeunit 81577 "LT BI Trigger Setup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Insert, Modify, Rename and Delete one row; the log of each step is observed separately.
    [Test]
    procedure BiTs_Row1_FlagsLeftAlone()
    var
        R: Record "LT BI TS Row 1";
        L: Codeunit "LT BI TS Log";
        Observer: Codeunit "Probe Observer";
    begin
        L.Take();
        R.Id := 1;
        R.Insert(true);
        Observer.Observe('insert', L.Take());
        R.Name := 'x';
        R.Modify(true);
        Observer.Observe('modify', L.Take());
        R.Rename(2);
        Observer.Observe('rename', L.Take());
        R.Delete(true);
        Observer.Observe('delete', L.Take());
        Observer.Expect('insert', 'mask1 in=0;after1 in=YesYesYesYes;setup1 in=YesYesYesYes;dbinsert1;');
        Observer.Expect('modify', 'dbmodify1;');
        Observer.Expect('rename', 'dbrename1;');
        Observer.Expect('delete', 'dbdelete1;');
        Observer.Verify();
    end;

    [Test]
    procedure BiTs_Row2_FalseInGlobalTriggersSubscriber()
    var
        R: Record "LT BI TS Row 2";
        L: Codeunit "LT BI TS Log";
        Observer: Codeunit "Probe Observer";
    begin
        L.Take();
        R.Id := 1;
        R.Insert(true);
        Observer.Observe('insert', L.Take());
        R.Name := 'x';
        R.Modify(true);
        Observer.Observe('modify', L.Take());
        R.Rename(2);
        Observer.Observe('rename', L.Take());
        R.Delete(true);
        Observer.Observe('delete', L.Take());
        Observer.Expect('insert', 'mask2 in=0;after2 in=YesYesYesYes;setup2 in=YesYesYesYes;');
        Observer.Expect('modify', '');
        Observer.Expect('rename', '');
        Observer.Expect('delete', '');
        Observer.Verify();
    end;

    [Test]
    procedure BiTs_Row3_FalseInOnAfterSubscriber()
    var
        R: Record "LT BI TS Row 3";
        L: Codeunit "LT BI TS Log";
        Observer: Codeunit "Probe Observer";
    begin
        L.Take();
        R.Id := 1;
        R.Insert(true);
        Observer.Observe('insert', L.Take());
        R.Name := 'x';
        R.Modify(true);
        Observer.Observe('modify', L.Take());
        R.Rename(2);
        Observer.Observe('rename', L.Take());
        R.Delete(true);
        Observer.Observe('delete', L.Take());
        Observer.Expect('insert', 'mask3 in=0;after3 in=YesYesYesYes;setup3 in=NoNoNoNo;');
        Observer.Expect('modify', '');
        Observer.Expect('rename', '');
        Observer.Expect('delete', '');
        Observer.Verify();
    end;

    [Test]
    procedure BiTs_Row4_OnlyInsertInGlobalTriggersSubscriber()
    var
        R: Record "LT BI TS Row 4";
        L: Codeunit "LT BI TS Log";
        Observer: Codeunit "Probe Observer";
    begin
        L.Take();
        R.Id := 1;
        R.Insert(true);
        Observer.Observe('insert', L.Take());
        R.Name := 'x';
        R.Modify(true);
        Observer.Observe('modify', L.Take());
        R.Rename(2);
        Observer.Observe('rename', L.Take());
        R.Delete(true);
        Observer.Observe('delete', L.Take());
        Observer.Expect('insert', 'mask4 in=0;after4 in=YesYesYesYes;setup4 in=YesYesYesYes;dbinsert4;');
        Observer.Expect('modify', '');
        Observer.Expect('rename', '');
        Observer.Expect('delete', '');
        Observer.Verify();
    end;
}
