// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-system-fields
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 90324, test codeunit 90325
// Probe (outside issue 6153): `if not Rec.Insert(false) then Rec.Modify(false);` on a key that already exists. Which SystemId the record variable holds after the failed Insert and after
//   the Modify (the stored row's, the first inserted variable's, a new one, null), what is stored, and the same with an explicit SystemId, with Insert(true) and through RecordRef.
//   Only equalities and null checks are observed (the GUID values differ between runs). DbtSystemFields.al covers SystemId after a successful Insert, Modify and Get.
// BC versions: 27-29

table 90324 "LT UF SysId Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 90325 "LT UF Failed Insert SystemId"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure FailedInsert_ThenModify_SystemIdOfVariable()
    var
        Observer: Codeunit "Probe Observer";
        First: Record "LT UF SysId Row";
        Entry: Record "LT UF SysId Row";
        Stored: Record "LT UF SysId Row";
        NullId: Guid;
    begin
        First.Init();
        First."No." := 'C';
        First.Insert(false);

        Entry.Init();
        Entry."No." := 'C';
        Entry.Name := 'changed';
        Observer.Observe('entry sysid null after Init', Format(Entry.SystemId = NullId));
        Observer.Observe('insert result', Format(Entry.Insert(false)));
        Observer.Observe('entry sysid null after failed insert', Format(Entry.SystemId = NullId));
        Observer.Observe('entry sysid = first after failed insert', Format(Entry.SystemId = First.SystemId));
        Entry.Modify(false);
        Observer.Observe('entry sysid null after modify', Format(Entry.SystemId = NullId));
        Stored.Get('C');
        Observer.Observe('entry sysid = stored', Format(Entry.SystemId = Stored.SystemId));
        Observer.Observe('entry sysid = first', Format(Entry.SystemId = First.SystemId));
        Observer.Observe('stored sysid = first', Format(Stored.SystemId = First.SystemId));
        Observer.Observe('stored name', Stored.Name);
        Observer.Finish();
    end;

    [Test]
    procedure IfNotInsert_ThenModify_Idiom()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "LT UF SysId Row";
        Stored: Record "LT UF SysId Row";
        Ref: RecordRef;
        NullId: Guid;
        Round: Integer;
    begin
        for Round := 1 to 2 do begin
            Entry.Init();
            Entry."No." := 'D';
            Entry.Name := 'round ' + Format(Round);
            if not Entry.Insert(false) then
                Entry.Modify(false);
            Stored.Get('D');
            Observer.Observe('round ' + Format(Round) + ' entry sysid = stored', Format(Entry.SystemId = Stored.SystemId));
            Observer.Observe('round ' + Format(Round) + ' entry sysid null', Format(Entry.SystemId = NullId));
            Observer.Observe('round ' + Format(Round) + ' stored name', Stored.Name);
        end;
        Ref.Get(Entry.RecordId());
        Observer.Observe('recordref sysid = entry', Format(Format(Ref.Field(Entry.FieldNo(SystemId)).Value) = Format(Entry.SystemId)));
        Observer.Observe('count', Format(Stored.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure FailedInsert_Variants()
    var
        Observer: Codeunit "Probe Observer";
        First: Record "LT UF SysId Row";
        Entry: Record "LT UF SysId Row";
        Explicit: Record "LT UF SysId Row";
        Stored: Record "LT UF SysId Row";
        Wanted: Guid;
    begin
        First.Init();
        First."No." := 'E';
        First.Insert(true);

        Entry.Init();
        Entry."No." := 'E';
        Observer.Observe('insert(true) result', Format(Entry.Insert(true)));
        Observer.Observe('insert(true) sysid = first', Format(Entry.SystemId = First.SystemId));
        Observer.Observe('insert(true) error', Format(not Entry.Insert()));

        Wanted := CreateGuid();
        Explicit.Init();
        Explicit."No." := 'E';
        Explicit.SystemId := Wanted;
        Observer.Observe('explicit insert result', Format(Explicit.Insert(false)));
        Observer.Observe('explicit sysid kept', Format(Explicit.SystemId = Wanted));
        Explicit.Modify(false);
        Observer.Observe('explicit sysid after modify kept', Format(Explicit.SystemId = Wanted));
        Stored.Get('E');
        Observer.Observe('stored sysid = first', Format(Stored.SystemId = First.SystemId));
        Observer.Observe('stored sysid = explicit', Format(Stored.SystemId = Wanted));
        Observer.Finish();
    end;

    [Test]
    procedure FailedInsert_StatementForm()
    var
        Observer: Codeunit "Probe Observer";
        First: Record "LT UF SysId Row";
        Entry: Record "LT UF SysId Row";
        NullId: Guid;
    begin
        First.Init();
        First."No." := 'F';
        First.Insert(false);
        Entry.Init();
        Entry."No." := 'F';
        Observer.Observe('try insert(true)', Format(TryInsert(Entry, true)));
        Observer.ObserveError('insert(true) error');
        Observer.Observe('entry sysid null after insert(true)', Format(Entry.SystemId = NullId));
        Observer.Observe('try insert(false)', Format(TryInsert(Entry, false)));
        Observer.ObserveError('insert(false) error');
        Observer.Observe('entry sysid null after insert(false)', Format(Entry.SystemId = NullId));
        Observer.Observe('try insert()', Format(TryInsertDefault(Entry)));
        Observer.ObserveError('insert() error');
        Observer.Observe('entry sysid null after insert()', Format(Entry.SystemId = NullId));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryInsert(var Row: Record "LT UF SysId Row"; RunTrigger: Boolean)
    begin
        Row.Insert(RunTrigger);
    end;

    [TryFunction]
    local procedure TryInsertDefault(var Row: Record "LT UF SysId Row")
    begin
        Row.Insert();
    end;
}
