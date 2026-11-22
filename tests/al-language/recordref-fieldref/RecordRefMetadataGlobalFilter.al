// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 55230-55232 (LT RR Meta Filtered, LT RR Meta Control, LT RR Meta Global Filter)
// Probe: from al-runner issue 7874 (RecordRef metadata calls on a table while another Record variable holds a filter in filter group 1;
//   record/filters/FilterGroupOtherVariable.al measures only Count and GetFilters of a RecordRef in that state).
// Area: a table of 4 rows (Qty 1, 2, 1, 2). A Record variable sets Qty = 1 in filter group 1, goes back to group 0 and leaves scope
//   (the filter stands for the session). A RecordRef is then opened on the table. One call per test:
//   - Number, Name, Caption; FieldCount, FieldExist, KeyCount, IsTemporary; Close and reopen and Count;
//   - RecordId before any read, CurrentKeyIndex, KeyIndex(1), FieldIndex(1), Field(1) Name, Caption and Type, SecurityFiltering,
//     ReadPermission;
//   - the Count of the RecordRef after the call (the filter still applies to rows).
//   The control tests make the same calls on a table without a global filter.
// Every test starts by taking back an earlier filter, seeding the four rows and setting the filter again; the last test takes it back.
// What BC did (BC 29.0 on the local host): every metadata call answers as it does without a global filter (the control test): Number,
//   Name, Caption, FieldCount, FieldExist, KeyCount, IsTemporary, RecordId (table name and 0), CurrentKeyIndex, KeyIndex, FieldIndex,
//   Field(1) Name, Caption and Type, SecurityFiltering and ReadPermission; Close and reopen shows Count 2 under the filter and 4 without.
// Observation form: every test ends in Finish(); the values are what BC produced.
// BC versions: 27.5, 28.5, 29.0 (measured by the corpus CI)

table 55230 "LT RR Meta Filtered"
{
    DataClassification = SystemMetadata;
    Caption = 'LT RR Meta Filtered Caption';

    fields
    {
        field(1; Id; Integer) { Caption = 'Row Id'; }
        field(2; Qty; Integer) { }
        field(3; Note; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(Sec; Qty) { }
    }
}

table 55231 "LT RR Meta Control"
{
    DataClassification = SystemMetadata;
    Caption = 'LT RR Meta Control Caption';

    fields
    {
        field(1; Id; Integer) { Caption = 'Row Id'; }
        field(2; Qty; Integer) { }
        field(3; Note; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(Sec; Qty) { }
    }
}

codeunit 55232 "LT RR Meta Global Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SetFilter()
    var
        R: Record "LT RR Meta Filtered";
    begin
        R.FilterGroup(1);
        R.SetRange(Qty, 1);
        R.FilterGroup(0);
    end;

    local procedure ClearFilter()
    var
        R: Record "LT RR Meta Filtered";
    begin
        R.FilterGroup(1);
        R.SetRange(Qty);
        R.FilterGroup(0);
    end;

    // Takes back an earlier filter, seeds four rows, then sets the global filter.
    local procedure Setup()
    var
        R: Record "LT RR Meta Filtered";
    begin
        ClearFilter();
        R.DeleteAll();
        Add(1, 1);
        Add(2, 2);
        Add(3, 1);
        Add(4, 2);
        SetFilter();
    end;

    local procedure Add(NewId: Integer; NewQty: Integer)
    var
        R: Record "LT RR Meta Filtered";
    begin
        R.Init();
        R.Id := NewId;
        R.Qty := NewQty;
        R.Insert();
    end;

    local procedure SetupControl()
    var
        R: Record "LT RR Meta Control";
    begin
        R.DeleteAll();
        R.Init(); R.Id := 1; R.Qty := 1; R.Insert();
        R.Init(); R.Id := 2; R.Qty := 2; R.Insert();
        R.Init(); R.Id := 3; R.Qty := 1; R.Insert();
        R.Init(); R.Id := 4; R.Qty := 2; R.Insert();
    end;

    [TryFunction]
    local procedure TryRecordId(var RR: RecordRef; var Result: Text)
    begin
        Result := Format(RR.RecordId());
    end;

    [TryFunction]
    local procedure TryCurrentKeyIndex(var RR: RecordRef; var Result: Text)
    begin
        Result := Format(RR.CurrentKeyIndex());
    end;

    [TryFunction]
    local procedure TryKeyIndex(var RR: RecordRef; var Result: Text)
    var
        K: KeyRef;
    begin
        K := RR.KeyIndex(1);
        Result := Format(K.FieldCount()) + ' ' + Format(K.FieldIndex(1).Name());
    end;

    [TryFunction]
    local procedure TryFieldIndex(var RR: RecordRef; var Result: Text)
    var
        F: FieldRef;
    begin
        F := RR.FieldIndex(1);
        Result := F.Name();
    end;

    [Test]
    procedure Filtered_Number()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Info: Text;
    begin
        Setup();
        RR.Open(Database::"LT RR Meta Filtered");
        Observer.Observe('number is the table id', Format(RR.Number() = Database::"LT RR Meta Filtered"));
        Observer.Expect('number is the table id', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_Name()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Info: Text;
    begin
        Setup();
        RR.Open(Database::"LT RR Meta Filtered");
        Observer.Observe('name', RR.Name());
        Observer.Expect('name', 'LT RR Meta Filtered');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_Caption()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Info: Text;
    begin
        Setup();
        RR.Open(Database::"LT RR Meta Filtered");
        Observer.Observe('caption', RR.Caption());
        Observer.Expect('caption', 'LT RR Meta Filtered Caption');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_FieldCount()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Info: Text;
    begin
        Setup();
        RR.Open(Database::"LT RR Meta Filtered");
        Observer.Observe('field count', Format(RR.FieldCount()));
        Observer.Expect('field count', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_FieldExist()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Info: Text;
    begin
        Setup();
        RR.Open(Database::"LT RR Meta Filtered");
        Observer.Observe('field 2 exists', Format(RR.FieldExist(2)));
        Observer.Observe('field 9 exists', Format(RR.FieldExist(9)));
        Observer.Expect('field 2 exists', 'Yes');
        Observer.Expect('field 9 exists', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_KeyCount()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Info: Text;
    begin
        Setup();
        RR.Open(Database::"LT RR Meta Filtered");
        Observer.Observe('key count', Format(RR.KeyCount()));
        Observer.Expect('key count', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_IsTemporary()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Info: Text;
    begin
        Setup();
        RR.Open(Database::"LT RR Meta Filtered");
        Observer.Observe('is temporary', Format(RR.IsTemporary()));
        Observer.Expect('is temporary', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_RecordId_BeforeRead()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Info: Text;
    begin
        Setup();
        RR.Open(Database::"LT RR Meta Filtered");
        if TryRecordId(RR, Info) then
            Observer.Observe('record id', Info)
        else
            Observer.ObserveError('record id');
        Observer.Expect('record id', 'LT RR Meta Filtered: 0');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_CurrentKeyIndex()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Info: Text;
    begin
        Setup();
        RR.Open(Database::"LT RR Meta Filtered");
        if TryCurrentKeyIndex(RR, Info) then
            Observer.Observe('current key index', Info)
        else
            Observer.ObserveError('current key index');
        Observer.Expect('current key index', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_KeyIndex1()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Info: Text;
    begin
        Setup();
        RR.Open(Database::"LT RR Meta Filtered");
        if TryKeyIndex(RR, Info) then
            Observer.Observe('key 1', Info)
        else
            Observer.ObserveError('key 1');
        Observer.Expect('key 1', '1 Id');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_FieldIndex1()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Info: Text;
    begin
        Setup();
        RR.Open(Database::"LT RR Meta Filtered");
        if TryFieldIndex(RR, Info) then
            Observer.Observe('field index 1', Info)
        else
            Observer.ObserveError('field index 1');
        Observer.Expect('field index 1', 'Id');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_Field1_Name()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Info: Text;
    begin
        Setup();
        RR.Open(Database::"LT RR Meta Filtered");
        Observer.Observe('field 1 name', RR.Field(1).Name());
        Observer.Expect('field 1 name', 'Id');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_Field1_Caption()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Info: Text;
    begin
        Setup();
        RR.Open(Database::"LT RR Meta Filtered");
        Observer.Observe('field 1 caption', RR.Field(1).Caption());
        Observer.Expect('field 1 caption', 'Row Id');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_Field1_Type()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Info: Text;
    begin
        Setup();
        RR.Open(Database::"LT RR Meta Filtered");
        Observer.Observe('field 1 type', Format(RR.Field(1).Type()));
        Observer.Expect('field 1 type', 'Integer');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_SecurityFiltering()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Info: Text;
    begin
        Setup();
        RR.Open(Database::"LT RR Meta Filtered");
        Observer.Observe('security filtering', Format(RR.SecurityFiltering()));
        Observer.Expect('security filtering', 'Validated');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_ReadPermission()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Info: Text;
    begin
        Setup();
        RR.Open(Database::"LT RR Meta Filtered");
        Observer.Observe('read permission', Format(RR.ReadPermission()));
        Observer.Expect('read permission', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_Close_Reopen_Count()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Info: Text;
    begin
        Setup();
        RR.Open(Database::"LT RR Meta Filtered");
        RR.Close();
        RR.Open(Database::"LT RR Meta Filtered");
        Observer.Observe('count after reopen', Format(RR.Count()));
        Observer.Observe('name after reopen', RR.Name());
        Observer.Expect('count after reopen', '2');
        Observer.Expect('name after reopen', 'LT RR Meta Filtered');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_Count_After_Metadata()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Info: Text;
    begin
        Setup();
        RR.Open(Database::"LT RR Meta Filtered");
        Observer.Observe('number', Format(RR.Number() = Database::"LT RR Meta Filtered"));
        Observer.Observe('field count', Format(RR.FieldCount()));
        Observer.Observe('key count', Format(RR.KeyCount()));
        Observer.Observe('count', Format(RR.Count()));
        Observer.Observe('is empty', Format(RR.IsEmpty()));
        Observer.Observe('find first', Format(RR.FindFirst()));
        Observer.Observe('first row id', Format(RR.Field(1).Value()));
        Observer.Expect('number', 'Yes');
        Observer.Expect('field count', '3');
        Observer.Expect('key count', '3');
        Observer.Expect('count', '2');
        Observer.Expect('is empty', 'No');
        Observer.Expect('find first', 'Yes');
        Observer.Expect('first row id', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Control_NoGlobalFilter_Metadata()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Info: Text;
    begin
        SetupControl();
        RR.Open(Database::"LT RR Meta Control");
        Observer.Observe('number is the table id', Format(RR.Number() = Database::"LT RR Meta Control"));
        Observer.Observe('name', RR.Name());
        Observer.Observe('caption', RR.Caption());
        Observer.Observe('field count', Format(RR.FieldCount()));
        Observer.Observe('field 2 exists', Format(RR.FieldExist(2)));
        Observer.Observe('field 9 exists', Format(RR.FieldExist(9)));
        Observer.Observe('key count', Format(RR.KeyCount()));
        Observer.Observe('is temporary', Format(RR.IsTemporary()));
        Observer.Observe('field 1 name', RR.Field(1).Name());
        Observer.Observe('field 1 caption', RR.Field(1).Caption());
        Observer.Observe('field 1 type', Format(RR.Field(1).Type()));
        Observer.Observe('security filtering', Format(RR.SecurityFiltering()));
        Observer.Observe('read permission', Format(RR.ReadPermission()));
        if TryRecordId(RR, Info) then
            Observer.Observe('record id', Info)
        else
            Observer.ObserveError('record id');
        if TryCurrentKeyIndex(RR, Info) then
            Observer.Observe('current key index', Info)
        else
            Observer.ObserveError('current key index');
        if TryKeyIndex(RR, Info) then
            Observer.Observe('key 1', Info)
        else
            Observer.ObserveError('key 1');
        if TryFieldIndex(RR, Info) then
            Observer.Observe('field index 1', Info)
        else
            Observer.ObserveError('field index 1');
        Observer.Expect('number is the table id', 'Yes');
        Observer.Expect('name', 'LT RR Meta Control');
        Observer.Expect('caption', 'LT RR Meta Control Caption');
        Observer.Expect('field count', '3');
        Observer.Expect('field 2 exists', 'Yes');
        Observer.Expect('field 9 exists', 'No');
        Observer.Expect('key count', '3');
        Observer.Expect('is temporary', 'No');
        Observer.Expect('field 1 name', 'Id');
        Observer.Expect('field 1 caption', 'Row Id');
        Observer.Expect('field 1 type', 'Integer');
        Observer.Expect('security filtering', 'Validated');
        Observer.Expect('read permission', 'Yes');
        Observer.Expect('record id', 'LT RR Meta Control: 0');
        Observer.Expect('current key index', '1');
        Observer.Expect('key 1', '1 Id');
        Observer.Expect('field index 1', 'Id');
        Observer.Verify();
    end;

    [Test]
    procedure Control_NoGlobalFilter_Close_Reopen_Count()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Info: Text;
    begin
        SetupControl();
        RR.Open(Database::"LT RR Meta Control");
        RR.Close();
        RR.Open(Database::"LT RR Meta Control");
        Observer.Observe('count after reopen', Format(RR.Count()));
        Observer.Observe('name after reopen', RR.Name());
        Observer.Expect('count after reopen', '4');
        Observer.Expect('name after reopen', 'LT RR Meta Control');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_ZZ_TakeFilterBack()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        // Last test of the codeunit: takes the global filter back so no later test codeunit sees it.
        Setup();
        ClearFilter();
        RR.Open(Database::"LT RR Meta Filtered");
        Observer.Observe('count after the filter was taken back', Format(RR.Count()));
        Observer.Expect('count after the filter was taken back', '4');
        Observer.Verify();
    end;
}
