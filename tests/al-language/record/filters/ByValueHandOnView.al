// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods/devenv-passing-parameters
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 89840..89853 (BVH Row, BVH Buffer, BVH Line, BVH Rows Report,
//   BVH Second Report, BVH Log, BVH Reader, BVH Copier, BVH Copy Subscriber, BVH RecRef Subscriber, BVH Batch, BVH Check Helper,
//   BVH Check Subscriber, BVH Hand On Tests)
// local object: what a by-value Record parameter holds of the caller's view, and what it hands on, in the shapes of Base Application
//   that pass such a copy along (al-runner issue 8973).
// Probe (al-runner issue 8973, follow-up of ByValueSubscriberView.al and ByValueTableProcedureView.al): one group per Base App shape.
//   - A: a field trigger (OnValidate) and the OnInsert/OnModify triggers (Insert(true), Modify(true)) of a table, and a non-trigger
//     procedure of that table, call a local procedure of the same table with Rec by value, as Proc(Rec) and as Rec.Proc(Rec)
//     (Base App table 7501 OnValidate -> CheckValueUniqueness(Rec, Value)). Caller views: none, a group-0 filter + FindFirst (Base
//     App shape), a secondary key with Ascending(false), SetAscending(Name, false), a filter in group 1, 2, 3, 4, -1, filters in
//     groups 5, 6 and 7, the caller standing in group 1, 2, 3, 4 and -1 (with its filter there), SetLoadFields + read, a marked row
//     with MarkedOnly, a rich view.
//   - E: a table procedure that gets a record of ANOTHER table by value, called from the callee table's own procedure and own
//     triggers (Base App table 175 ApplyStdCodesToPurchaseLines -> GetNextLineNo(PurchLine)), as Proc(X) and Rec.Proc(X); the local
//     record holds two group-0 SetRange + Init (Base App shape), no view, a secondary key descending, a group-2 filter, a current
//     row after FindFirst, SetLoadFields + read.
//   - B: a report IntegrationEvent(true, false) raised from OnAfterGetRecord with the data item (DataItemTableView with a secondary key
//     and two const filters, the caller's SetTableView filter in group 0); the subscriber reads its by-value copy (B1) and hands it by
//     var to a public procedure of the sender report, which does SetRecFilter, then SetTableView of a second report + RunModal (B2;
//     Base App report 5708 and codeunit 5995).
//   - C: a codeunit IntegrationEvent(false, false) with four parameters (var Line; Header; Line; Header; three by value) raised in a
//     FindSet loop over a local record with two group-0 SetRange, headers from Get (C1); a second subscriber does RecordRef.GetTable of
//     the by-value line and header (C2; Base App codeunits 87/86 and 1173).
//   - D: a codeunit's global record after Copy(Src), SetAutoCalcFields(), ReadIsolation(UpdLock) and two group-0 SetRange, its row set
//     by := in a loop, handed by value to a local procedure of the same codeunit; the copy goes by var into a table procedure that
//     raises an IncludeSender event; the subscriber does sender -> Variant -> RecordRef.GetTable (Base App codeunit 23, table 83,
//     codeunit 1550). Neighbors: no ReadIsolation, ReadCommitted, SetAutoCalcFields(Total).
//   The reader (BVH Reader.Describe) gets the record by var and reads: AreFieldsLoaded(Name) first, temp, same company, the filters of
//   every group -1..7 that has one, the filter group, Count, key, order, MarkedOnly, marked count, ReadIsolation, the FlowFilter, the
//   current Id and Name, the FlowField Total after CalcFields; GetView next to it. BVH Reader.Light reads a report data item without
//   Count, marks or CalcFields.
// Facts (observed, same on 27.5, 28.5 and 29.0; see the Expect lines):
//   - In every group the by-value copy (copy, subscriber, hand on, sender) holds the caller's group-1 filter and row set, but its view
//     is the plain primary-key view: no group-0 filter, no secondary key, no descending order, no marks, no filter in group 2 or higher,
//     no rows of the caller's group-0 view (Count 4 when the caller's group-0 filter had 3).
//   - A: inside the table's own triggers and procedures, Rec keeps the caller's view in full (group-0 filter, key, order, group 2+
//     filters, marks, FlowFilter), and the caller's view is unchanged afterwards. The copy handed to Proc(Rec) and Rec.Proc(Rec) is
//     view-less. The caller's filter group (-1..4) is kept on Rec.
//   - E: a record of another table that is a local of the callee procedure reaches Proc(X) view-less (key Id, no group-0 filter), and the
//     local record keeps its own view after the call.
//   - B: the report data item keeps its view; the subscriber copy is view-less; the hand-on to a var parameter stays view-less until the
//     sender sets SetRecFilter, which then stands in group 0 (Id=1); the second report's SetTableView sees that filter.
//   - C: in the four-parameter event the by-value Line and Header are view-less (group-1 filter kept, key Id), the RecordRef from
//     GetTable has no filters and the row of the by-value record.
//   - D: a global record after Copy, SetAutoCalcFields and ReadIsolation: the copy is view-less with ReadIsolation Default whatever the
//     global's isolation (UpdLock, ReadCommitted, none); the global keeps its isolation and group-0 view; the FlowField is 0 with or
//     without SetAutoCalcFields(Total).
// BC versions: 27.5, 28.5, 29.0

table 89840 "BVH Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
        field(3; Status; Option) { OptionMembers = Open,Posted; }
        field(4; Amount; Decimal) { }
        field(5; Total; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("BVH Line".Amt where(RowId = field(Id), Day = field("Day Filter")));
        }
        field(6; "Day Filter"; Integer) { FieldClass = FlowFilter; }
        field(7; Flag; Boolean) { }
        field(8; Mode; Integer) { }
        field(9; Code; Code[10])
        {
            trigger OnValidate()
            begin
                if Mode = 0 then
                    exit;
                if Mode = 1 then
                    CheckValue(Rec, 'copy')
                else
                    Rec.CheckValueRec(Rec, 'copy');
                Reader.Record('trigger rec', Rec);
            end;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByName; Name) { }
    }

    var
        Reader: Codeunit "BVH Reader";

    trigger OnInsert()
    begin
        if Mode = 0 then
            exit;
        if Mode = 1 then
            CheckValue(Rec, 'copy')
        else
            Rec.CheckValueRec(Rec, 'copy');
        Reader.Record('trigger rec', Rec);
    end;

    trigger OnModify()
    begin
        if Mode = 0 then
            exit;
        if Mode = 1 then
            CheckValue(Rec, 'copy')
        else
            Rec.CheckValueRec(Rec, 'copy');
        Reader.Record('trigger rec', Rec);
    end;

    procedure CallOwn()
    begin
        if Mode = 1 then
            CheckValue(Rec, 'copy')
        else
            Rec.CheckValueRec(Rec, 'copy');
        Reader.Record('trigger rec', Rec);
    end;

    local procedure CheckValue(R: Record "BVH Row"; Slot: Text)
    begin
        Reader.Record(Slot, R);
    end;

    // Rec.Proc(Rec) of a local procedure gives AL0161 under runtime 16.1 and 17.1 (BC 27, 28), so the Rec. form calls an internal one.
    internal procedure CheckValueRec(R: Record "BVH Row"; Slot: Text)
    begin
        Reader.Record(Slot, R);
    end;

    procedure RaiseCheck()
    begin
        OnCheckSender();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCheckSender()
    begin
    end;
}

table 89841 "BVH Buffer"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Mode; Integer) { }
        field(3; Code; Code[10])
        {
            trigger OnValidate()
            var
                Row: Record "BVH Row";
            begin
                Row.SetRange(Status, Row.Status::Open);
                Row.SetRange(Flag, true);
                Row.Init();
                if Mode = 1 then
                    GetNext(Row)
                else
                    Rec.GetNext(Row);
                Reader.Record('local after', Row);
            end;
        }
    }

    keys { key(PK; Id) { Clustered = true; } }

    var
        Reader: Codeunit "BVH Reader";

    trigger OnInsert()
    var
        Row: Record "BVH Row";
    begin
        Row.SetRange(Status, Row.Status::Open);
        Row.SetRange(Flag, true);
        Row.Init();
        if Mode = 1 then
            GetNext(Row)
        else
            Rec.GetNext(Row);
        Reader.Record('local after', Row);
    end;

    // Shape 0: two group-0 SetRange + Init (Base App); 1: no view; 2: key ByName descending + group-0 filter; 3: a filter in group 2;
    // 4: two group-0 SetRange + FindFirst (current row 1); 5: SetLoadFields(Id) + Get(1).
    procedure ApplyLines(Shape: Integer)
    var
        Row: Record "BVH Row";
    begin
        case Shape of
            0:
                begin
                    Row.SetRange(Status, Row.Status::Open);
                    Row.SetRange(Flag, true);
                    Row.Init();
                end;
            1:
                ;
            2:
                begin
                    Row.SetCurrentKey(Name);
                    Row.Ascending(false);
                    Row.SetRange(Status, Row.Status::Open);
                end;
            3:
                begin
                    Row.FilterGroup(2);
                    Row.SetFilter(Amount, '>15');
                    Row.FilterGroup(0);
                end;
            4:
                begin
                    Row.SetRange(Status, Row.Status::Open);
                    Row.SetRange(Flag, true);
                    Row.FindFirst();
                end;
            5:
                begin
                    Row.SetLoadFields(Id);
                    Row.Get(1);
                end;
        end;
        if Mode = 1 then
            GetNext(Row)
        else
            Rec.GetNext(Row);
        Reader.Record('local after', Row);
    end;

    procedure GetNext(R: Record "BVH Row")
    begin
        Reader.Record('copy', R);
    end;
}

table 89842 "BVH Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; RowId; Integer) { }
        field(3; Day; Integer) { }
        field(4; Amt; Decimal) { }
        field(5; Kind; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByRow; RowId, Day) { }
    }
}

report 89843 "BVH Rows Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "BVH Row")
        {
            DataItemTableView = sorting(Name) where(Status = const(Open), Flag = const(true));

            trigger OnAfterGetRecord()
            var
                Reader: Codeunit "BVH Reader";
            begin
                Reader.Light('item', Row);
                OnRowAfterGet(Row);
            end;
        }
    }

    procedure HandOn(var R: Record "BVH Row")
    var
        Reader: Codeunit "BVH Reader";
        Second: Report "BVH Second Report";
    begin
        Reader.Record('hand on', R);
        R.SetRecFilter();
        Reader.Record('after setrecfilter', R);
        Second.SetTableView(R);
        Second.UseRequestPage(false);
        Second.RunModal();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnRowAfterGet(R: Record "BVH Row")
    begin
    end;
}

report 89844 "BVH Second Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(R2; "BVH Row")
        {
            trigger OnPreDataItem()
            var
                Reader: Codeunit "BVH Reader";
            begin
                Reader.Record('second item', R2);
            end;

            trigger OnAfterGetRecord()
            var
                Log: Codeunit "BVH Log";
            begin
                Log.Put('second rows', Format(R2.Id));
            end;
        }
    }
}

codeunit 89845 "BVH Log"
{
    SingleInstance = true;

    var
        Entries: Dictionary of [Text, Text];

    procedure Put(Slot: Text; Value: Text)
    var
        Old: Text;
    begin
        if Entries.Get(Slot, Old) then
            Entries.Set(Slot, Old + ' | ' + Value)
        else
            Entries.Add(Slot, Value);
    end;

    procedure Take(Slot: Text): Text
    var
        Value: Text;
    begin
        if not Entries.Get(Slot, Value) then
            exit('(not raised)');
        Entries.Remove(Slot);
        exit(Value);
    end;

    procedure Reset()
    begin
        Clear(Entries);
    end;
}

codeunit 89846 "BVH Reader"
{
    // Reads the record it is given by var, so it reads the caller's own record. Leaves MarkedOnly and the filter group as it found them.
    procedure Describe(var R: Record "BVH Row"): Text
    var
        Other: Record "BVH Row";
        Result: Text;
        Group: Integer;
        WasMarkedOnly: Boolean;
    begin
        Result := 'ld=' + Format(R.AreFieldsLoaded(Name));
        Group := R.FilterGroup();
        WasMarkedOnly := R.MarkedOnly();
        Result += ' temp=' + Format(R.IsTemporary()) + ' same=' + Format(R.CurrentCompany() = CompanyName());
        Result += ' gs={' + Groups(R) + '}';
        R.FilterGroup(Group);
        Result += ' grp=' + Format(Group) + ' n=' + Format(R.Count()) + ' key=' + R.CurrentKey() + ' asc=' + Format(R.Ascending());
        Result += ' iso=' + Format(R.ReadIsolation());
        Result += ' mo=' + Format(WasMarkedOnly);
        R.MarkedOnly(true);
        Result += ' m=' + Format(R.Count());
        R.MarkedOnly(WasMarkedOnly);
        R.CopyFilter("Day Filter", Other."Day Filter");
        Result += ' ff={' + R.GetFilter("Day Filter") + '} cf={' + Other.GetFilters() + '}';
        R.CalcFields(Total);
        exit(Result + ' id=' + Format(R.Id) + ' name=' + R.Name + ' total=' + Format(R.Total));
    end;

    // Every filter group -1..7 that holds a filter, as 'group:filters;'. Leaves the record in filter group 0; callers restore.
    local procedure Groups(var R: Record "BVH Row"): Text
    var
        G: Integer;
        Result: Text;
    begin
        for G := -1 to 7 do begin
            R.FilterGroup(G);
            if R.GetFilters() <> '' then
                Result += Format(G) + ':' + R.GetFilters() + ';';
        end;
        R.FilterGroup(0);
        exit(Result);
    end;

    procedure Record(Slot: Text; var R: Record "BVH Row")
    var
        Log: Codeunit "BVH Log";
    begin
        Log.Put(Slot, Describe(R));
        Log.Put(Slot + ' view', R.GetView());
    end;

    // For a report data item while it loops: no Count, marks or CalcFields.
    procedure Light(Slot: Text; var R: Record "BVH Row")
    var
        Log: Codeunit "BVH Log";
        Group: Integer;
        Result: Text;
    begin
        Group := R.FilterGroup();
        Result := 'gs={' + Groups(R) + '}';
        R.FilterGroup(Group);
        Log.Put(Slot, Result + ' grp=' + Format(Group) + ' key=' + R.CurrentKey() + ' id=' + Format(R.Id) + ' name=' + R.Name);
        Log.Put(Slot + ' view', R.GetView());
    end;

    procedure RecordLine(Slot: Text; var L: Record "BVH Line")
    var
        Log: Codeunit "BVH Log";
        G: Integer;
        Group: Integer;
        Result: Text;
    begin
        Group := L.FilterGroup();
        for G := -1 to 7 do begin
            L.FilterGroup(G);
            if L.GetFilters() <> '' then
                Result += Format(G) + ':' + L.GetFilters() + ';';
        end;
        L.FilterGroup(Group);
        Log.Put(Slot, 'temp=' + Format(L.IsTemporary()) + ' gs={' + Result + '} grp=' + Format(Group) + ' n=' + Format(L.Count()) +
            ' key=' + L.CurrentKey() + ' asc=' + Format(L.Ascending()) + ' iso=' + Format(L.ReadIsolation()) +
            ' id=' + Format(L.Id) + ' rowid=' + Format(L.RowId) + ' kind=' + Format(L.Kind));
        Log.Put(Slot + ' view', L.GetView());
    end;

    procedure RecRefFacts(Slot: Text; var RecRef: RecordRef)
    var
        Log: Codeunit "BVH Log";
    begin
        Log.Put(Slot, 'temp=' + Format(RecRef.IsTemporary()) + ' f={' + RecRef.GetFilters() + '} n=' + Format(RecRef.Count()) +
            ' rid=' + Format(RecRef.RecordId()) + ' f1=' + Format(RecRef.Field(1).Value()) + ' f2=' + Format(RecRef.Field(2).Value()) +
            ' iso=' + Format(RecRef.ReadIsolation()));
        Log.Put(Slot + ' view', RecRef.GetView());
    end;
}

codeunit 89847 "BVH Copier"
{
    // Base App codeunit 87 shape: a FindSet loop over a local line record with two group-0 SetRange; headers from Get.
    procedure Run(Rich: Boolean)
    var
        Header: Record "BVH Row";
        NewHeader: Record "BVH Row";
        Line: Record "BVH Line";
        NewLine: Record "BVH Line";
    begin
        Header.Get(1);
        NewHeader.Get(2);
        Line.SetRange(RowId, 1);
        Line.SetRange(Kind, 1);
        if Rich then begin
            Line.SetCurrentKey(RowId, Day);
            Line.Ascending(false);
            Line.FilterGroup(2);
            Line.SetFilter(Amt, '>1');
            Line.FilterGroup(0);
        end;
        if Line.FindSet() then
            repeat
                NewLine.Init();
                NewLine.Id := Line.Id + 100;
                NewLine.RowId := 2;
                NewLine.Kind := Line.Kind;
                NewLine.Insert();
                OnAfterInsertLine(NewLine, NewHeader, Line, Header);
            until Line.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertLine(var NewLine: Record "BVH Line"; NewHeader: Record "BVH Row"; OldLine: Record "BVH Line"; OldHeader: Record "BVH Row")
    begin
    end;
}

codeunit 89848 "BVH Copy Subscriber"
{
    var
        Reader: Codeunit "BVH Reader";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVH Copier", 'OnAfterInsertLine', '', false, false)]
    local procedure HandleAfterInsertLine(var NewLine: Record "BVH Line"; NewHeader: Record "BVH Row"; OldLine: Record "BVH Line"; OldHeader: Record "BVH Row")
    begin
        Reader.RecordLine('new line', NewLine);
        Reader.RecordLine('old line', OldLine);
        Reader.Record('new header', NewHeader);
        Reader.Record('old header', OldHeader);
    end;
}

codeunit 89849 "BVH RecRef Subscriber"
{
    var
        Reader: Codeunit "BVH Reader";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVH Copier", 'OnAfterInsertLine', '', false, false)]
    local procedure HandleAfterInsertLine(var NewLine: Record "BVH Line"; NewHeader: Record "BVH Row"; OldLine: Record "BVH Line"; OldHeader: Record "BVH Row")
    var
        LineRef: RecordRef;
        HeaderRef: RecordRef;
    begin
        LineRef.GetTable(OldLine);
        Reader.RecRefFacts('line ref', LineRef);
        HeaderRef.GetTable(OldHeader);
        Reader.RecRefFacts('header ref', HeaderRef);
    end;

    [EventSubscriber(ObjectType::Report, Report::"BVH Rows Report", 'OnRowAfterGet', '', false, false)]
    local procedure HandleRowAfterGet(var Sender: Report "BVH Rows Report"; R: Record "BVH Row")
    begin
        Reader.Record('subscriber', R);
        Sender.HandOn(R);
        Reader.Record('subscriber after', R);
    end;
}

codeunit 89850 "BVH Batch"
{
    var
        GRow: Record "BVH Row";
        Reader: Codeunit "BVH Reader";
        Log: Codeunit "BVH Log";

    // Base App codeunit 23 shape. Iso: 0 none, 1 UpdLock, 2 ReadCommitted. AutoCalc: 0 SetAutoCalcFields(), 1 SetAutoCalcFields(Total).
    procedure Post(var Src: Record "BVH Row"; Iso: Integer; AutoCalc: Integer)
    var
        Other: Record "BVH Row";
    begin
        GRow.Copy(Src);
        if AutoCalc = 0 then
            GRow.SetAutoCalcFields()
        else
            GRow.SetAutoCalcFields(Total);
        case Iso of
            1:
                GRow.ReadIsolation(IsolationLevel::UpdLock);
            2:
                GRow.ReadIsolation(IsolationLevel::ReadCommitted);
        end;
        GRow.SetRange(Status, GRow.Status::Open);
        GRow.SetRange(Flag, true);
        Other.SetRange(Status, Other.Status::Open);
        Other.SetRange(Flag, true);
        if Other.FindSet() then
            repeat
                GRow := Other;
                SumLine(GRow);
            until Other.Next() = 0;
        Reader.Record('global after', GRow);
    end;

    local procedure SumLine(R: Record "BVH Row")
    var
        Helper: Codeunit "BVH Check Helper";
    begin
        Log.Put('total before find', Format(R.Total));
        Log.Put('find', Format(R.Find('=')));
        Log.Put('total after find', Format(R.Total));
        Reader.Record('copy', R);
        Helper.CheckVar(R);
    end;
}

codeunit 89851 "BVH Check Helper"
{
    procedure CheckVar(var R: Record "BVH Row")
    begin
        R.RaiseCheck();
    end;
}

codeunit 89852 "BVH Check Subscriber"
{
    var
        Reader: Codeunit "BVH Reader";

    [EventSubscriber(ObjectType::Table, Database::"BVH Row", 'OnCheckSender', '', false, false)]
    local procedure HandleCheckSender(var Sender: Record "BVH Row")
    var
        RecRef: RecordRef;
        V: Variant;
    begin
        Reader.Record('sender', Sender);
        V := Sender;
        RecRef.GetTable(V);
        Reader.RecRefFacts('sender ref', RecRef);
    end;
}

codeunit 89853 "BVH Hand On Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Reader: Codeunit "BVH Reader";
        Log: Codeunit "BVH Log";

    // Rows 1 (C-NAME, Open, 30, Flag), 2 (B-NAME, Posted, 20, Flag), 3 (A-NAME, Open, 10, Flag), 4 (D-NAME, Open, 40, no Flag).
    // Lines: 1 (row 1, day 1, 5, kind 1), 2 (row 1, day 2, 7, kind 1), 3 (row 1, day 1, 3, kind 2).
    local procedure Seed()
    var
        Row: Record "BVH Row";
        Line: Record "BVH Line";
        Buffer: Record "BVH Buffer";
    begin
        Row.DeleteAll();
        Line.DeleteAll();
        Buffer.DeleteAll();
        AddRow(1, 'C-NAME', 0, 30, true);
        AddRow(2, 'B-NAME', 1, 20, true);
        AddRow(3, 'A-NAME', 0, 10, true);
        AddRow(4, 'D-NAME', 0, 40, false);
        AddLine(1, 1, 1, 5, 1);
        AddLine(2, 1, 2, 7, 1);
        AddLine(3, 1, 1, 3, 2);
        Log.Reset();
    end;

    local procedure AddRow(Id: Integer; Name: Text[20]; Status: Option; Amount: Decimal; Flag: Boolean)
    var
        Row: Record "BVH Row";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Name := Name;
        Row.Status := Status;
        Row.Amount := Amount;
        Row.Flag := Flag;
        Row.Insert();
    end;

    local procedure AddLine(Id: Integer; RowId: Integer; Day: Integer; Amt: Decimal; Kind: Integer)
    var
        Line: Record "BVH Line";
    begin
        Line.Id := Id;
        Line.RowId := RowId;
        Line.Day := Day;
        Line.Amt := Amt;
        Line.Kind := Kind;
        Line.Insert();
    end;

    local procedure ObserveSlot(var Observer: Codeunit "Probe Observer"; Slot: Text)
    begin
        Observer.Observe(Slot, Log.Take(Slot));
        Observer.Observe(Slot + ' view', Log.Take(Slot + ' view'));
    end;

    local procedure ObserveCaller(var Observer: Codeunit "Probe Observer"; var Row: Record "BVH Row")
    begin
        Observer.Observe('caller after', Reader.Describe(Row));
        Observer.Observe('caller after view', Row.GetView());
    end;

    // Group A: validate Code with Mode 1 (Proc(Rec)) or 2 (Rec.Proc(Rec)) on row 1 after the view is set; observe copy, trigger rec, caller.
    local procedure ValidateRow1(var Observer: Codeunit "Probe Observer"; var Row: Record "BVH Row"; Mode: Integer)
    begin
        Row.Mode := Mode;
        Row.Validate(Code, 'X');
        ObserveSlot(Observer, 'copy');
        ObserveSlot(Observer, 'trigger rec');
        ObserveCaller(Observer, Row);
    end;

    [Test]
    procedure A_Validate_Proc_Group0FindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
    begin
        Seed();
        Row.SetRange(Status, Row.Status::Open);
        Row.FindFirst();
        ValidateRow1(Observer, Row, 1);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={} grp=0 n=4 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={0:Status: Open;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open))');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={0:Status: Open;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open))');
        Observer.Verify();
    end;

    [Test]
    procedure A_Validate_RecProc_Group0FindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
    begin
        Seed();
        Row.SetRange(Status, Row.Status::Open);
        Row.FindFirst();
        ValidateRow1(Observer, Row, 2);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={} grp=0 n=4 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={0:Status: Open;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open))');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={0:Status: Open;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open))');
        Observer.Verify();
    end;

    [Test]
    procedure A_Insert_Proc_Group0FindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
    begin
        Seed();
        Row.SetRange(Status, Row.Status::Open);
        Row.FindFirst();
        Row.Id := 9;
        Row.Name := 'NEW';
        Row.Mode := 1;
        Row.Insert(true);
        ObserveSlot(Observer, 'copy');
        ObserveSlot(Observer, 'trigger rec');
        ObserveCaller(Observer, Row);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={} grp=0 n=4 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=9 name=NEW total=0');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={0:Status: Open;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=9 name=NEW total=0');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open))');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={0:Status: Open;} grp=0 n=4 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=9 name=NEW total=0');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open))');
        Observer.Verify();
    end;

    [Test]
    procedure A_Insert_RecProc_Group0FindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
    begin
        Seed();
        Row.SetRange(Status, Row.Status::Open);
        Row.FindFirst();
        Row.Id := 9;
        Row.Name := 'NEW';
        Row.Mode := 2;
        Row.Insert(true);
        ObserveSlot(Observer, 'copy');
        ObserveSlot(Observer, 'trigger rec');
        ObserveCaller(Observer, Row);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={} grp=0 n=4 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=9 name=NEW total=0');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={0:Status: Open;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=9 name=NEW total=0');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open))');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={0:Status: Open;} grp=0 n=4 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=9 name=NEW total=0');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open))');
        Observer.Verify();
    end;

    [Test]
    procedure A_Modify_Proc_Group0FindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
    begin
        Seed();
        Row.SetRange(Status, Row.Status::Open);
        Row.FindFirst();
        Row.Mode := 1;
        Row.Modify(true);
        ObserveSlot(Observer, 'copy');
        ObserveSlot(Observer, 'trigger rec');
        ObserveCaller(Observer, Row);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={} grp=0 n=4 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={0:Status: Open;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open))');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={0:Status: Open;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open))');
        Observer.Verify();
    end;

    [Test]
    procedure A_Modify_RecProc_Group0FindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
    begin
        Seed();
        Row.SetRange(Status, Row.Status::Open);
        Row.FindFirst();
        Row.Mode := 2;
        Row.Modify(true);
        ObserveSlot(Observer, 'copy');
        ObserveSlot(Observer, 'trigger rec');
        ObserveCaller(Observer, Row);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={} grp=0 n=4 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={0:Status: Open;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open))');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={0:Status: Open;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open))');
        Observer.Verify();
    end;

    [Test]
    procedure A_OwnProcedure_Proc_Group0FindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
    begin
        Seed();
        Row.SetRange(Status, Row.Status::Open);
        Row.FindFirst();
        Row.Mode := 1;
        Row.CallOwn();
        ObserveSlot(Observer, 'copy');
        ObserveSlot(Observer, 'trigger rec');
        ObserveCaller(Observer, Row);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={} grp=0 n=4 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={0:Status: Open;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open))');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={0:Status: Open;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open))');
        Observer.Verify();
    end;

    [Test]
    procedure A_OwnProcedure_RecProc_Group0FindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
    begin
        Seed();
        Row.SetRange(Status, Row.Status::Open);
        Row.FindFirst();
        Row.Mode := 2;
        Row.CallOwn();
        ObserveSlot(Observer, 'copy');
        ObserveSlot(Observer, 'trigger rec');
        ObserveCaller(Observer, Row);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={} grp=0 n=4 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={0:Status: Open;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open))');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={0:Status: Open;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open))');
        Observer.Verify();
    end;

    [Test]
    procedure A_Validate_Proc_NoView()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
    begin
        Seed();
        Row.Get(1);
        ValidateRow1(Observer, Row, 1);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={} grp=0 n=4 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={} grp=0 n=4 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={} grp=0 n=4 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id)');
        Observer.Verify();
    end;

    [Test]
    procedure A_Validate_Proc_SecondaryKeyDescending()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
    begin
        Seed();
        Row.SetCurrentKey(Name);
        Row.Ascending(false);
        Row.SetRange(Status, Row.Status::Open);
        Row.Get(1);
        ValidateRow1(Observer, Row, 1);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={} grp=0 n=4 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={0:Status: Open;} grp=0 n=3 key=Name asc=No iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Status=FILTER(Open))');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={0:Status: Open;} grp=0 n=3 key=Name asc=No iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Status=FILTER(Open))');
        Observer.Verify();
    end;

    [Test]
    procedure A_Validate_Proc_SetAscendingField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
    begin
        Seed();
        Row.SetCurrentKey(Name);
        Row.SetAscending(Name, false);
        Row.Get(1);
        ValidateRow1(Observer, Row, 1);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={} grp=0 n=4 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={} grp=0 n=4 key=Name asc=No iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Name) ORDER(Descending)');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={} grp=0 n=4 key=Name asc=No iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Name) ORDER(Descending)');
        Observer.Verify();
    end;

    [Test]
    procedure A_Validate_Proc_Group1Filter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
    begin
        Seed();
        Row.FilterGroup(1);
        Row.SetFilter(Amount, '>15');
        Row.FilterGroup(0);
        Row.Get(1);
        ValidateRow1(Observer, Row, 1);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id)');
        Observer.Verify();
    end;

    [Test]
    procedure A_Validate_Proc_Group2Filter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
    begin
        Seed();
        Row.FilterGroup(2);
        Row.SetFilter(Amount, '>15');
        Row.FilterGroup(0);
        Row.Get(1);
        ValidateRow1(Observer, Row, 1);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;2:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;2:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id)');
        Observer.Verify();
    end;

    [Test]
    procedure A_Validate_Proc_Group3Filter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
    begin
        Seed();
        Row.FilterGroup(3);
        Row.SetFilter(Amount, '>15');
        Row.FilterGroup(0);
        Row.Get(1);
        ValidateRow1(Observer, Row, 1);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;3:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;3:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id)');
        Observer.Verify();
    end;

    [Test]
    procedure A_Validate_Proc_Group4Filter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
    begin
        Seed();
        Row.FilterGroup(4);
        Row.SetFilter(Amount, '>15');
        Row.FilterGroup(0);
        Row.Get(1);
        ValidateRow1(Observer, Row, 1);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;4:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;4:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id)');
        Observer.Verify();
    end;

    [Test]
    procedure A_Validate_Proc_GroupMinus1Filter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
    begin
        Seed();
        Row.FilterGroup(-1);
        Row.SetFilter(Amount, '>15');
        Row.FilterGroup(0);
        Row.Get(1);
        ValidateRow1(Observer, Row, 1);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={-1:Amount: >15;1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={-1:Amount: >15;1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id)');
        Observer.Verify();
    end;

    [Test]
    procedure A_Validate_Proc_Groups567Filters()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
    begin
        Seed();
        Row.FilterGroup(5);
        Row.SetFilter(Amount, '>5');
        Row.FilterGroup(6);
        Row.SetRange(Flag, true);
        Row.FilterGroup(7);
        Row.SetRange(Status, Row.Status::Open);
        Row.FilterGroup(0);
        Row.Get(1);
        ValidateRow1(Observer, Row, 1);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;5:Amount: >5;6:Flag: Yes;7:Status: Open;} grp=0 n=1 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;5:Amount: >5;6:Flag: Yes;7:Status: Open;} grp=0 n=1 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id)');
        Observer.Verify();
    end;

    local procedure CallerInGroup(var Observer: Codeunit "Probe Observer"; Group: Integer)
    var
        Row: Record "BVH Row";
    begin
        Seed();
        Row.FilterGroup(Group);
        Row.SetFilter(Amount, '>15');
        Row.Get(1);
        ValidateRow1(Observer, Row, 1);
    end;

    [Test]
    procedure A_Validate_Proc_CallerInGroup1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CallerInGroup(Observer, 1);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=1 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id) WHERE(Amount=FILTER(>15))');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=1 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id) WHERE(Amount=FILTER(>15))');
        Observer.Verify();
    end;

    [Test]
    procedure A_Validate_Proc_CallerInGroup2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CallerInGroup(Observer, 2);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;2:Amount: >15;} grp=2 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id) WHERE(Amount=FILTER(>15))');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;2:Amount: >15;} grp=2 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id) WHERE(Amount=FILTER(>15))');
        Observer.Verify();
    end;

    [Test]
    procedure A_Validate_Proc_CallerInGroup3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CallerInGroup(Observer, 3);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;3:Amount: >15;} grp=3 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id) WHERE(Amount=FILTER(>15))');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;3:Amount: >15;} grp=3 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id) WHERE(Amount=FILTER(>15))');
        Observer.Verify();
    end;

    [Test]
    procedure A_Validate_Proc_CallerInGroup4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CallerInGroup(Observer, 4);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;4:Amount: >15;} grp=4 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id) WHERE(Amount=FILTER(>15))');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;4:Amount: >15;} grp=4 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id) WHERE(Amount=FILTER(>15))');
        Observer.Verify();
    end;

    [Test]
    procedure A_Validate_Proc_CallerInGroupMinus1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CallerInGroup(Observer, -1);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={-1:Amount: >15;1:Amount: >15;} grp=-1 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id) WHERE(Amount=FILTER(>15))');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={-1:Amount: >15;1:Amount: >15;} grp=-1 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id) WHERE(Amount=FILTER(>15))');
        Observer.Verify();
    end;

    [Test]
    procedure A_Validate_Proc_SetLoadFieldsRead()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
    begin
        Seed();
        Row.SetLoadFields(Id, Mode);
        Row.Get(1);
        ValidateRow1(Observer, Row, 1);
        Observer.Expect('copy', 'ld=No temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=No temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id)');
        Observer.Verify();
    end;

    [Test]
    procedure A_Validate_Proc_MarkedOnly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
    begin
        Seed();
        Row.Get(3);
        Row.Mark(true);
        Row.Get(1);
        Row.Mark(true);
        Row.MarkedOnly(true);
        ValidateRow1(Observer, Row, 1);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={-1:Marked: Yes;0:Marked: Yes;1:Marked: Yes, Amount: >15;2:Marked: Yes;3:Marked: Yes;4:Marked: Yes;5:Marked: Yes;6:Marked: Yes;7:Marked: Yes;} grp=0 n=1 key=Id asc=Yes iso=Default mo=Yes m=1 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={-1:Marked: Yes;0:Marked: Yes;1:Marked: Yes, Amount: >15;2:Marked: Yes;3:Marked: Yes;4:Marked: Yes;5:Marked: Yes;6:Marked: Yes;7:Marked: Yes;} grp=0 n=1 key=Id asc=Yes iso=Default mo=Yes m=1 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Id)');
        Observer.Verify();
    end;

    // Key ByName descending, Status = Open and Day Filter = 1 in group 0, Amount > 15 in group 2, current row 1, row 1 marked.
    local procedure SetRichView(var Row: Record "BVH Row")
    begin
        Row.SetCurrentKey(Name);
        Row.Ascending(false);
        Row.SetRange(Status, Row.Status::Open);
        Row.SetFilter("Day Filter", '1');
        Row.FilterGroup(2);
        Row.SetFilter(Amount, '>15');
        Row.FilterGroup(0);
        Row.Get(1);
        Row.Mark(true);
    end;

    [Test]
    procedure A_Validate_Proc_RichView()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
    begin
        Seed();
        SetRichView(Row);
        ValidateRow1(Observer, Row, 1);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={0:Status: Open, Day Filter: 1;1:Amount: >15;2:Amount: >15;} grp=0 n=2 key=Name asc=No iso=Default mo=No m=1 ff={1} cf={Day Filter: 1} id=1 name=C-NAME total=8');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Status=FILTER(Open),Day Filter=FILTER(1))');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={0:Status: Open, Day Filter: 1;1:Amount: >15;2:Amount: >15;} grp=0 n=2 key=Name asc=No iso=Default mo=No m=1 ff={1} cf={Day Filter: 1} id=1 name=C-NAME total=8');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Status=FILTER(Open),Day Filter=FILTER(1))');
        Observer.Verify();
    end;

    [Test]
    procedure A_Validate_RecProc_RichView()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
    begin
        Seed();
        SetRichView(Row);
        ValidateRow1(Observer, Row, 2);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('trigger rec', 'ld=Yes temp=No same=Yes gs={0:Status: Open, Day Filter: 1;1:Amount: >15;2:Amount: >15;} grp=0 n=2 key=Name asc=No iso=Default mo=No m=1 ff={1} cf={Day Filter: 1} id=1 name=C-NAME total=8');
        Observer.Expect('trigger rec view', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Status=FILTER(Open),Day Filter=FILTER(1))');
        Observer.Expect('caller after', 'ld=Yes temp=No same=Yes gs={0:Status: Open, Day Filter: 1;1:Amount: >15;2:Amount: >15;} grp=0 n=2 key=Name asc=No iso=Default mo=No m=1 ff={1} cf={Day Filter: 1} id=1 name=C-NAME total=8');
        Observer.Expect('caller after view', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Status=FILTER(Open),Day Filter=FILTER(1))');
        Observer.Verify();
    end;

    // Group E: Buffer's own procedure, OnValidate and OnInsert hand a local BVH Row to Buffer.GetNext by value.
    local procedure Apply(var Observer: Codeunit "Probe Observer"; Shape: Integer; Mode: Integer)
    var
        Buffer: Record "BVH Buffer";
    begin
        Seed();
        Buffer.Id := 1;
        Buffer.Mode := Mode;
        Buffer.ApplyLines(Shape);
        ObserveSlot(Observer, 'copy');
        ObserveSlot(Observer, 'local after');
    end;

    [Test]
    procedure E_OwnProcedure_Proc_Group0Init()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Apply(Observer, 0, 1);
        Observer.Expect('copy', 'ld=No temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('local after', 'ld=No temp=No same=Yes gs={0:Status: Open, Flag: Yes;1:Amount: >15;} grp=0 n=1 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('local after view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open),Flag=FILTER(true))');
        Observer.Verify();
    end;

    [Test]
    procedure E_OwnProcedure_RecProc_Group0Init()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Apply(Observer, 0, 2);
        Observer.Expect('copy', 'ld=No temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('local after', 'ld=No temp=No same=Yes gs={0:Status: Open, Flag: Yes;1:Amount: >15;} grp=0 n=1 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('local after view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open),Flag=FILTER(true))');
        Observer.Verify();
    end;

    [Test]
    procedure E_OwnProcedure_Proc_NoView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Apply(Observer, 1, 1);
        Observer.Expect('copy', 'ld=No temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('local after', 'ld=No temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('local after view', 'VERSION(1) SORTING(Id)');
        Observer.Verify();
    end;

    [Test]
    procedure E_OwnProcedure_Proc_SecondaryKeyDescending()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Apply(Observer, 2, 1);
        Observer.Expect('copy', 'ld=No temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('local after', 'ld=No temp=No same=Yes gs={0:Status: Open;1:Amount: >15;} grp=0 n=2 key=Name asc=No iso=Default mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('local after view', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Status=FILTER(Open))');
        Observer.Verify();
    end;

    [Test]
    procedure E_OwnProcedure_Proc_Group2Filter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Apply(Observer, 3, 1);
        Observer.Expect('copy', 'ld=No temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('local after', 'ld=No temp=No same=Yes gs={1:Amount: >15;2:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('local after view', 'VERSION(1) SORTING(Id)');
        Observer.Verify();
    end;

    [Test]
    procedure E_OwnProcedure_Proc_Group0FindFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Apply(Observer, 4, 1);
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('local after', 'ld=Yes temp=No same=Yes gs={0:Status: Open, Flag: Yes;1:Amount: >15;} grp=0 n=1 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('local after view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open),Flag=FILTER(true))');
        Observer.Verify();
    end;

    [Test]
    procedure E_OwnProcedure_Proc_SetLoadFieldsRead()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Apply(Observer, 5, 1);
        Observer.Expect('copy', 'ld=No temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('local after', 'ld=No temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('local after view', 'VERSION(1) SORTING(Id)');
        Observer.Verify();
    end;

    [Test]
    procedure E_OwnValidate_Proc_Group0Init()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "BVH Buffer";
    begin
        Seed();
        Buffer.Id := 1;
        Buffer.Mode := 1;
        Buffer.Validate(Code, 'X');
        ObserveSlot(Observer, 'copy');
        ObserveSlot(Observer, 'local after');
        Observer.Expect('copy', 'ld=No temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('local after', 'ld=No temp=No same=Yes gs={0:Status: Open, Flag: Yes;1:Amount: >15;} grp=0 n=1 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('local after view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open),Flag=FILTER(true))');
        Observer.Verify();
    end;

    [Test]
    procedure E_OwnInsert_RecProc_Group0Init()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "BVH Buffer";
    begin
        Seed();
        Buffer.Id := 1;
        Buffer.Mode := 2;
        Buffer.Insert(true);
        ObserveSlot(Observer, 'copy');
        ObserveSlot(Observer, 'local after');
        Observer.Expect('copy', 'ld=No temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('local after', 'ld=No temp=No same=Yes gs={0:Status: Open, Flag: Yes;1:Amount: >15;} grp=0 n=1 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('local after view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open),Flag=FILTER(true))');
        Observer.Verify();
    end;

    // Group B: the report raises OnRowAfterGet for rows 3 (A-NAME) and 1 (C-NAME); the subscriber reads and hands on its copy.
    [Test]
    procedure B_ReportSender_HandOn_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
        Rep: Report "BVH Rows Report";
    begin
        Seed();
        Row.SetFilter(Amount, '>5');
        Rep.SetTableView(Row);
        Rep.UseRequestPage(false);
        Rep.Run();
        ObserveSlot(Observer, 'item');
        ObserveSlot(Observer, 'subscriber');
        ObserveSlot(Observer, 'hand on');
        ObserveSlot(Observer, 'after setrecfilter');
        ObserveSlot(Observer, 'second item');
        Observer.Observe('second rows', Log.Take('second rows'));
        ObserveSlot(Observer, 'subscriber after');
        Observer.Expect('item', 'gs={0:Amount: >5;1:Amount: >15;2:Status: Open, Flag: Yes;} grp=0 key=Name id=1 name=C-NAME');
        Observer.Expect('item view', 'VERSION(1) SORTING(Name) WHERE(Amount=FILTER(>5))');
        Observer.Expect('subscriber', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('subscriber view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('hand on', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('hand on view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('after setrecfilter', 'ld=Yes temp=No same=Yes gs={0:Id: 1;1:Amount: >15;} grp=0 n=1 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('after setrecfilter view', 'VERSION(1) SORTING(Id) WHERE(Id=FILTER(1))');
        Observer.Expect('second item', 'ld=No temp=No same=Yes gs={0:Id: 1;1:Amount: >15;} grp=0 n=1 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('second item view', 'VERSION(1) SORTING(Id) WHERE(Id=FILTER(1))');
        Observer.Expect('second rows', '1');
        Observer.Expect('subscriber after', 'ld=Yes temp=No same=Yes gs={0:Id: 1;1:Amount: >15;} grp=0 n=1 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('subscriber after view', 'VERSION(1) SORTING(Id) WHERE(Id=FILTER(1))');
        Observer.Verify();
    end;

    [Test]
    procedure B_ReportSender_HandOn_Group2AndKey()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVH Row";
        Rep: Report "BVH Rows Report";
    begin
        Seed();
        Row.SetCurrentKey(Name);
        Row.Ascending(false);
        Row.FilterGroup(2);
        Row.SetFilter(Amount, '>15');
        Row.FilterGroup(0);
        Rep.SetTableView(Row);
        Rep.UseRequestPage(false);
        Rep.Run();
        ObserveSlot(Observer, 'item');
        ObserveSlot(Observer, 'subscriber');
        ObserveSlot(Observer, 'after setrecfilter');
        ObserveSlot(Observer, 'second item');
        Observer.Observe('second rows', Log.Take('second rows'));
        Observer.Expect('item', 'gs={1:Amount: >15;2:Status: Open, Amount: >15, Flag: Yes;} grp=0 key=Name id=1 name=C-NAME');
        Observer.Expect('item view', 'VERSION(1) SORTING(Name) ORDER(Descending)');
        Observer.Expect('subscriber', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('subscriber view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('after setrecfilter', 'ld=Yes temp=No same=Yes gs={0:Id: 1;1:Amount: >15;} grp=0 n=1 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('after setrecfilter view', 'VERSION(1) SORTING(Id) WHERE(Id=FILTER(1))');
        Observer.Expect('second item', 'ld=No temp=No same=Yes gs={0:Id: 1;1:Amount: >15;} grp=0 n=1 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('second item view', 'VERSION(1) SORTING(Id) WHERE(Id=FILTER(1))');
        Observer.Expect('second rows', '1');
        Observer.Verify();
    end;

    // Group C: lines 1 and 2 (row 1, kind 1) are copied; four-parameter event, two subscribers.
    [Test]
    procedure C_FourParameters_Group0Loop()
    var
        Observer: Codeunit "Probe Observer";
        Copier: Codeunit "BVH Copier";
    begin
        Seed();
        Copier.Run(false);
        ObserveSlot(Observer, 'new line');
        ObserveSlot(Observer, 'old line');
        ObserveSlot(Observer, 'new header');
        ObserveSlot(Observer, 'old header');
        ObserveSlot(Observer, 'line ref');
        ObserveSlot(Observer, 'header ref');
        Observer.Expect('new line', 'temp=No gs={} grp=0 n=4 key=Id asc=Yes iso=Default id=101 rowid=2 kind=1 | temp=No gs={} grp=0 n=5 key=Id asc=Yes iso=Default id=102 rowid=2 kind=1');
        Observer.Expect('new line view', 'VERSION(1) SORTING(Id) | VERSION(1) SORTING(Id)');
        Observer.Expect('old line', 'temp=No gs={} grp=0 n=4 key=Id asc=Yes iso=Default id=1 rowid=1 kind=1 | temp=No gs={} grp=0 n=5 key=Id asc=Yes iso=Default id=2 rowid=1 kind=1');
        Observer.Expect('old line view', 'VERSION(1) SORTING(Id) | VERSION(1) SORTING(Id)');
        Observer.Expect('new header', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=2 name=B-NAME total=0 | ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=2 name=B-NAME total=0');
        Observer.Expect('new header view', 'VERSION(1) SORTING(Id) | VERSION(1) SORTING(Id)');
        Observer.Expect('old header', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15 | ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('old header view', 'VERSION(1) SORTING(Id) | VERSION(1) SORTING(Id)');
        Observer.Expect('line ref', 'temp=No f={} n=4 rid=BVH Line: 1 f1=1 f2=1 iso=Default | temp=No f={} n=5 rid=BVH Line: 2 f1=2 f2=1 iso=Default');
        Observer.Expect('line ref view', 'VERSION(1) SORTING(Id) | VERSION(1) SORTING(Id)');
        Observer.Expect('header ref', 'temp=No f={} n=3 rid=BVH Row: 1 f1=1 f2=C-NAME iso=Default | temp=No f={} n=3 rid=BVH Row: 1 f1=1 f2=C-NAME iso=Default');
        Observer.Expect('header ref view', 'VERSION(1) SORTING(Id) | VERSION(1) SORTING(Id)');
        Observer.Verify();
    end;

    [Test]
    procedure C_FourParameters_RichLoop()
    var
        Observer: Codeunit "Probe Observer";
        Copier: Codeunit "BVH Copier";
    begin
        Seed();
        Copier.Run(true);
        ObserveSlot(Observer, 'old line');
        ObserveSlot(Observer, 'old header');
        ObserveSlot(Observer, 'line ref');
        Observer.Expect('old line', 'temp=No gs={} grp=0 n=4 key=Id asc=Yes iso=Default id=2 rowid=1 kind=1 | temp=No gs={} grp=0 n=5 key=Id asc=Yes iso=Default id=1 rowid=1 kind=1');
        Observer.Expect('old line view', 'VERSION(1) SORTING(Id) | VERSION(1) SORTING(Id)');
        Observer.Expect('old header', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15 | ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('old header view', 'VERSION(1) SORTING(Id) | VERSION(1) SORTING(Id)');
        Observer.Expect('line ref', 'temp=No f={} n=4 rid=BVH Line: 2 f1=2 f2=1 iso=Default | temp=No f={} n=5 rid=BVH Line: 1 f1=1 f2=1 iso=Default');
        Observer.Expect('line ref view', 'VERSION(1) SORTING(Id) | VERSION(1) SORTING(Id)');
        Observer.Verify();
    end;

    // Group D: rows 1 and 3 (Open, Flag) go through SumLine; the caller's Src has Amount >= 10 in group 0.
    local procedure PostBatch(var Observer: Codeunit "Probe Observer"; Iso: Integer; AutoCalc: Integer)
    var
        Src: Record "BVH Row";
        Batch: Codeunit "BVH Batch";
    begin
        Seed();
        Src.SetFilter(Amount, '>=10');
        Batch.Post(Src, Iso, AutoCalc);
        Observer.Observe('total before find', Log.Take('total before find'));
        Observer.Observe('find', Log.Take('find'));
        Observer.Observe('total after find', Log.Take('total after find'));
        ObserveSlot(Observer, 'copy');
        ObserveSlot(Observer, 'sender');
        ObserveSlot(Observer, 'sender ref');
        ObserveSlot(Observer, 'global after');
    end;

    [Test]
    procedure D_GlobalCopy_UpdLock_NoAutoCalc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PostBatch(Observer, 1, 0);
        Observer.Expect('total before find', '0');
        Observer.Expect('find', 'Yes');
        Observer.Expect('total after find', '0');
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('sender', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('sender view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('sender ref', 'temp=No f={} n=3 rid=BVH Row: 1 f1=1 f2=C-NAME iso=Default');
        Observer.Expect('sender ref view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('global after', 'ld=Yes temp=No same=Yes gs={0:Status: Open, Amount: >=10, Flag: Yes;1:Amount: >15;} grp=0 n=1 key=Id asc=Yes iso=UpdLock mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('global after view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open),Amount=FILTER(>=10),Flag=FILTER(true))');
        Observer.Verify();
    end;

    [Test]
    procedure D_GlobalCopy_NoIsolation_NoAutoCalc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PostBatch(Observer, 0, 0);
        Observer.Expect('total before find', '0');
        Observer.Expect('find', 'Yes');
        Observer.Expect('total after find', '0');
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('sender', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('sender view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('sender ref', 'temp=No f={} n=3 rid=BVH Row: 1 f1=1 f2=C-NAME iso=Default');
        Observer.Expect('sender ref view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('global after', 'ld=Yes temp=No same=Yes gs={0:Status: Open, Amount: >=10, Flag: Yes;1:Amount: >15;} grp=0 n=1 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('global after view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open),Amount=FILTER(>=10),Flag=FILTER(true))');
        Observer.Verify();
    end;

    [Test]
    procedure D_GlobalCopy_ReadCommitted_NoAutoCalc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PostBatch(Observer, 2, 0);
        Observer.Expect('total before find', '0');
        Observer.Expect('find', 'Yes');
        Observer.Expect('total after find', '0');
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('sender', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('sender view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('sender ref', 'temp=No f={} n=3 rid=BVH Row: 1 f1=1 f2=C-NAME iso=Default');
        Observer.Expect('sender ref view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('global after', 'ld=Yes temp=No same=Yes gs={0:Status: Open, Amount: >=10, Flag: Yes;1:Amount: >15;} grp=0 n=1 key=Id asc=Yes iso=ReadCommitted mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('global after view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open),Amount=FILTER(>=10),Flag=FILTER(true))');
        Observer.Verify();
    end;

    [Test]
    procedure D_GlobalCopy_UpdLock_AutoCalcTotal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PostBatch(Observer, 1, 1);
        Observer.Expect('total before find', '0');
        Observer.Expect('find', 'Yes');
        Observer.Expect('total after find', '0');
        Observer.Expect('copy', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('copy view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('sender', 'ld=Yes temp=No same=Yes gs={1:Amount: >15;} grp=0 n=3 key=Id asc=Yes iso=Default mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('sender view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('sender ref', 'temp=No f={} n=3 rid=BVH Row: 1 f1=1 f2=C-NAME iso=Default');
        Observer.Expect('sender ref view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('global after', 'ld=Yes temp=No same=Yes gs={0:Status: Open, Amount: >=10, Flag: Yes;1:Amount: >15;} grp=0 n=1 key=Id asc=Yes iso=UpdLock mo=No m=0 ff={} cf={} id=1 name=C-NAME total=15');
        Observer.Expect('global after view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open),Amount=FILTER(>=10),Flag=FILTER(true))');
        Observer.Verify();
    end;
}
