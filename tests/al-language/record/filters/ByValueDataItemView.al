// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods/devenv-passing-parameters
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 78735..78739 and 78751..78755 (BVV Iso Row, BVV Iso Callee, BVV Iso Desc Report,
//   BVV Iso Name Report, BVV Iso Item View Tests)
// local object: the view a report's data item record hands by value, and the isolation level of the copy, is what is under test.
// Probe (al-runner issue 8838): a report's data item that still holds its DataItemTableView, read descending, handed by value
//   from its OnAfterGetRecord. The shape of report 7300 "Calculate Bin Replenishment": its "Bin Content" data item declares
//   sorting(...) order(descending) where(Fixed = filter(true)) and hands its record to codeunit 7308 "Replenishment"
//   .ReplenishBin, which calls table 7302 "Bin Content".NeedToReplenish on the copy; that procedure reads Rec.ReadIsolation()
//   and sets ReadCommitted when it is not UpdLock. Cells:
//   - the primary key descending with a where filter, to a codeunit procedure that calls such a table procedure on the copy;
//   - the same data item to a local procedure of the report;
//   - a declared secondary key descending with two where filters and a SetTableView filter, to the codeunit procedure.
//   Each callee reads GetFilters, Count, CurrentKey, Ascending, FilterGroup and the filters of groups -1 to 7, then the table
//   procedure's ReadIsolation before and after it sets one, the copy's ReadIsolation after it, and FindFirst; the report then
//   reads its own data item's view and ReadIsolation, and the rows it read.
// Already pinned elsewhere, not repeated: the same data item, ascending, to a local and to a codeunit procedure
//   (record/filters/ByValueRecordView.al ByValue_ReportProcedure_DataItemView and _DataItemViewToCodeunit).
// Facts (measured on 29.0):
//   - the copy has the view of a fresh record: no filter in groups -1 to 7, the primary key, ascending, filter group 0, Count of
//     the whole table, FindFirst the lowest id; the order(descending) and the where filters of the DataItemTableView and the
//     SetTableView filter are not handed;
//   - the copy's ReadIsolation is Default; the table procedure sets ReadCommitted on the copy, and the data item keeps Default;
//   - the data item keeps its key, descending order and filters, and the rows come in its descending order.
// BC versions: 29.0

table 78735 "BVV Iso Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
        field(3; Status; Option) { OptionMembers = Open,Posted; }
        field(4; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByName; Name) { }
    }

    // The shape of table 7302 "Bin Content".NeedToReplenish: it reads the isolation level of its own Rec and sets it when it
    // is not UpdLock.
    procedure NeedToReplenish(ExcludeQty: Decimal): Text
    var
        Before: Text;
    begin
        Before := Format(Rec.ReadIsolation());
        if Rec.ReadIsolation() <> IsolationLevel::UpdLock then
            Rec.ReadIsolation(IsolationLevel::ReadCommitted);
        exit('iso before=' + Before + ' after=' + Format(Rec.ReadIsolation()) + ' need=' + Format(Rec.Amount > ExcludeQty));
    end;
}

codeunit 78736 "BVV Iso Callee"
{
    procedure Replenish(R: Record "BVV Iso Row"): Text
    var
        Result: Text;
        First: Text;
    begin
        Result := 'id=' + Format(R.Id) + ' f={' + R.GetFilters() + '} n=' + Format(R.Count()) + ' key=' + R.CurrentKey()
            + ' asc=' + Format(R.Ascending()) + ' grp=' + Format(R.FilterGroup()) + ' groups ' + Groups(R);
        Result += ' ' + R.NeedToReplenish(0) + ' iso now=' + Format(R.ReadIsolation());
        if R.FindFirst() then
            First := Format(R.Id)
        else
            First := 'none';
        exit(Result + ' first=' + First);
    end;

    procedure Groups(R: Record "BVV Iso Row"): Text
    var
        Result: Text;
        Group: Integer;
    begin
        for Group := -1 to 7 do begin
            R.FilterGroup(Group);
            Result += Format(Group) + '={' + R.GetFilters() + '} ';
        end;
        R.FilterGroup(0);
        exit(Result);
    end;
}

// The shape of report 7300 "Calculate Bin Replenishment": a data item read descending under a where filter, whose
// OnAfterGetRecord hands its record by value to a codeunit.
report 78737 "BVV Iso Desc Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "BVV Iso Row")
        {
            DataItemTableView = sorting(Id) order(descending) where(Status = filter(Open));

            trigger OnAfterGetRecord()
            var
                Callee: Codeunit "BVV Iso Callee";
            begin
                Ids += Format(Id) + ',';
                if Done then
                    exit;
                Done := true;
                case Mode of
                    1:
                        Outcome := 'callee ' + Callee.Replenish(Row);
                    2:
                        Outcome := 'callee ' + Replenish(Row);
                end;
                Outcome += ' item after f={' + GetFilters() + '} n=' + Format(Count()) + ' key=' + CurrentKey() + ' asc='
                    + Format(Ascending()) + ' iso=' + Format(ReadIsolation());
            end;
        }
    }

    var
        Mode: Integer;
        Done: Boolean;
        Outcome: Text;
        Ids: Text;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    procedure GetResult(): Text
    begin
        exit(Outcome + ' ids=' + Ids);
    end;

    local procedure Replenish(R: Record "BVV Iso Row"): Text
    var
        Callee: Codeunit "BVV Iso Callee";
        Result: Text;
        First: Text;
    begin
        Result := 'id=' + Format(R.Id) + ' f={' + R.GetFilters() + '} n=' + Format(R.Count()) + ' key=' + R.CurrentKey()
            + ' asc=' + Format(R.Ascending()) + ' grp=' + Format(R.FilterGroup()) + ' groups ' + Callee.Groups(R);
        Result += ' ' + R.NeedToReplenish(0) + ' iso now=' + Format(R.ReadIsolation());
        if R.FindFirst() then
            First := Format(R.Id)
        else
            First := 'none';
        exit(Result + ' first=' + First);
    end;
}

// A secondary key read descending under two where filters, handed to the codeunit.
report 78738 "BVV Iso Name Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "BVV Iso Row")
        {
            DataItemTableView = sorting(Name) order(descending) where(Status = filter(Open), Amount = filter(> 0));

            trigger OnAfterGetRecord()
            var
                Callee: Codeunit "BVV Iso Callee";
            begin
                Ids += Format(Id) + ',';
                if Done then
                    exit;
                Done := true;
                Outcome := 'callee ' + Callee.Replenish(Row);
                Outcome += ' item after f={' + GetFilters() + '} n=' + Format(Count()) + ' key=' + CurrentKey() + ' asc='
                    + Format(Ascending()) + ' iso=' + Format(ReadIsolation());
            end;
        }
    }

    var
        Done: Boolean;
        Outcome: Text;
        Ids: Text;

    procedure GetResult(): Text
    begin
        exit(Outcome + ' ids=' + Ids);
    end;
}

codeunit 78739 "BVV Iso Item View Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Rows 1 (C-NAME, Open, 30), 2 (B-NAME, Posted, 20), 3 (A-NAME, Open, 0), 4 (D-NAME, Open, 10).
    local procedure Seed()
    var
        Row: Record "BVV Iso Row";
    begin
        Row.DeleteAll();
        AddRow(1, 'C-NAME', Row.Status::Open, 30);
        AddRow(2, 'B-NAME', Row.Status::Posted, 20);
        AddRow(3, 'A-NAME', Row.Status::Open, 0);
        AddRow(4, 'D-NAME', Row.Status::Open, 10);
    end;

    local procedure AddRow(Id: Integer; Name: Text[20]; Status: Option; Amount: Decimal)
    var
        Row: Record "BVV Iso Row";
    begin
        Row.Id := Id;
        Row.Name := Name;
        Row.Status := Status;
        Row.Amount := Amount;
        Row.Insert();
    end;

    [Test]
    procedure ByValue_ReportProcedure_DataItemViewDescendingToCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "BVV Iso Desc Report";
    begin
        Seed();
        Rep.SetMode(1);
        Rep.RunModal();
        Observer.Observe('report', Rep.GetResult());
        Observer.Expect('report', 'callee id=4 f={} n=4 key=Id asc=Yes grp=0 groups -1={} 0={} 1={} 2={} 3={} 4={} 5={} 6={} 7={}  iso before=Default after=ReadCommitted need=Yes iso now=ReadCommitted first=1 item after f={} n=3 key=Id asc=No iso=Default ids=4,3,1,');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_ReportProcedure_DataItemViewDescendingToLocal()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "BVV Iso Desc Report";
    begin
        Seed();
        Rep.SetMode(2);
        Rep.RunModal();
        Observer.Observe('report', Rep.GetResult());
        Observer.Expect('report', 'callee id=4 f={} n=4 key=Id asc=Yes grp=0 groups -1={} 0={} 1={} 2={} 3={} 4={} 5={} 6={} 7={}  iso before=Default after=ReadCommitted need=Yes iso now=ReadCommitted first=1 item after f={} n=3 key=Id asc=No iso=Default ids=4,3,1,');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_ReportProcedure_DataItemViewSecondaryKeyDescendingToCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Iso Row";
        Rep: Report "BVV Iso Name Report";
    begin
        Seed();
        Row.SetFilter(Amount, '<%1', 30);
        Rep.SetTableView(Row);
        Rep.RunModal();
        Observer.Observe('report', Rep.GetResult());
        Observer.Observe('caller after', 'f={' + Row.GetFilters() + '} n=' + Format(Row.Count()));
        Observer.Expect('report', 'callee id=4 f={} n=4 key=Id asc=Yes grp=0 groups -1={} 0={} 1={} 2={} 3={} 4={} 5={} 6={} 7={}  iso before=Default after=ReadCommitted need=Yes iso now=ReadCommitted first=1 item after f={Amount: <30} n=1 key=Name asc=No iso=Default ids=4,');
        Observer.Expect('caller after', 'f={Amount: <30} n=3');
        Observer.Verify();
    end;
}

// Added after review (al-runner PR 8853): a child data item with a DataItemLink and a DataItemTableView, handed to a
// codeunit procedure and to a local procedure of the report; and the data item with its view handed to a procedure of another
// instance of the same report.
// Facts (measured on 29.0): the copy has the view of a fresh record in each: neither the DataItemLink filter nor the
// DataItemTableView of the child is handed (no filter in groups -1 to 7, the primary key ascending, Count of the whole
// table), and another instance of the report gets a fresh view too; the data items keep their views.
table 78751 "BVV Iso Line"
{
    fields
    {
        field(1; RowId; Integer) { }
        field(2; Id; Integer) { }
        field(3; Amt; Decimal) { }
    }

    keys
    {
        key(PK; RowId, Id) { Clustered = true; }
    }
}

codeunit 78752 "BVV Iso Line Callee"
{
    procedure Describe(L: Record "BVV Iso Line"): Text
    var
        Result: Text;
        First: Text;
        Group: Integer;
    begin
        Result := 'row=' + Format(L.RowId) + ' id=' + Format(L.Id) + ' f={' + L.GetFilters() + '} n=' + Format(L.Count())
            + ' key=' + L.CurrentKey() + ' asc=' + Format(L.Ascending()) + ' grp=' + Format(L.FilterGroup()) + ' groups ';
        for Group := -1 to 7 do begin
            L.FilterGroup(Group);
            Result += Format(Group) + '={' + L.GetFilters() + '} ';
        end;
        L.FilterGroup(0);
        if L.FindFirst() then
            First := Format(L.RowId) + '/' + Format(L.Id)
        else
            First := 'none';
        exit(Result + 'first=' + First);
    end;
}

// The child Line has both a DataItemLink and a DataItemTableView, as many Base Application child data items do.
report 78753 "BVV Iso Link Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "BVV Iso Row")
        {
            DataItemTableView = sorting(Id) where(Status = filter(Open));

            dataitem(Line; "BVV Iso Line")
            {
                DataItemLink = RowId = field(Id);
                DataItemTableView = sorting(RowId, Id) order(descending) where(Amt = filter(> 0));

                trigger OnAfterGetRecord()
                var
                    Callee: Codeunit "BVV Iso Line Callee";
                begin
                    Ids += Format(RowId) + '/' + Format(Id) + ',';
                    if Done then
                        exit;
                    Done := true;
                    case Mode of
                        1:
                            Outcome := 'callee ' + Callee.Describe(Line);
                        2:
                            Outcome := 'callee ' + DescribeLine(Line);
                    end;
                    Outcome += ' item after f={' + GetFilters() + '} n=' + Format(Count()) + ' key=' + CurrentKey() + ' asc='
                        + Format(Ascending());
                end;
            }
        }
    }

    var
        Mode: Integer;
        Done: Boolean;
        Outcome: Text;
        Ids: Text;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    procedure GetResult(): Text
    begin
        exit(Outcome + ' ids=' + Ids);
    end;

    local procedure DescribeLine(L: Record "BVV Iso Line"): Text
    var
        Callee: Codeunit "BVV Iso Line Callee";
    begin
        exit(Callee.Describe(L));
    end;
}

// The data item with its view handed to a procedure of another instance of the same report.
report 78754 "BVV Iso Other Instance"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "BVV Iso Row")
        {
            DataItemTableView = sorting(Id) order(descending) where(Status = filter(Open));

            trigger OnAfterGetRecord()
            var
                OtherInstance: Report "BVV Iso Other Instance";
            begin
                Ids += Format(Id) + ',';
                if Done then
                    exit;
                Done := true;
                Outcome := 'other instance ' + OtherInstance.Describe(Row) + ' item after f={' + GetFilters() + '} n='
                    + Format(Count()) + ' key=' + CurrentKey() + ' asc=' + Format(Ascending());
            end;
        }
    }

    var
        Done: Boolean;
        Outcome: Text;
        Ids: Text;

    procedure GetResult(): Text
    begin
        exit(Outcome + ' ids=' + Ids);
    end;

    procedure Describe(R: Record "BVV Iso Row"): Text
    var
        Result: Text;
        First: Text;
        Group: Integer;
    begin
        Result := 'id=' + Format(R.Id) + ' f={' + R.GetFilters() + '} n=' + Format(R.Count()) + ' key=' + R.CurrentKey()
            + ' asc=' + Format(R.Ascending()) + ' grp=' + Format(R.FilterGroup()) + ' groups ';
        for Group := -1 to 7 do begin
            R.FilterGroup(Group);
            Result += Format(Group) + '={' + R.GetFilters() + '} ';
        end;
        R.FilterGroup(0);
        if R.FindFirst() then
            First := Format(R.Id)
        else
            First := 'none';
        exit(Result + 'first=' + First);
    end;
}

codeunit 78755 "BVV Iso Link Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Rows 1 (C-NAME, Open, 30), 2 (B-NAME, Posted, 20), 3 (A-NAME, Open, 0), 4 (D-NAME, Open, 10).
    // Lines: row 1: 1 (5), 2 (0), 3 (7); row 2: 1 (9); row 4: 1 (3).
    local procedure Seed()
    var
        Row: Record "BVV Iso Row";
        Line: Record "BVV Iso Line";
    begin
        Row.DeleteAll();
        Line.DeleteAll();
        AddRow(1, 'C-NAME', Row.Status::Open, 30);
        AddRow(2, 'B-NAME', Row.Status::Posted, 20);
        AddRow(3, 'A-NAME', Row.Status::Open, 0);
        AddRow(4, 'D-NAME', Row.Status::Open, 10);
        AddLine(1, 1, 5);
        AddLine(1, 2, 0);
        AddLine(1, 3, 7);
        AddLine(2, 1, 9);
        AddLine(4, 1, 3);
    end;

    local procedure AddRow(Id: Integer; Name: Text[20]; Status: Option; Amount: Decimal)
    var
        Row: Record "BVV Iso Row";
    begin
        Row.Id := Id;
        Row.Name := Name;
        Row.Status := Status;
        Row.Amount := Amount;
        Row.Insert();
    end;

    local procedure AddLine(RowId: Integer; Id: Integer; Amt: Decimal)
    var
        Line: Record "BVV Iso Line";
    begin
        Line.RowId := RowId;
        Line.Id := Id;
        Line.Amt := Amt;
        Line.Insert();
    end;

    [Test]
    procedure ByValue_ReportProcedure_ChildDataItemLinkViewToCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "BVV Iso Link Report";
    begin
        Seed();
        Rep.SetMode(1);
        Rep.RunModal();
        Observer.Observe('report', Rep.GetResult());
        Observer.Expect('report', 'callee row=1 id=3 f={} n=5 key=RowId,Id asc=Yes grp=0 groups -1={} 0={} 1={} 2={} 3={} 4={} 5={} 6={} 7={} first=1/1 item after f={} n=2 key=RowId,Id asc=No ids=1/3,1/1,4/1,');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_ReportProcedure_ChildDataItemLinkViewToLocal()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "BVV Iso Link Report";
    begin
        Seed();
        Rep.SetMode(2);
        Rep.RunModal();
        Observer.Observe('report', Rep.GetResult());
        Observer.Expect('report', 'callee row=1 id=3 f={} n=5 key=RowId,Id asc=Yes grp=0 groups -1={} 0={} 1={} 2={} 3={} 4={} 5={} 6={} 7={} first=1/1 item after f={} n=2 key=RowId,Id asc=No ids=1/3,1/1,4/1,');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_ReportProcedure_DataItemViewToOtherInstance()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "BVV Iso Other Instance";
    begin
        Seed();
        Rep.RunModal();
        Observer.Observe('report', Rep.GetResult());
        Observer.Expect('report', 'other instance id=4 f={} n=4 key=Id asc=Yes grp=0 groups -1={} 0={} 1={} 2={} 3={} 4={} 5={} 6={} 7={} first=1 item after f={} n=3 key=Id asc=No ids=4,3,1,');
        Observer.Verify();
    end;
}
