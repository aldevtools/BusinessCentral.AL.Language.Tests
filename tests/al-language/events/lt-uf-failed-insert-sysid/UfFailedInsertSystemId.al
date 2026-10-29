// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-system-fields
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 90324, test codeunit 90325 (the statement form of a failing Insert is left out: asserterror and Codeunit.Run give different answers on the SaaS tier)
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
        Observer.Expect('entry sysid null after Init', 'Yes');
        Observer.Expect('insert result', 'No');
        Observer.Expect('entry sysid null after failed insert', 'Yes');
        Observer.Expect('entry sysid = first after failed insert', 'No');
        Observer.Expect('entry sysid null after modify', 'No');
        Observer.Expect('entry sysid = stored', 'Yes');
        Observer.Expect('entry sysid = first', 'Yes');
        Observer.Expect('stored sysid = first', 'Yes');
        Observer.Expect('stored name', 'changed');
        Observer.Verify();
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
        Observer.Observe('count', Format(CountRows('D')));
        Observer.Expect('round 1 entry sysid = stored', 'Yes');
        Observer.Expect('round 1 entry sysid null', 'No');
        Observer.Expect('round 1 stored name', 'round 1');
        Observer.Expect('round 2 entry sysid = stored', 'Yes');
        Observer.Expect('round 2 entry sysid null', 'No');
        Observer.Expect('round 2 stored name', 'round 2');
        Observer.Expect('recordref sysid = entry', 'Yes');
        Observer.Expect('count', '1');
        Observer.Verify();
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
        NullId: Guid;
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
        Observer.Observe('explicit sysid null', Format(Explicit.SystemId = NullId));
        Explicit.Modify(false);
        Observer.Observe('explicit sysid after modify kept', Format(Explicit.SystemId = Wanted));
        Observer.Observe('explicit sysid after modify = first', Format(Explicit.SystemId = First.SystemId));
        Stored.Get('E');
        Observer.Observe('stored sysid = first', Format(Stored.SystemId = First.SystemId));
        Observer.Observe('stored sysid = explicit', Format(Stored.SystemId = Wanted));
        Observer.Expect('insert(true) result', 'No');
        Observer.Expect('insert(true) sysid = first', 'No');
        Observer.Expect('insert(true) error', 'Yes');
        Observer.Expect('explicit insert result', 'No');
        Observer.Expect('explicit sysid kept', 'No');
        Observer.Expect('explicit sysid null', 'Yes');
        Observer.Expect('explicit sysid after modify kept', 'No');
        Observer.Expect('explicit sysid after modify = first', 'Yes');
        Observer.Expect('stored sysid = first', 'Yes');
        Observer.Expect('stored sysid = explicit', 'No');
        Observer.Verify();
    end;

    local procedure CountRows(No: Code[20]): Integer
    var
        Rows: Record "LT UF SysId Row";
    begin
        Rows.SetRange("No.", No);
        exit(Rows.Count());
    end;
}
