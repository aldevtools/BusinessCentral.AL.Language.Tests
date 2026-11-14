// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-registertableconnection-method
// Scope: in-scope (Cloud-compatible: CRM is the one TableConnectionType a Cloud extension may register)
// Fixtures used: Probe Observer (69160); table 71974 (a CRM table with triggers), test codeunit 71975
// Probe: DRAFT, observe form, not yet run on BC (al-runner issue 7837). Every value is observed; the pipeline turns them into Expect lines.
// Facts: on a TableType = CRM table served by the '@@test@@' table connection, whether the table's own OnInsert, OnModify,
//   OnDelete and OnRename triggers run for Insert(true), Modify(true), Delete(true) and Rename, and that they do not for
//   Insert(false), Modify(false) and Delete(false); what a field the trigger sets reads back after the call and from the
//   connection (Get); the order against the global OnDatabaseInsert is not covered here.
//   Already pinned elsewhere: Insert/Get/Modify/Delete on a CRM table without triggers (TestDatabaseTableConnectionCrm.al,
//   al-language-onprem/session-system/Y16CrmTableConnectionOps.al).
// BC versions: 27, 28, 29 by CI

// local object: the triggers of a TableType = CRM table are under test; the shared CRM fixture (60291) has none
table 71974 "SES CRM Triggered"
{
    TableType = CRM;
    ExternalName = 'ses_triggered';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; ThingId; Guid)
        {
            ExternalName = 'ses_triggeredid';
            ExternalType = 'Uniqueidentifier';
            ExternalAccess = Insert;
            DataClassification = SystemMetadata;
        }
        field(2; Name; Text[100])
        {
            ExternalName = 'ses_name';
            ExternalType = 'String';
            DataClassification = SystemMetadata;
        }
        field(3; Note; Text[100])
        {
            ExternalName = 'ses_note';
            ExternalType = 'String';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; ThingId) { Clustered = true; }
    }

    trigger OnInsert()
    begin
        Note := 'insert trigger';
    end;

    trigger OnModify()
    begin
        Note := 'modify trigger';
    end;

    trigger OnDelete()
    begin
        TriggerLog.Add('delete trigger');
    end;

    trigger OnRename()
    begin
        Note := 'rename trigger';
    end;

    var
        TriggerLog: List of [Text];

    procedure DeleteLog(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in TriggerLog do
            Result += Line + ';';
        exit(Result);
    end;
}

codeunit 71975 "SES CRM Triggered Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        ConnectionNameTok: Label 'SESTRIG', Locked = true;
        TestConnectionStringTok: Label '@@test@@', Locked = true;

    local procedure Initialize()
    begin
        if HasTableConnection(TableConnectionType::CRM, ConnectionNameTok) then
            UnregisterTableConnection(TableConnectionType::CRM, ConnectionNameTok);
        RegisterTableConnection(TableConnectionType::CRM, ConnectionNameTok, TestConnectionStringTok);
        SetDefaultTableConnection(TableConnectionType::CRM, ConnectionNameTok);
    end;

    local procedure Finish()
    begin
        UnregisterTableConnection(TableConnectionType::CRM, ConnectionNameTok);
        Observer.Finish();
    end;

    local procedure StoredNote(Id: Guid): Text
    var
        T: Record "SES CRM Triggered";
    begin
        if not T.Get(Id) then
            exit('<not found>');
        exit(T.Note);
    end;

    [TryFunction]
    local procedure TryRename(var T: Record "SES CRM Triggered"; NewId: Guid)
    begin
        T.Rename(NewId);
    end;

    [Test]
    procedure Crm_InsertTrue_RunsOnInsert()
    var
        T: Record "SES CRM Triggered";
    begin
        Initialize();
        T.ThingId := CreateGuid();
        T.Name := 'a';
        T.Insert(true);
        Observer.Observe('note after insert', T.Note);
        Observer.Observe('stored note', StoredNote(T.ThingId));
        Finish();
    end;

    [Test]
    procedure Crm_InsertFalse_SkipsOnInsert()
    var
        T: Record "SES CRM Triggered";
    begin
        Initialize();
        T.ThingId := CreateGuid();
        T.Name := 'a';
        T.Insert(false);
        Observer.Observe('note after insert', T.Note);
        Observer.Observe('stored note', StoredNote(T.ThingId));
        Finish();
    end;

    [Test]
    procedure Crm_InsertTrue_EmptyGuid_RunsOnInsert()
    var
        T: Record "SES CRM Triggered";
    begin
        Initialize();
        T.Name := 'a';
        T.Insert(true);
        Observer.Observe('note after insert', T.Note);
        Observer.Observe('id assigned', Format(not IsNullGuid(T.ThingId)));
        Observer.Observe('stored note', StoredNote(T.ThingId));
        Finish();
    end;

    [Test]
    procedure Crm_ModifyTrue_RunsOnModify()
    var
        T: Record "SES CRM Triggered";
    begin
        Initialize();
        T.ThingId := CreateGuid();
        T.Insert(false);
        T.Name := 'b';
        T.Modify(true);
        Observer.Observe('note after modify', T.Note);
        Observer.Observe('stored note', StoredNote(T.ThingId));
        Finish();
    end;

    [Test]
    procedure Crm_ModifyFalse_SkipsOnModify()
    var
        T: Record "SES CRM Triggered";
    begin
        Initialize();
        T.ThingId := CreateGuid();
        T.Insert(false);
        T.Name := 'b';
        T.Modify(false);
        Observer.Observe('note after modify', T.Note);
        Observer.Observe('stored note', StoredNote(T.ThingId));
        Finish();
    end;

    [Test]
    procedure Crm_DeleteTrue_RunsOnDelete()
    var
        T: Record "SES CRM Triggered";
    begin
        Initialize();
        T.ThingId := CreateGuid();
        T.Insert(false);
        T.Delete(true);
        Observer.Observe('delete log', T.DeleteLog());
        Observer.Observe('stored note', StoredNote(T.ThingId));
        Finish();
    end;

    [Test]
    procedure Crm_DeleteFalse_SkipsOnDelete()
    var
        T: Record "SES CRM Triggered";
    begin
        Initialize();
        T.ThingId := CreateGuid();
        T.Insert(false);
        T.Delete(false);
        Observer.Observe('delete log', T.DeleteLog());
        Observer.Observe('stored note', StoredNote(T.ThingId));
        Finish();
    end;

    [Test]
    procedure Crm_Rename_OnRename()
    var
        T: Record "SES CRM Triggered";
        NewId: Guid;
    begin
        Initialize();
        T.ThingId := CreateGuid();
        T.Insert(false);
        NewId := CreateGuid();
        if TryRename(T, NewId) then
            Observer.Observe('rename', 'ok')
        else
            Observer.ObserveError('rename');
        Observer.Observe('note after rename', T.Note);
        Observer.Observe('stored note', StoredNote(NewId));
        Finish();
    end;
}
