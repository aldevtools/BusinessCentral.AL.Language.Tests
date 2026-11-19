// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods/devenv-passing-parameters
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 78790..78799 (BVT Entry, BVT Buffer, BVT Holder, BVT Caller,
//   BVT By Value Table Proc Tests, BVT Log, BVT More Callers, BVT Entry Runner, BVT Publisher, BVT Trigger Holder)
// local object: the parameter of a table procedure (a record of another table, by value) and the callee table's TableType are what
//   is under test.
// Probe (al-runner issue 8385): what a procedure of one table sees of the caller's view when it gets a record of ANOTHER, stored
//   table by value (a Record parameter without var), called as Buffer.Proc(Entry) from a codeunit. This is Base Application's path
//   in item availability: codeunit 5530 "Calc. Item Availability".TryGetQtyOnInventory hands a filtered Item Ledger Entry to
//   table 5530 "Inventory Event Buffer".TransferInventoryQty, which calls RecRef.GetTable(ItemLedgEntry).
//   ByValueRecordView.al (codeunit 78728) measured a codeunit procedure and a table procedure whose parameter is a record of its own
//   table (Rec.CountSameStatus(Rec)). Cells, each with the callee table TableType = Temporary (BVT Buffer) unless named:
//   - no filter (control); a filter in filter group 0 (GetFilters, Count, FindFirst, GetView, CurrentKey, Ascending, FilterGroup,
//     the filters of every group), also after FindFirst in the caller;
//   - the reporter's shape from a codeunit that is not a test codeunit: SetCurrentKey on a secondary key, SetRange, FindFirst, a second
//     SetRange, CalcSums, then RecordRef.GetTable in the callee (RecordId, GetFilters, Count, GetView);
//   - a filter in filter group 2, 4 and -1; the caller standing in group 2 (with its filter there, and with a filter in group 0);
//   - Ascending(false) with a filter; a marked row with MarkedOnly off and on; SetLoadFields before any read;
//   - a declared secondary key without a filter; an ad hoc key (fields no key starts with) with a filter;
//   - CalcFields of a FlowField with its FlowFilter in group 0; a filter on the FlowField itself (with its FlowFilter);
//   - a rich view (secondary key, descending, a filter and a FlowFilter in group 0, a filter in group 2, a marked current row);
//   - the copy handed on to Other.Copy in the callee;
//   - the callee table a normal table (BVT Holder), called on a stored record and on a temporary record variable;
//   - the procedure called from a procedure and from the OnInsert trigger of another table (BVT Holder);
//   - the source a global record of a codeunit, a var parameter, Rec of a codeunit with TableNo (Codeunit.Run), the var parameter
//     of an event subscriber; the procedure called from OnValidate, OnModify and OnDelete of a third table (BVT Trigger Holder);
//   - in every cell, the caller's filters, filter group and key after the call.
// Facts (observed on a local BC 29.1 OnPrem W1 container; 27.5 and 28.5 by the corpus CI):
//   - the by-value copy of a record of another table starts with the view of a fresh record, whatever the callee table's
//     TableType, the record variable the procedure runs on, the source (a local, a global, a var parameter, Rec of a TableNo
//     codeunit, an event subscriber's var parameter) and the caller (a test codeunit, another codeunit, an event subscriber, a
//     procedure or trigger of another table): no filters in groups -1, 0, 1, 2 and 4, filter group 0, the primary key, ascending
//     (GetView 'VERSION(1) SORTING(Entry No.)'), no marks (MarkedOnly No, 0 marked), all fields loaded after SetLoadFields in
//     the caller, no FlowFilter (CalcFields sums every location), Count and FindFirst over the whole table;
//   - it keeps the field values of the caller's current row (RecordRef.GetTable: RecordId 'BVT Entry: 3' after FindFirst);
//   - Other.Copy of the copy in the callee has no filter and the primary key;
//   - the caller's own filters, filter group, key, order and marks are unchanged after every call.
// BC versions: 27.5, 28.5, 29.0

table 78790 "BVT Entry"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Item Code"; Code[20]) { }
        field(3; "Location Code"; Code[10]) { }
        field(4; Quantity; Decimal) { }
        field(5; "Location Filter"; Code[10]) { FieldClass = FlowFilter; }
        field(6; "Item Qty"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("BVT Entry".Quantity where("Item Code" = field("Item Code"), "Location Code" = field("Location Filter")));
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ByItem; "Item Code", "Location Code") { SumIndexFields = Quantity; }
    }
}

table 78791 "BVT Buffer"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Info; Text[250]) { }
    }

    keys { key(PK; "Line No.") { Clustered = true; } }

    procedure DescribeEntry(E: Record "BVT Entry"): Text
    var
        Result: Text;
        First: Text;
    begin
        Result := 'id=' + Format(E."Entry No.") + ' f={' + E.GetFilters() + '} n=' + Format(E.Count()) + ' key=' + E.CurrentKey()
            + ' asc=' + Format(E.Ascending()) + ' grp=' + Format(E.FilterGroup());
        if E.FindFirst() then
            First := Format(E."Entry No.")
        else
            First := 'none';
        exit(Result + ' first=' + First);
    end;

    procedure ViewOf(E: Record "BVT Entry"): Text
    begin
        exit(E.GetView());
    end;

    procedure GroupsOf(E: Record "BVT Entry"): Text
    var
        Result: Text;
        Group: Integer;
    begin
        foreach Group in GroupList() do begin
            E.FilterGroup(Group);
            Result += Format(Group) + '={' + E.GetFilters() + '} ';
        end;
        E.FilterGroup(0);
        exit(Result + 'n=' + Format(E.Count()));
    end;

    local procedure GroupList(): List of [Integer]
    var
        L: List of [Integer];
    begin
        L.Add(-1);
        L.Add(0);
        L.Add(1);
        L.Add(2);
        L.Add(4);
        exit(L);
    end;

    procedure MarksOf(E: Record "BVT Entry"): Text
    var
        Result: Text;
    begin
        Result := 'mo=' + Format(E.MarkedOnly()) + ' n=' + Format(E.Count());
        E.MarkedOnly(true);
        exit(Result + ' marked n=' + Format(E.Count()));
    end;

    procedure LoadFieldsOf(E: Record "BVT Entry"): Text
    begin
        if not E.FindFirst() then
            exit('none');
        exit('first=' + Format(E."Entry No.") + ' qty loaded=' + Format(E.AreFieldsLoaded(Quantity)) + ' item loaded=' + Format(E.AreFieldsLoaded("Item Code")));
    end;

    procedure TotalOf(E: Record "BVT Entry"): Text
    begin
        E.CalcFields("Item Qty");
        exit('id=' + Format(E."Entry No.") + ' qty=' + Format(E."Item Qty") + ' f={' + E.GetFilters() + '}');
    end;

    procedure RecRefOf(E: Record "BVT Entry"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(E);
        exit('rid=' + Format(RecRef.RecordId) + ' f={' + RecRef.GetFilters() + '} n=' + Format(RecRef.Count()) + ' view=' + RecRef.GetView(false));
    end;

    procedure CopyOf(E: Record "BVT Entry"): Text
    var
        Other: Record "BVT Entry";
    begin
        Other.Copy(E);
        exit('id=' + Format(Other."Entry No.") + ' f={' + Other.GetFilters() + '} n=' + Format(Other.Count()) + ' key=' + Other.CurrentKey());
    end;
}

table 78792 "BVT Holder"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Info; Text[250]) { }
    }

    keys { key(PK; "Line No.") { Clustered = true; } }

    trigger OnInsert()
    var
        Entry: Record "BVT Entry";
        Buffer: Record "BVT Buffer";
    begin
        Entry.SetCurrentKey("Item Code", "Location Code");
        Entry.SetRange("Item Code", 'ITEM-A');
        Info := CopyStr(Buffer.DescribeEntry(Entry), 1, MaxStrLen(Info));
    end;

    procedure CollectFromTable(): Text
    var
        Entry: Record "BVT Entry";
        Buffer: Record "BVT Buffer";
    begin
        Entry.SetCurrentKey("Item Code", "Location Code");
        Entry.SetRange("Item Code", 'ITEM-A');
        Entry.FindFirst();
        exit(Buffer.RecRefOf(Entry) + ' | ' + Buffer.DescribeEntry(Entry));
    end;

    procedure DescribeEntry(E: Record "BVT Entry"): Text
    var
        Result: Text;
        First: Text;
    begin
        Result := 'id=' + Format(E."Entry No.") + ' f={' + E.GetFilters() + '} n=' + Format(E.Count()) + ' key=' + E.CurrentKey()
            + ' asc=' + Format(E.Ascending()) + ' grp=' + Format(E.FilterGroup());
        if E.FindFirst() then
            First := Format(E."Entry No.")
        else
            First := 'none';
        exit(Result + ' first=' + First);
    end;

    procedure RecRefOf(E: Record "BVT Entry"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(E);
        exit('rid=' + Format(RecRef.RecordId) + ' f={' + RecRef.GetFilters() + '} n=' + Format(RecRef.Count()) + ' view=' + RecRef.GetView(false));
    end;
}

codeunit 78793 "BVT Caller"
{
    // The reporter's shape: a codeunit that is not a test codeunit filters its own Entry variable and hands it by value to a
    // procedure of the Buffer it got as a var parameter.
    procedure CollectEntries(ItemCode: Code[20]; var Buffer: Record "BVT Buffer"; var RecRefSeen: Text; var Described: Text; var CallerAfter: Text)
    var
        Entry: Record "BVT Entry";
    begin
        Entry.SetCurrentKey("Item Code", "Location Code");
        Entry.SetRange("Item Code", ItemCode);
        if Entry.FindFirst() then begin
            Entry.SetRange("Location Code", Entry."Location Code");
            Entry.CalcSums(Quantity);
            RecRefSeen := Buffer.RecRefOf(Entry);
            Described := Buffer.DescribeEntry(Entry);
            CallerAfter := 'id=' + Format(Entry."Entry No.") + ' f={' + Entry.GetFilters() + '} n=' + Format(Entry.Count()) + ' key=' + Entry.CurrentKey()
                + ' sum=' + Format(Entry.Quantity);
        end;
    end;
}

codeunit 78794 "BVT By Value Table Proc Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Entries 1 (ITEM-A, BLUE, 2), 2 (ITEM-A, BLUE, 3), 3 (ITEM-A, RED, 5), 4 (ITEM-B, BLUE, 7).
    local procedure Initialize()
    var
        Entry: Record "BVT Entry";
        Holder: Record "BVT Holder";
        TriggerHolder: Record "BVT Trigger Holder";
        Log: Codeunit "BVT Log";
    begin
        Entry.DeleteAll();
        Holder.DeleteAll();
        TriggerHolder.DeleteAll();
        Log.Take();
        AddEntry(1, 'ITEM-A', 'BLUE', 2);
        AddEntry(2, 'ITEM-A', 'BLUE', 3);
        AddEntry(3, 'ITEM-A', 'RED', 5);
        AddEntry(4, 'ITEM-B', 'BLUE', 7);
    end;

    local procedure AddEntry(EntryNo: Integer; ItemCode: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        Entry: Record "BVT Entry";
    begin
        Entry."Entry No." := EntryNo;
        Entry."Item Code" := ItemCode;
        Entry."Location Code" := LocationCode;
        Entry.Quantity := Qty;
        Entry.Insert();
    end;

    local procedure ObserveCaller(var Observer: Codeunit "Probe Observer"; var Entry: Record "BVT Entry")
    begin
        Observer.Observe('caller after', 'f={' + Entry.GetFilters() + '} n=' + Format(Entry.Count()) + ' grp=' + Format(Entry.FilterGroup())
            + ' key=' + Entry.CurrentKey() + ' asc=' + Format(Entry.Ascending()));
    end;

    local procedure SetGroupFilter(var Entry: Record "BVT Entry"; Group: Integer)
    begin
        Entry.FilterGroup(Group);
        Entry.SetRange("Location Code", 'BLUE');
        Entry.FilterGroup(0);
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_NoFilter_Control()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Buffer: Record "BVT Buffer";
    begin
        Initialize();
        Observer.Observe('callee', Buffer.DescribeEntry(Entry));
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee', 'id=0 f={} n=4 key=Entry No. asc=Yes grp=0 first=1');
        Observer.Expect('caller after', 'f={} n=4 grp=0 key=Entry No. asc=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_Group0Filter()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Buffer: Record "BVT Buffer";
    begin
        Initialize();
        Entry.SetRange("Item Code", 'ITEM-B');
        Observer.Observe('callee', Buffer.DescribeEntry(Entry));
        Observer.Observe('callee view', Buffer.ViewOf(Entry));
        Observer.Observe('callee groups', Buffer.GroupsOf(Entry));
        Observer.Observe('callee recref', Buffer.RecRefOf(Entry));
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee', 'id=0 f={} n=4 key=Entry No. asc=Yes grp=0 first=1');
        Observer.Expect('callee view', 'VERSION(1) SORTING(Entry No.)');
        Observer.Expect('callee groups', '-1={} 0={} 1={} 2={} 4={} n=4');
        Observer.Expect('callee recref', 'rid=BVT Entry: 0 f={} n=4 view=VERSION(1) SORTING(Field1)');
        Observer.Expect('caller after', 'f={Item Code: ITEM-B} n=1 grp=0 key=Entry No. asc=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_Group0Filter_AfterFind()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Buffer: Record "BVT Buffer";
    begin
        Initialize();
        Entry.SetRange("Location Code", 'RED');
        Entry.FindFirst();
        Observer.Observe('callee', Buffer.DescribeEntry(Entry));
        Observer.Observe('callee recref', Buffer.RecRefOf(Entry));
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee', 'id=3 f={} n=4 key=Entry No. asc=Yes grp=0 first=1');
        Observer.Expect('callee recref', 'rid=BVT Entry: 3 f={} n=4 view=VERSION(1) SORTING(Field1)');
        Observer.Expect('caller after', 'f={Location Code: RED} n=1 grp=0 key=Entry No. asc=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_SecondaryKeyTwoFilters_FromCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "BVT Buffer";
        Caller: Codeunit "BVT Caller";
        RecRefSeen: Text;
        Described: Text;
        CallerAfter: Text;
    begin
        Initialize();
        Caller.CollectEntries('ITEM-A', Buffer, RecRefSeen, Described, CallerAfter);
        Observer.Observe('callee recref', RecRefSeen);
        Observer.Observe('callee', Described);
        Observer.Observe('caller after', CallerAfter);
        Observer.Expect('callee recref', 'rid=BVT Entry: 1 f={} n=4 view=VERSION(1) SORTING(Field1)');
        Observer.Expect('callee', 'id=1 f={} n=4 key=Entry No. asc=Yes grp=0 first=1');
        Observer.Expect('caller after', 'id=1 f={Item Code: ITEM-A, Location Code: BLUE} n=2 key=Item Code,Location Code sum=5');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_Group2Filter()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Buffer: Record "BVT Buffer";
    begin
        Initialize();
        SetGroupFilter(Entry, 2);
        Observer.Observe('callee', Buffer.DescribeEntry(Entry));
        Observer.Observe('callee groups', Buffer.GroupsOf(Entry));
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee', 'id=0 f={} n=4 key=Entry No. asc=Yes grp=0 first=1');
        Observer.Expect('callee groups', '-1={} 0={} 1={} 2={} 4={} n=4');
        Observer.Expect('caller after', 'f={} n=3 grp=0 key=Entry No. asc=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_Group4Filter()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Buffer: Record "BVT Buffer";
    begin
        Initialize();
        SetGroupFilter(Entry, 4);
        Observer.Observe('callee', Buffer.DescribeEntry(Entry));
        Observer.Observe('callee groups', Buffer.GroupsOf(Entry));
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee', 'id=0 f={} n=4 key=Entry No. asc=Yes grp=0 first=1');
        Observer.Expect('callee groups', '-1={} 0={} 1={} 2={} 4={} n=4');
        Observer.Expect('caller after', 'f={} n=3 grp=0 key=Entry No. asc=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_GroupMinus1Filter()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Buffer: Record "BVT Buffer";
    begin
        Initialize();
        SetGroupFilter(Entry, -1);
        Observer.Observe('callee', Buffer.DescribeEntry(Entry));
        Observer.Observe('callee groups', Buffer.GroupsOf(Entry));
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee', 'id=0 f={} n=4 key=Entry No. asc=Yes grp=0 first=1');
        Observer.Expect('callee groups', '-1={} 0={} 1={} 2={} 4={} n=4');
        Observer.Expect('caller after', 'f={} n=3 grp=0 key=Entry No. asc=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_CallerInGroup2_FilterInGroup2()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Buffer: Record "BVT Buffer";
    begin
        Initialize();
        Entry.FilterGroup(2);
        Entry.SetRange("Location Code", 'BLUE');
        Observer.Observe('callee', Buffer.DescribeEntry(Entry));
        Observer.Observe('callee groups', Buffer.GroupsOf(Entry));
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee', 'id=0 f={} n=4 key=Entry No. asc=Yes grp=0 first=1');
        Observer.Expect('callee groups', '-1={} 0={} 1={} 2={} 4={} n=4');
        Observer.Expect('caller after', 'f={Location Code: BLUE} n=3 grp=2 key=Entry No. asc=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_CallerInGroup2_FilterInGroup0()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Buffer: Record "BVT Buffer";
    begin
        Initialize();
        Entry.SetRange("Item Code", 'ITEM-A');
        Entry.FilterGroup(2);
        Observer.Observe('callee', Buffer.DescribeEntry(Entry));
        Observer.Observe('callee groups', Buffer.GroupsOf(Entry));
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee', 'id=0 f={} n=4 key=Entry No. asc=Yes grp=0 first=1');
        Observer.Expect('callee groups', '-1={} 0={} 1={} 2={} 4={} n=4');
        Observer.Expect('caller after', 'f={} n=3 grp=2 key=Entry No. asc=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_Descending_Group0Filter()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Buffer: Record "BVT Buffer";
    begin
        Initialize();
        Entry.Ascending(false);
        Entry.SetRange("Item Code", 'ITEM-A');
        Observer.Observe('callee', Buffer.DescribeEntry(Entry));
        Observer.Observe('callee view', Buffer.ViewOf(Entry));
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee', 'id=0 f={} n=4 key=Entry No. asc=Yes grp=0 first=1');
        Observer.Expect('callee view', 'VERSION(1) SORTING(Entry No.)');
        Observer.Expect('caller after', 'f={Item Code: ITEM-A} n=3 grp=0 key=Entry No. asc=No');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_Marks_MarkedOnlyOff()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Buffer: Record "BVT Buffer";
    begin
        Initialize();
        Entry.Get(2);
        Entry.Mark(true);
        Observer.Observe('callee marks', Buffer.MarksOf(Entry));
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee marks', 'mo=No n=4 marked n=0');
        Observer.Expect('caller after', 'f={} n=4 grp=0 key=Entry No. asc=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_Marks_MarkedOnlyOn()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Buffer: Record "BVT Buffer";
    begin
        Initialize();
        Entry.Get(2);
        Entry.Mark(true);
        Entry.MarkedOnly(true);
        Observer.Observe('callee marks', Buffer.MarksOf(Entry));
        Observer.Observe('callee', Buffer.DescribeEntry(Entry));
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee marks', 'mo=No n=4 marked n=0');
        Observer.Expect('callee', 'id=2 f={} n=4 key=Entry No. asc=Yes grp=0 first=1');
        Observer.Expect('caller after', 'f={Marked: Yes} n=1 grp=0 key=Entry No. asc=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_SetLoadFields()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Buffer: Record "BVT Buffer";
    begin
        Initialize();
        Entry.SetLoadFields("Item Code");
        Entry.SetRange("Item Code", 'ITEM-A');
        Observer.Observe('callee load', Buffer.LoadFieldsOf(Entry));
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee load', 'first=1 qty loaded=Yes item loaded=Yes');
        Observer.Expect('caller after', 'f={Item Code: ITEM-A} n=3 grp=0 key=Entry No. asc=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_SecondaryKey_NoFilter()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Buffer: Record "BVT Buffer";
    begin
        Initialize();
        Entry.SetCurrentKey("Item Code", "Location Code");
        Observer.Observe('callee', Buffer.DescribeEntry(Entry));
        Observer.Observe('callee view', Buffer.ViewOf(Entry));
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee', 'id=0 f={} n=4 key=Entry No. asc=Yes grp=0 first=1');
        Observer.Expect('callee view', 'VERSION(1) SORTING(Entry No.)');
        Observer.Expect('caller after', 'f={} n=4 grp=0 key=Item Code,Location Code asc=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_AdHocKey_Group0Filter()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Buffer: Record "BVT Buffer";
    begin
        Initialize();
        Entry.SetCurrentKey(Quantity);
        Entry.SetRange("Item Code", 'ITEM-A');
        Observer.Observe('callee', Buffer.DescribeEntry(Entry));
        Observer.Observe('callee view', Buffer.ViewOf(Entry));
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee', 'id=0 f={} n=4 key=Entry No. asc=Yes grp=0 first=1');
        Observer.Expect('callee view', 'VERSION(1) SORTING(Entry No.)');
        Observer.Expect('caller after', 'f={Item Code: ITEM-A} n=3 grp=0 key=Quantity asc=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_CalcFields_FlowFilterGroup0()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Buffer: Record "BVT Buffer";
    begin
        Initialize();
        Entry.Get(1);
        Entry.SetRange("Location Filter", 'RED');
        Observer.Observe('callee total', Buffer.TotalOf(Entry));
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee total', 'id=1 qty=10 f={}');
        Observer.Expect('caller after', 'f={Location Filter: RED} n=4 grp=0 key=Entry No. asc=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_RichView()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Buffer: Record "BVT Buffer";
    begin
        Initialize();
        Entry.SetCurrentKey("Item Code", "Location Code");
        Entry.Ascending(false);
        Entry.SetRange("Item Code", 'ITEM-A');
        Entry.SetRange("Location Filter", 'RED');
        Entry.FilterGroup(2);
        Entry.SetFilter(Quantity, '>%1', 1);
        Entry.FilterGroup(0);
        Entry.FindFirst();
        Entry.Mark(true);
        Observer.Observe('callee', Buffer.DescribeEntry(Entry));
        Observer.Observe('callee view', Buffer.ViewOf(Entry));
        Observer.Observe('callee groups', Buffer.GroupsOf(Entry));
        Observer.Observe('callee marks', Buffer.MarksOf(Entry));
        Observer.Observe('callee recref', Buffer.RecRefOf(Entry));
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee', 'id=3 f={} n=4 key=Entry No. asc=Yes grp=0 first=1');
        Observer.Expect('callee view', 'VERSION(1) SORTING(Entry No.)');
        Observer.Expect('callee groups', '-1={} 0={} 1={} 2={} 4={} n=4');
        Observer.Expect('callee marks', 'mo=No n=4 marked n=0');
        Observer.Expect('callee recref', 'rid=BVT Entry: 3 f={} n=4 view=VERSION(1) SORTING(Field1)');
        Observer.Expect('caller after', 'f={Item Code: ITEM-A, Location Filter: RED} n=3 grp=0 key=Item Code,Location Code asc=No');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_HandOn_Copy()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Buffer: Record "BVT Buffer";
    begin
        Initialize();
        Entry.SetCurrentKey("Item Code", "Location Code");
        Entry.SetRange("Item Code", 'ITEM-A');
        Entry.FindLast();
        Observer.Observe('callee copy', Buffer.CopyOf(Entry));
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee copy', 'id=3 f={} n=4 key=Entry No.');
        Observer.Expect('caller after', 'f={Item Code: ITEM-A} n=3 grp=0 key=Item Code,Location Code asc=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_NormalTable_Group0Filter()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Holder: Record "BVT Holder";
    begin
        Initialize();
        Entry.SetCurrentKey("Item Code", "Location Code");
        Entry.SetRange("Item Code", 'ITEM-A');
        Entry.FindFirst();
        Observer.Observe('callee', Holder.DescribeEntry(Entry));
        Observer.Observe('callee recref', Holder.RecRefOf(Entry));
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee', 'id=1 f={} n=4 key=Entry No. asc=Yes grp=0 first=1');
        Observer.Expect('callee recref', 'rid=BVT Entry: 1 f={} n=4 view=VERSION(1) SORTING(Field1)');
        Observer.Expect('caller after', 'f={Item Code: ITEM-A} n=3 grp=0 key=Item Code,Location Code asc=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_NormalTableTemporaryVariable_Group0Filter()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Holder: Record "BVT Holder" temporary;
    begin
        Initialize();
        Entry.SetCurrentKey("Item Code", "Location Code");
        Entry.SetRange("Item Code", 'ITEM-A');
        Entry.FindFirst();
        Observer.Observe('callee', Holder.DescribeEntry(Entry));
        Observer.Observe('callee recref', Holder.RecRefOf(Entry));
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee', 'id=1 f={} n=4 key=Entry No. asc=Yes grp=0 first=1');
        Observer.Expect('callee recref', 'rid=BVT Entry: 1 f={} n=4 view=VERSION(1) SORTING(Field1)');
        Observer.Expect('caller after', 'f={Item Code: ITEM-A} n=3 grp=0 key=Item Code,Location Code asc=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_FromTableProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Record "BVT Holder";
    begin
        Initialize();
        Observer.Observe('callee', Holder.CollectFromTable());
        Observer.Expect('callee', 'rid=BVT Entry: 1 f={} n=4 view=VERSION(1) SORTING(Field1) | id=1 f={} n=4 key=Entry No. asc=Yes grp=0 first=1');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_FromTableTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Record "BVT Holder";
    begin
        Initialize();
        Holder."Line No." := 1;
        Holder.Insert(true);
        Holder.Get(1);
        Observer.Observe('callee', Holder.Info);
        Observer.Expect('callee', 'id=0 f={} n=4 key=Entry No. asc=Yes grp=0 first=1');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_FlowFieldFilter()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Buffer: Record "BVT Buffer";
    begin
        Initialize();
        Entry.SetRange("Location Filter", 'BLUE');
        Entry.SetFilter("Item Qty", '>%1', 6);
        Observer.Observe('callee', Buffer.DescribeEntry(Entry));
        Observer.Observe('callee total', Buffer.TotalOf(Entry));
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee', 'id=0 f={} n=4 key=Entry No. asc=Yes grp=0 first=1');
        Observer.Expect('callee total', 'id=0 qty=0 f={}');
        Observer.Expect('caller after', 'f={Location Filter: BLUE, Item Qty: >6} n=1 grp=0 key=Entry No. asc=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_GlobalRecordSource()
    var
        Observer: Codeunit "Probe Observer";
        More: Codeunit "BVT More Callers";
    begin
        Initialize();
        Observer.Observe('callee', More.FromGlobal());
        Observer.Expect('callee', 'id=1 f={} n=4 key=Entry No. asc=Yes grp=0 first=1');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_VarParameterSource()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        More: Codeunit "BVT More Callers";
    begin
        Initialize();
        Entry.SetCurrentKey("Item Code", "Location Code");
        Entry.SetRange("Item Code", 'ITEM-A');
        Entry.FindLast();
        Observer.Observe('callee', More.FromVarParameter(Entry));
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee', 'id=3 f={} n=4 key=Entry No. asc=Yes grp=0 first=1');
        Observer.Expect('caller after', 'f={Item Code: ITEM-A} n=3 grp=0 key=Item Code,Location Code asc=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_CodeunitTableNoRec()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Log: Codeunit "BVT Log";
    begin
        Initialize();
        Entry.SetRange("Item Code", 'ITEM-A');
        Entry.FindFirst();
        Codeunit.Run(Codeunit::"BVT Entry Runner", Entry);
        Observer.Observe('callee', Log.Take());
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee', 'id=1 f={} n=4 key=Entry No. asc=Yes grp=0 first=1;');
        Observer.Expect('caller after', 'f={Item Code: ITEM-A} n=3 grp=0 key=Entry No. asc=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_FromEventSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "BVT Entry";
        Publisher: Codeunit "BVT Publisher";
        Log: Codeunit "BVT Log";
    begin
        Initialize();
        Entry.SetRange("Location Code", 'RED');
        Entry.FindFirst();
        Publisher.Raise(Entry);
        Observer.Observe('callee', Log.Take());
        ObserveCaller(Observer, Entry);
        Observer.Expect('callee', 'id=3 f={} n=4 key=Entry No. asc=Yes grp=0 first=1;');
        Observer.Expect('caller after', 'f={Location Code: RED} n=1 grp=0 key=Entry No. asc=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_FromOtherTableOnValidate()
    var
        Observer: Codeunit "Probe Observer";
        TriggerHolder: Record "BVT Trigger Holder";
        Log: Codeunit "BVT Log";
    begin
        Initialize();
        TriggerHolder."Line No." := 1;
        TriggerHolder.Insert();
        TriggerHolder.Validate(Mode, 1);
        Observer.Observe('callee', Log.Take());
        Observer.Expect('callee', 'validate id=3 f={} n=4 key=Entry No. asc=Yes grp=0 first=1;');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_FromOtherTableOnModify()
    var
        Observer: Codeunit "Probe Observer";
        TriggerHolder: Record "BVT Trigger Holder";
        Log: Codeunit "BVT Log";
    begin
        Initialize();
        TriggerHolder."Line No." := 1;
        TriggerHolder.Insert();
        TriggerHolder.Mode := 2;
        TriggerHolder.Modify(true);
        Observer.Observe('callee', Log.Take());
        Observer.Expect('callee', 'modify id=3 f={} n=4 key=Entry No. asc=Yes grp=0 first=1;');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueTableProc_OtherTable_FromOtherTableOnDelete()
    var
        Observer: Codeunit "Probe Observer";
        TriggerHolder: Record "BVT Trigger Holder";
        Log: Codeunit "BVT Log";
    begin
        Initialize();
        TriggerHolder."Line No." := 1;
        TriggerHolder.Insert();
        TriggerHolder.Delete(true);
        Observer.Observe('callee', Log.Take());
        Observer.Expect('callee', 'delete id=3 f={} n=4 key=Entry No. asc=Yes grp=0 first=1;');
        Observer.Verify();
    end;
}

// Added for the review of al-runner PR 8390: more callers of Buffer.Proc(Entry).
codeunit 78795 "BVT Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Value: Text)
    begin
        Log += Value + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

codeunit 78796 "BVT More Callers"
{
    var
        GlobalEntry: Record "BVT Entry";

    // A global record of the codeunit as the source.
    procedure FromGlobal(): Text
    var
        Buffer: Record "BVT Buffer";
    begin
        GlobalEntry.SetCurrentKey("Item Code", "Location Code");
        GlobalEntry.SetRange("Item Code", 'ITEM-A');
        GlobalEntry.FindFirst();
        exit(Buffer.DescribeEntry(GlobalEntry));
    end;

    // A var parameter as the source.
    procedure FromVarParameter(var E: Record "BVT Entry"): Text
    var
        Buffer: Record "BVT Buffer";
    begin
        exit(Buffer.DescribeEntry(E));
    end;

    // An event subscriber hands on the publisher's var parameter.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVT Publisher", 'OnEntry', '', false, false)]
    local procedure HandleEntry(var E: Record "BVT Entry")
    var
        Buffer: Record "BVT Buffer";
        Log: Codeunit "BVT Log";
    begin
        Log.Add(Buffer.DescribeEntry(E));
    end;
}

// Rec of a codeunit with TableNo as the source.
codeunit 78797 "BVT Entry Runner"
{
    TableNo = "BVT Entry";

    trigger OnRun()
    var
        Buffer: Record "BVT Buffer";
        Log: Codeunit "BVT Log";
    begin
        Log.Add(Buffer.DescribeEntry(Rec));
    end;
}

codeunit 78798 "BVT Publisher"
{
    procedure Raise(var E: Record "BVT Entry")
    begin
        OnEntry(E);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEntry(var E: Record "BVT Entry")
    begin
    end;
}

// OnValidate, OnModify and OnDelete of a third table call Buffer.Proc(Entry) on a filtered local record.
table 78799 "BVT Trigger Holder"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Mode; Integer)
        {
            trigger OnValidate()
            begin
                Describe('validate');
            end;
        }
    }

    keys { key(PK; "Line No.") { Clustered = true; } }

    trigger OnModify()
    begin
        Describe('modify');
    end;

    trigger OnDelete()
    begin
        Describe('delete');
    end;

    local procedure Describe(Name: Text)
    var
        Entry: Record "BVT Entry";
        Buffer: Record "BVT Buffer";
        Log: Codeunit "BVT Log";
    begin
        Entry.SetCurrentKey("Item Code", "Location Code");
        Entry.SetRange("Item Code", 'ITEM-A');
        Entry.FindLast();
        Log.Add(Name + ' ' + Buffer.DescribeEntry(Entry));
    end;
}
