// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods/devenv-passing-parameters
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 78720..78728 (BVV Row, BVV Line, BVV Rows, BVV Rows Report, BVV Log,
//   BVV Callee, BVV Publisher, BVV Subscriber, BVV By Value View Tests)
// local object: the view (filters, filter groups, key, order, marks) of a record of an own table handed by value is what is under test.
// Probe (al-runner issue 8185): what a procedure sees of the caller's view when it gets a record of a stored table by value
//   (a Record parameter without var). Cells:
//   - a filter in filter group 0 (GetFilters, Count, FindFirst, GetView, CurrentKey, Ascending, FilterGroup in the callee), with a
//     codeunit procedure and with a local procedure of the test codeunit (the reporter's shape), and no filter as the control;
//   - a filter in filter group 1, 2, 4 and -1; the caller standing in filter group 2 (with its filter there, and with a filter in
//     group 0); the filters of every group as the callee reads them;
//   - Ascending(false) with and without a filter;
//   - a marked row with MarkedOnly off and on;
//   - SetLoadFields (AreFieldsLoaded after FindFirst in the callee); ChangeCompany to the current company;
//   - a declared secondary key (with and without a filter) and an ad hoc key (fields no key starts with);
//   - CalcFields of a FlowField with its FlowFilter in group 0 and in group 2;
//   - the copy handed on to Other.Copy, Other.CopyFilters, RecordRef.GetTable, Page.Run, Page.SetTableView and Report.SetTableView;
//   - a by-value parameter of an integration event (what the subscriber sees);
//   - a temporary record handed by value to a parameter that is not declared temporary;
//   - in every cell, the caller's filters after the call.
//   Added for al-runner issue 8248: a filter on a FlowField (with its FlowFilter) handed to a codeunit procedure and to a
//   local procedure; two filters in filter group -1 (the reporter's shape); a table procedure that gets its own Rec by value
//   (Rec.CountSameStatus(Rec), the shape of "Item Attribute Value".CheckValueUniqueness) after Get, with a FlowField filter
//   in the caller; whether a filter in filter group 1 is seen by another, fresh record variable of the same table.
// Already pinned elsewhere, not repeated: the primary key of the copy (record/keys-sorting/PwFlowFieldKeyRule.al).
// Facts (measured on 29.0; 27.5 and 28.5 by the final observe run and the corpus CI):
//   - a Record parameter without var starts with no filters in groups -1, 0, 2 and 4, whatever group the caller stands in
//     (GetFilters empty, Count of the whole table, FilterGroup 0); this holds for a plain filter, a filter on a FlowField with its
//     FlowFilter, two filters in filter group -1, a FlowFilter in group 0 or 2 (CalcFields in the callee sums every day);
//   - the copy has the primary key, ascending, GetView 'VERSION(1) SORTING(Id)', no marks (MarkedOnly No, 0 marked), all fields
//     loaded after SetLoadFields in the caller, and the caller's company; a temporary record given to a parameter not declared
//     temporary arrives as a non-temporary record of the table;
//   - Copy, CopyFilters, RecordRef.GetTable, Page.Run, Page.SetTableView, Report.SetTableView in the callee and a by-value event
//     subscriber parameter see no filter either;
//   - a table procedure called as Rec.Proc(Rec): its own Rec keeps the caller's filters, the by-value parameter has none;
//   - a filter set in filter group 1 is seen by every record variable of the table in the session (a fresh variable, the callee's
//     copy), until one of them clears it (ByValue_Group1Filter_OtherInstance); Seed clears it for that reason;
//   - the caller's own filters, filter group, key, order and marks are unchanged after every call.
// BC versions: 27.5, 28.5, 29.0

table 78720 "BVV Row"
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
            CalcFormula = sum("BVV Line".Amt where(RowId = field(Id), Day = field("Day Filter")));
        }
        field(6; "Day Filter"; Integer) { FieldClass = FlowFilter; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByName; Name) { }
    }

    procedure CountSameStatus(Copy: Record "BVV Row"): Text
    var
        Result: Text;
    begin
        Result := 'self f={' + Rec.GetFilters() + '} copy f={' + Copy.GetFilters() + '}';
        Copy.SetFilter(Id, '<>%1', Copy.Id);
        Copy.SetRange(Status, Copy.Status);
        exit(Result + ' same n=' + Format(Copy.Count()));
    end;
}

table 78721 "BVV Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; RowId; Integer) { }
        field(3; Day; Integer) { }
        field(4; Amt; Decimal) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 78722 "BVV Rows"
{
    PageType = List;
    SourceTable = "BVV Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
            }
        }
    }
}

report 78723 "BVV Rows Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "BVV Row")
        {
            trigger OnPreDataItem()
            var
                Log: Codeunit "BVV Log";
            begin
                Log.Add('report f={' + Row.GetFilters() + '} n=' + Format(Row.Count()));
            end;

            trigger OnAfterGetRecord()
            var
                Log: Codeunit "BVV Log";
            begin
                Log.Add('row ' + Format(Row.Id));
            end;
        }
    }
}

codeunit 78724 "BVV Log"
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

codeunit 78725 "BVV Callee"
{
    procedure Describe(R: Record "BVV Row"): Text
    var
        First: Text;
        Result: Text;
    begin
        Result := 'f={' + R.GetFilters() + '} n=' + Format(R.Count()) + ' key=' + R.CurrentKey() + ' asc=' + Format(R.Ascending())
            + ' grp=' + Format(R.FilterGroup());
        if R.FindFirst() then
            First := Format(R.Id)
        else
            First := 'none';
        exit(Result + ' first=' + First);
    end;

    procedure View(R: Record "BVV Row"): Text
    begin
        exit(R.GetView());
    end;

    procedure Groups(R: Record "BVV Row"): Text
    var
        Result: Text;
        Group: Integer;
    begin
        foreach Group in GroupList() do begin
            R.FilterGroup(Group);
            Result += Format(Group) + '={' + R.GetFilters() + '} ';
        end;
        R.FilterGroup(0);
        exit(Result + 'n=' + Format(R.Count()));
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

    procedure Marks(R: Record "BVV Row"): Text
    var
        Result: Text;
    begin
        Result := 'mo=' + Format(R.MarkedOnly()) + ' n=' + Format(R.Count());
        R.MarkedOnly(true);
        exit(Result + ' marked n=' + Format(R.Count()));
    end;

    procedure LoadFields(R: Record "BVV Row"): Text
    begin
        if not R.FindFirst() then
            exit('none');
        exit('first=' + Format(R.Id) + ' amount loaded=' + Format(R.AreFieldsLoaded(R.Amount)) + ' name loaded=' + Format(R.AreFieldsLoaded(R.Name)));
    end;

    procedure Company(R: Record "BVV Row"): Text
    begin
        exit('company=' + R.CurrentCompany() + ' f={' + R.GetFilters() + '} n=' + Format(R.Count()));
    end;

    procedure Total(R: Record "BVV Row"): Text
    begin
        R.CalcFields(Total);
        exit('id=' + Format(R.Id) + ' total=' + Format(R.Total) + ' f={' + R.GetFilters() + '}');
    end;

    procedure Temp(R: Record "BVV Row"): Text
    begin
        exit('temp=' + Format(R.IsTemporary()) + ' f={' + R.GetFilters() + '} n=' + Format(R.Count()));
    end;

    procedure CopyTo(R: Record "BVV Row"): Text
    var
        Other: Record "BVV Row";
    begin
        Other.Copy(R);
        exit('f={' + Other.GetFilters() + '} n=' + Format(Other.Count()));
    end;

    procedure CopyFiltersTo(R: Record "BVV Row"): Text
    var
        Other: Record "BVV Row";
    begin
        Other.CopyFilters(R);
        exit('f={' + Other.GetFilters() + '} n=' + Format(Other.Count()));
    end;

    procedure RecRefOf(R: Record "BVV Row"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(R);
        exit('f={' + RecRef.GetFilters() + '} n=' + Format(RecRef.Count()));
    end;

    procedure RunPage(R: Record "BVV Row")
    begin
        Page.Run(Page::"BVV Rows", R);
    end;

    procedure RunPageSetTableView(R: Record "BVV Row")
    var
        RowsPage: Page "BVV Rows";
    begin
        RowsPage.SetTableView(R);
        RowsPage.Run();
    end;

    procedure RunReport(R: Record "BVV Row")
    var
        Rep: Report "BVV Rows Report";
    begin
        Rep.SetTableView(R);
        Rep.UseRequestPage(false);
        Rep.Run();
    end;
}

codeunit 78726 "BVV Publisher"
{
    procedure Raise(var R: Record "BVV Row")
    begin
        OnThing(R);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnThing(R: Record "BVV Row")
    begin
    end;
}

codeunit 78727 "BVV Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVV Publisher", 'OnThing', '', false, false)]
    local procedure HandleThing(R: Record "BVV Row")
    var
        Log: Codeunit "BVV Log";
    begin
        Log.Add('sub f={' + R.GetFilters() + '} n=' + Format(R.Count()));
    end;
}

codeunit 78728 "BVV By Value View Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Callee: Codeunit "BVV Callee";
        Log: Codeunit "BVV Log";

    // Rows 1 (A, Open), 2 (B, Posted), 3 (C, Open); lines of row 1: day 1 amount 5, day 2 amount 7.
    local procedure Seed()
    var
        Row: Record "BVV Row";
        Line: Record "BVV Line";
    begin
        // A filter in filter group 1 that an earlier test left is seen by this variable too (measured:
        // ByValue_Group1Filter_OtherInstance), and DeleteAll would keep the rows it hides. So clear it first.
        Row.FilterGroup(1);
        Row.SetRange(Status);
        Row.FilterGroup(0);
        Row.DeleteAll();
        Line.DeleteAll();
        AddRow(1, 'C-NAME', Row.Status::Open, 30);
        AddRow(2, 'B-NAME', Row.Status::Posted, 20);
        AddRow(3, 'A-NAME', Row.Status::Open, 10);
        Line.Id := 1;
        Line.RowId := 1;
        Line.Day := 1;
        Line.Amt := 5;
        Line.Insert();
        Line.Id := 2;
        Line.RowId := 1;
        Line.Day := 2;
        Line.Amt := 7;
        Line.Insert();
        Log.Take();
    end;

    local procedure AddRow(Id: Integer; Name: Text[20]; Status: Option; Amount: Decimal)
    var
        Row: Record "BVV Row";
    begin
        Row.Id := Id;
        Row.Name := Name;
        Row.Status := Status;
        Row.Amount := Amount;
        Row.Insert();
    end;

    local procedure DescribeLocal(R: Record "BVV Row"): Text
    var
        First: Text;
    begin
        if R.FindFirst() then
            First := Format(R.Id)
        else
            First := 'none';
        exit('f={' + R.GetFilters() + '} n=' + Format(R.Count()) + ' first=' + First);
    end;

    local procedure ObserveCaller(var Observer: Codeunit "Probe Observer"; var Row: Record "BVV Row")
    begin
        Observer.Observe('caller after', 'f={' + Row.GetFilters() + '} n=' + Format(Row.Count()) + ' grp=' + Format(Row.FilterGroup()));
    end;

    local procedure SetGroupFilter(var Row: Record "BVV Row"; Group: Integer)
    begin
        Row.FilterGroup(Group);
        Row.SetRange(Status, Row.Status::Posted);
        Row.FilterGroup(0);
    end;

    [Test]
    procedure ByValue_NoFilter_Control()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Observer.Observe('callee', Callee.Describe(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee', 'f={} n=3 key=Id asc=Yes grp=0 first=1');
        Observer.Expect('caller after', 'f={} n=3 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_Group0Filter_Codeunit()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.SetRange(Status, Row.Status::Posted);
        Observer.Observe('callee', Callee.Describe(Row));
        Observer.Observe('callee view', Callee.View(Row));
        Observer.Observe('callee groups', Callee.Groups(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee', 'f={} n=3 key=Id asc=Yes grp=0 first=1');
        Observer.Expect('callee view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('callee groups', '-1={} 0={} 1={} 2={} 4={} n=3');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_Group0Filter_LocalProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.SetRange(Status, Row.Status::Posted);
        Observer.Observe('callee', DescribeLocal(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee', 'f={} n=3 first=1');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_Group0Filter_AfterFind()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.SetRange(Status, Row.Status::Open);
        Row.FindLast();
        Observer.Observe('caller row', Format(Row.Id));
        Observer.Observe('callee', Callee.Describe(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('caller row', '3');
        Observer.Expect('callee', 'f={} n=3 key=Id asc=Yes grp=0 first=1');
        Observer.Expect('caller after', 'f={Status: Open} n=2 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_Group1Filter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        SetGroupFilter(Row, 1);
        Observer.Observe('callee', Callee.Describe(Row));
        Observer.Observe('callee groups', Callee.Groups(Row));
        ObserveCaller(Observer, Row);
        Row.FilterGroup(1);
        Row.SetRange(Status);
        Row.FilterGroup(0);
        Observer.Expect('callee', 'f={} n=1 key=Id asc=Yes grp=0 first=2');
        Observer.Expect('callee groups', '-1={} 0={} 1={Status: Posted} 2={} 4={} n=1');
        Observer.Expect('caller after', 'f={} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_Group1Filter_OtherInstance()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
        Other: Record "BVV Row";
    begin
        Seed();
        SetGroupFilter(Row, 1);
        Other.FilterGroup(1);
        Observer.Observe('other group 1', 'f={' + Other.GetFilters() + '}');
        Other.FilterGroup(0);
        Observer.Observe('other', 'f={' + Other.GetFilters() + '} n=' + Format(Other.Count()));
        Observer.Observe('callee', Callee.Describe(Row));
        ObserveCaller(Observer, Row);
        Row.FilterGroup(1);
        Row.SetRange(Status);
        Row.FilterGroup(0);
        Observer.Observe('other after clear', 'n=' + Format(Other.Count()));
        Observer.Expect('other group 1', 'f={Status: Posted}');
        Observer.Expect('other', 'f={} n=1');
        Observer.Expect('callee', 'f={} n=1 key=Id asc=Yes grp=0 first=2');
        Observer.Expect('caller after', 'f={} n=1 grp=0');
        Observer.Expect('other after clear', 'n=3');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_Group2Filter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        SetGroupFilter(Row, 2);
        Observer.Observe('callee', Callee.Describe(Row));
        Observer.Observe('callee groups', Callee.Groups(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee', 'f={} n=3 key=Id asc=Yes grp=0 first=1');
        Observer.Expect('callee groups', '-1={} 0={} 1={} 2={} 4={} n=3');
        Observer.Expect('caller after', 'f={} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_Group4Filter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        SetGroupFilter(Row, 4);
        Observer.Observe('callee', Callee.Describe(Row));
        Observer.Observe('callee groups', Callee.Groups(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee', 'f={} n=3 key=Id asc=Yes grp=0 first=1');
        Observer.Expect('callee groups', '-1={} 0={} 1={} 2={} 4={} n=3');
        Observer.Expect('caller after', 'f={} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_GroupMinus1Filter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        SetGroupFilter(Row, -1);
        Observer.Observe('callee', Callee.Describe(Row));
        Observer.Observe('callee groups', Callee.Groups(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee', 'f={} n=3 key=Id asc=Yes grp=0 first=1');
        Observer.Expect('callee groups', '-1={} 0={} 1={} 2={} 4={} n=3');
        Observer.Expect('caller after', 'f={} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_GroupMinus1_TwoFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.FilterGroup(-1);
        Row.SetFilter(Id, '2');
        Row.SetFilter(Name, 'NOTHING');
        Row.FilterGroup(0);
        Observer.Observe('callee', Callee.Describe(Row));
        Observer.Observe('callee local', DescribeLocal(Row));
        Observer.Observe('callee groups', Callee.Groups(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee', 'f={} n=3 key=Id asc=Yes grp=0 first=1');
        Observer.Expect('callee local', 'f={} n=3 first=1');
        Observer.Expect('callee groups', '-1={} 0={} 1={} 2={} 4={} n=3');
        Observer.Expect('caller after', 'f={} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_FlowFieldFilter_Codeunit()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.SetRange("Day Filter", 1);
        Row.SetRange(Total, 0);
        Observer.Observe('callee', Callee.Describe(Row));
        Observer.Observe('callee view', Callee.View(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee', 'f={} n=3 key=Id asc=Yes grp=0 first=1');
        Observer.Expect('callee view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Day Filter: 1, Total: 0} n=2 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_FlowFieldFilter_LocalProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.SetRange("Day Filter", 1);
        Row.SetRange(Total, 0);
        Observer.Observe('callee', DescribeLocal(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee', 'f={} n=3 first=1');
        Observer.Expect('caller after', 'f={Day Filter: 1, Total: 0} n=2 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_TableProcedure_OwnRecByValue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.SetRange("Day Filter", 1);
        Row.SetRange(Total, 0);
        Row.Get(3);
        Observer.Observe('same status', Row.CountSameStatus(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('same status', 'self f={Day Filter: 1, Total: 0} copy f={} same n=1');
        Observer.Expect('caller after', 'f={Day Filter: 1, Total: 0} n=2 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_CallerInGroup2_FilterInGroup2()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.FilterGroup(2);
        Row.SetRange(Status, Row.Status::Posted);
        Observer.Observe('callee', Callee.Describe(Row));
        Observer.Observe('callee groups', Callee.Groups(Row));
        ObserveCaller(Observer, Row);
        Row.FilterGroup(0);
        Observer.Expect('callee', 'f={} n=3 key=Id asc=Yes grp=0 first=1');
        Observer.Expect('callee groups', '-1={} 0={} 1={} 2={} 4={} n=3');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=2');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_CallerInGroup2_FilterInGroup0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.SetRange(Status, Row.Status::Posted);
        Row.FilterGroup(2);
        Observer.Observe('callee', Callee.Describe(Row));
        Observer.Observe('callee groups', Callee.Groups(Row));
        ObserveCaller(Observer, Row);
        Row.FilterGroup(0);
        Observer.Expect('callee', 'f={} n=3 key=Id asc=Yes grp=0 first=1');
        Observer.Expect('callee groups', '-1={} 0={} 1={} 2={} 4={} n=3');
        Observer.Expect('caller after', 'f={} n=1 grp=2');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_Descending_NoFilter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.Ascending(false);
        Observer.Observe('callee', Callee.Describe(Row));
        Observer.Observe('caller asc', Format(Row.Ascending()));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee', 'f={} n=3 key=Id asc=Yes grp=0 first=1');
        Observer.Expect('caller asc', 'No');
        Observer.Expect('caller after', 'f={} n=3 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_Descending_Group0Filter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.Ascending(false);
        Row.SetRange(Status, Row.Status::Open);
        Observer.Observe('callee', Callee.Describe(Row));
        Observer.Observe('callee view', Callee.View(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee', 'f={} n=3 key=Id asc=Yes grp=0 first=1');
        Observer.Expect('callee view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Open} n=2 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_Marks_MarkedOnlyOff()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.Get(2);
        Row.Mark(true);
        Observer.Observe('callee marks', Callee.Marks(Row));
        Observer.Observe('callee', Callee.Describe(Row));
        Row.MarkedOnly(true);
        Observer.Observe('caller marked n', Format(Row.Count()));
        Observer.Expect('callee marks', 'mo=No n=3 marked n=0');
        Observer.Expect('callee', 'f={} n=3 key=Id asc=Yes grp=0 first=1');
        Observer.Expect('caller marked n', '1');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_Marks_MarkedOnlyOn()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.Get(2);
        Row.Mark(true);
        Row.MarkedOnly(true);
        Observer.Observe('callee marks', Callee.Marks(Row));
        Observer.Observe('callee', Callee.Describe(Row));
        Observer.Observe('caller marked n', Format(Row.Count()));
        Observer.Expect('callee marks', 'mo=No n=3 marked n=0');
        Observer.Expect('callee', 'f={} n=3 key=Id asc=Yes grp=0 first=1');
        Observer.Expect('caller marked n', '1');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_SetLoadFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.SetRange(Status, Row.Status::Posted);
        Observer.Observe('callee load', Callee.LoadFields(Row));
        Observer.Observe('callee', Callee.Describe(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee load', 'first=1 amount loaded=Yes name loaded=Yes');
        Observer.Expect('callee', 'f={} n=3 key=Id asc=Yes grp=0 first=1');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_ChangeCompany_Current()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.ChangeCompany(CompanyName());
        Row.SetRange(Status, Row.Status::Posted);
        Observer.Observe('callee company', Callee.Company(Row));
        Observer.Observe('callee', Callee.Describe(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee company', 'company=<Company> f={} n=3');
        Observer.Expect('callee', 'f={} n=3 key=Id asc=Yes grp=0 first=1');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_SecondaryKey_NoFilter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.SetCurrentKey(Name);
        Observer.Observe('callee', Callee.Describe(Row));
        Observer.Observe('callee view', Callee.View(Row));
        Observer.Observe('caller key', Row.CurrentKey());
        Observer.Expect('callee', 'f={} n=3 key=Id asc=Yes grp=0 first=1');
        Observer.Expect('callee view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller key', 'Name');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_SecondaryKey_Group0Filter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.SetCurrentKey(Name);
        Row.SetRange(Status, Row.Status::Open);
        Observer.Observe('callee', Callee.Describe(Row));
        Observer.Observe('callee view', Callee.View(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee', 'f={} n=3 key=Id asc=Yes grp=0 first=1');
        Observer.Expect('callee view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Open} n=2 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_AdHocKey_Group0Filter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.SetCurrentKey(Amount);
        Row.SetRange(Status, Row.Status::Open);
        Observer.Observe('callee', Callee.Describe(Row));
        Observer.Observe('callee view', Callee.View(Row));
        Observer.Observe('caller key', Row.CurrentKey());
        ObserveCaller(Observer, Row);
        Observer.Expect('callee', 'f={} n=3 key=Id asc=Yes grp=0 first=1');
        Observer.Expect('callee view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller key', 'Amount');
        Observer.Expect('caller after', 'f={Status: Open} n=2 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_CalcFields_FlowFilterGroup0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.Get(1);
        Row.SetFilter("Day Filter", '1');
        Observer.Observe('callee total', Callee.Total(Row));
        Row.CalcFields(Total);
        Observer.Observe('caller total', Format(Row.Total));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee total', 'id=1 total=12 f={}');
        Observer.Expect('caller total', '5');
        Observer.Expect('caller after', 'f={Day Filter: 1} n=3 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_CalcFields_FlowFilterGroup2()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.Get(1);
        Row.FilterGroup(2);
        Row.SetFilter("Day Filter", '1');
        Row.FilterGroup(0);
        Observer.Observe('callee total', Callee.Total(Row));
        Row.CalcFields(Total);
        Observer.Observe('caller total', Format(Row.Total));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee total', 'id=1 total=12 f={}');
        Observer.Expect('caller total', '5');
        Observer.Expect('caller after', 'f={} n=3 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_HandOn_Copy()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.SetRange(Status, Row.Status::Posted);
        Observer.Observe('copy', Callee.CopyTo(Row));
        Observer.Observe('copy filters', Callee.CopyFiltersTo(Row));
        Observer.Observe('recref', Callee.RecRefOf(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('copy', 'f={} n=3');
        Observer.Expect('copy filters', 'f={} n=3');
        Observer.Expect('recref', 'f={} n=3');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_HandOn_Group2_Copy()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        SetGroupFilter(Row, 2);
        Observer.Observe('copy', Callee.CopyTo(Row));
        Observer.Observe('copy filters', Callee.CopyFiltersTo(Row));
        Observer.Observe('recref', Callee.RecRefOf(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('copy', 'f={} n=3');
        Observer.Expect('copy filters', 'f={} n=3');
        Observer.Expect('recref', 'f={} n=3');
        Observer.Expect('caller after', 'f={} n=1 grp=0');
        Observer.Verify();
    end;

    local procedure PageRows(var Rows: TestPage "BVV Rows"): Text
    var
        Result: Text;
    begin
        if Rows.First() then
            repeat
                Result += Rows.Id.Value() + ' ';
            until not Rows.Next();
        Rows.Close();
        exit(Result);
    end;

    [Test]
    procedure ByValue_HandOn_PageRun()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
        Rows: TestPage "BVV Rows";
    begin
        Seed();
        Row.SetRange(Status, Row.Status::Posted);
        Rows.Trap();
        Callee.RunPage(Row);
        Observer.Observe('page rows', PageRows(Rows));
        ObserveCaller(Observer, Row);
        Observer.Expect('page rows', '1 2 3 ');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_HandOn_PageSetTableView()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
        Rows: TestPage "BVV Rows";
    begin
        Seed();
        Row.SetRange(Status, Row.Status::Posted);
        Rows.Trap();
        Callee.RunPageSetTableView(Row);
        Observer.Observe('page rows', PageRows(Rows));
        ObserveCaller(Observer, Row);
        Observer.Expect('page rows', '1 2 3 ');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_HandOn_ReportSetTableView()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
    begin
        Seed();
        Row.SetRange(Status, Row.Status::Posted);
        Callee.RunReport(Row);
        Observer.Observe('report', Log.Take());
        ObserveCaller(Observer, Row);
        Observer.Expect('report', 'report f={} n=3;row 1;row 2;row 3;');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_EventSubscriberParameter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
        Publisher: Codeunit "BVV Publisher";
    begin
        Seed();
        Row.SetRange(Status, Row.Status::Posted);
        Publisher.Raise(Row);
        Observer.Observe('subscriber', Log.Take());
        ObserveCaller(Observer, Row);
        Observer.Expect('subscriber', 'sub f={} n=3;');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_TemporaryToPlainParameter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVV Row";
        TempRow: Record "BVV Row" temporary;
    begin
        Seed();
        Row.DeleteAll();
        TempRow.Id := 1;
        TempRow.Status := TempRow.Status::Open;
        TempRow.Insert();
        TempRow.Id := 2;
        TempRow.Status := TempRow.Status::Posted;
        TempRow.Insert();
        TempRow.SetRange(Status, TempRow.Status::Posted);
        Observer.Observe('callee temp', Callee.Temp(TempRow));
        Observer.Observe('callee', Callee.Describe(TempRow));
        ObserveCaller(Observer, TempRow);
        Observer.Expect('callee temp', 'temp=No f={} n=0');
        Observer.Expect('callee', 'f={} n=0 key=Id asc=Yes grp=0 first=none');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;
}
