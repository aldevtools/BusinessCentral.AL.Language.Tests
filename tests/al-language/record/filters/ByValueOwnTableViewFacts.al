// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods/devenv-passing-parameters
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-filtergroup-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 73790..73793 (BVF Item, BVF Entry, BVF Item Ext, BVF View Facts Tests)
// local object: the by-value parameter of a procedure of a table and of a table extension (its own table) is what is under test.
// Probe (al-runner issue 8596, the view facts named in the review of al-runner pull request 9317): the shape of
//   ByValueOwnTableLocalCopy.al (corpus PR 1578): a procedure of a table, or of a table extension, takes a LOCAL record of its
//   own table (Get of this row's No.), sets a view on it and hands it by value to a procedure of the same object. That file
//   measures one filter or none, in group 0, on the primary key, ascending, no marks, no SetLoadFields, no CalcFields before the
//   hand-off and a local callee. This file measures the other view facts, one per cell:
//      0 NoView: no view (control: CurrentKey, AreFieldsLoaded and the rest of the default view).
//      1 TwoFlowFiltersCalcFields: SetFilter("Date Filter", ..01/31/26), SetFilter("Kind Filter", 7), CalcFields(Net) before the hand-off (the issue's shape).
//      2 GlobalCallee: SetFilter("Date Filter", ..01/31/26), handed to a global (not local) procedure.
//      3 FilterGroup2: SetFilter(Amount, <>0) in filter group 2, then FilterGroup(0).
//      4 FilterGroupMinus1: SetFilter(Amount, <>0) in filter group -1, then FilterGroup(0).
//      5 CallerInGroup2: FilterGroup(2), SetFilter(Amount, <>0), handed off while the caller is in group 2.
//      6 SecondaryKeyOneFilter: SetCurrentKey(Amount, "No."), SetFilter(Amount, <>0).
//      7 SecondaryKeyNoFilter: SetCurrentKey(Amount, "No.") only (control).
//      8 Descending: Ascending(false).
//      9 MarksMarkedOnly: Mark(true) on A3 and A1, MarkedOnly(true).
//     10 SetLoadFieldsBeforeRead: SetLoadFields(Amount) before the Get.
//     11 TwoNormalFilters: SetFilter(Amount, <>0), SetFilter(Kind, 1).
//   The callee describes the copy; back in the caller, the caller's record is described. Describe reads, in this order: No.,
//   FilterGroup(), CurrentKey, Ascending, MarkedOnly, AreFieldsLoaded(Kind), GetFilters in groups 0, 2 and -1 (each read in a
//   TryFunction; the group is set back afterwards), CalcFields(Net) and Net, Count and the rows a FindSet loop visits, in
//   order. Each cell runs for the table (CallerT) and the table extension (CallerX).
// Table "BVF Item": Amount, Kind, FlowFilters "Date Filter" and "Kind Filter", a FlowField Net = sum of "BVF Entry".Amount over
//   both, keys PK ("No.") and ByAmount (Amount, "No."). Rows A1 (Amount 5, Kind 1), A2 (Amount 0, Kind 2), A3 (Amount 7, Kind 1);
//   A1 has entries 100 (2026-01-10, Kind 7) and -40 (2026-03-10, Kind 3). The caller runs on row A1.
//   Not probed: a key with a descending field (AL keys have no per-field direction).
//   Measured on a local BC 29.0.54011.57673 service tier (Linux, W1, en-US session) on 2026-11-27 with an invented app holding
//   these objects, through the dev endpoint's TestRunnerHub; the values are those readings, turned into Expect and Verify by
//   convert.py verbatim. This pull request's CI checks them on 27.5, 28.5 and 29.0; a version difference gets a version guard.
//   Facts (BC 29.0.54011.57673), the same in all 24 cells, table and table extension alike: inside the callee the copy has the
//   default view whatever the caller set: no filter in group 0, 2 or -1, FilterGroup() 0, CurrentKey No., Ascending Yes,
//   MarkedOnly No, AreFieldsLoaded(Kind) Yes, Net 60 (no FlowFilter), Count 3 and the rows A1 A2 A3 in primary key order; it keeps
//   the row's values (No. A1). Back in the caller its own view is unchanged (its filters in their groups, its key, its order, its
//   marks with MarkedOnly). AreFieldsLoaded(Kind) reads Yes in the caller too after SetLoadFields(Amount) and Get, so the
//   SetLoadFields cell does not tell a load request apart on this tier.
// BC versions: 27, 28, 29 by CI

table 73790 "BVF Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Amount; Decimal) { }
        field(3; Kind; Integer) { }
        field(4; "Date Filter"; Date) { FieldClass = FlowFilter; }
        field(5; "Kind Filter"; Integer) { FieldClass = FlowFilter; }
        field(6; Net; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("BVF Entry".Amount where("Item No." = field("No."), "Posting Date" = field("Date Filter"), Kind = field("Kind Filter")));
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(ByAmount; Amount, "No.") { }
    }

    // The caller: a local record of this table with this row's No., the view of the shape, then the by-value call.
    procedure CallerT(Shape: Integer): Text
    var
        Item: Record "BVF Item";
        Inside: Text;
    begin
        Prepare(Item, Shape, "No.");
        if Shape = 2 then
            Inside := CalleeGlobalT(Item)
        else
            Inside := CalleeT(Item);
        if Shape = 5 then
            Item.FilterGroup(0);
        exit('inside: ' + Inside + ' || caller after: ' + Describe(Item));
    end;

    local procedure CalleeT(Item: Record "BVF Item"): Text
    begin
        exit(Describe(Item));
    end;

    procedure CalleeGlobalT(Item: Record "BVF Item"): Text
    begin
        exit(Describe(Item));
    end;

    procedure Prepare(var Item: Record "BVF Item"; Shape: Integer; No: Code[20])
    var
        Other: Record "BVF Item";
    begin
        if Shape = 10 then
            Item.SetLoadFields(Amount);
        Item.Get(No);
        case Shape of
            1:
                begin
                    Item.SetFilter("Date Filter", '..%1', 20260131D);
                    Item.SetFilter("Kind Filter", '%1', 7);
                    Item.CalcFields(Net);
                end;
            2:
                Item.SetFilter("Date Filter", '..%1', 20260131D);
            3:
                begin
                    Item.FilterGroup(2);
                    Item.SetFilter(Amount, '<>%1', 0);
                    Item.FilterGroup(0);
                end;
            4:
                begin
                    Item.FilterGroup(-1);
                    Item.SetFilter(Amount, '<>%1', 0);
                    Item.FilterGroup(0);
                end;
            5:
                begin
                    Item.FilterGroup(2);
                    Item.SetFilter(Amount, '<>%1', 0);
                end;
            6:
                begin
                    Item.SetCurrentKey(Amount, "No.");
                    Item.SetFilter(Amount, '<>%1', 0);
                end;
            7:
                Item.SetCurrentKey(Amount, "No.");
            8:
                Item.Ascending(false);
            9:
                begin
                    Other.Get('A3');
                    Item := Other;
                    Item.Mark(true);
                    Item.Get(No);
                    Item.Mark(true);
                    Item.MarkedOnly(true);
                end;
            11:
                begin
                    Item.SetFilter(Amount, '<>%1', 0);
                    Item.SetFilter(Kind, '%1', 1);
                end;
        end;
    end;

    [TryFunction]
    local procedure TryGroupFilters(var Item: Record "BVF Item"; Group: Integer; var Result: Text)
    begin
        Item.FilterGroup(Group);
        Result := Item.GetFilters();
    end;

    local procedure GroupFilters(var Item: Record "BVF Item"; Group: Integer; Current: Integer): Text
    var
        Result: Text;
        T: Text;
    begin
        ClearLastError();
        if TryGroupFilters(Item, Group, Result) then
            T := '[' + Result + ']'
        else
            T := 'E: ' + GetLastErrorText();
        ClearLastError();
        Item.FilterGroup(Current);
        exit(T);
    end;

    procedure Describe(var Item: Record "BVF Item"): Text
    var
        G: Integer;
        Rows: Text;
        Head: Text;
        Filters: Text;
    begin
        G := Item.FilterGroup();
        Head := StrSubstNo('No.=%1 FilterGroup()=%2 CurrentKey=%3 Ascending=%4 MarkedOnly=%5 AreFieldsLoaded(Kind)=%6',
            Item."No.", G, Item.CurrentKey(), Item.Ascending(), Item.MarkedOnly(), Item.AreFieldsLoaded(Kind));
        Filters := StrSubstNo('g0=%1 g2=%2 g-1=%3', GroupFilters(Item, 0, G), GroupFilters(Item, 2, G), GroupFilters(Item, -1, G));
        Item.CalcFields(Net);
        Head += StrSubstNo(' Net=%1', Item.Net);
        if Item.FindSet() then
            repeat
                Rows += Item."No." + ' ';
            until Item.Next() = 0;
        exit(StrSubstNo('%1 %2 Count=%3 Rows=[%4]', Head, Filters, Item.Count(), Rows.TrimEnd()));
    end;
}

table 73791 "BVF Entry"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Item No."; Code[20]) { }
        field(3; "Posting Date"; Date) { }
        field(4; Kind; Integer) { }
        field(5; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

// The same caller and callees as procedures of a table extension.
tableextension 73792 "BVF Item Ext" extends "BVF Item"
{
    procedure CallerX(Shape: Integer): Text
    var
        Item: Record "BVF Item";
        Inside: Text;
    begin
        Prepare(Item, Shape, "No.");
        if Shape = 2 then
            Inside := CalleeGlobalX(Item)
        else
            Inside := CalleeX(Item);
        if Shape = 5 then
            Item.FilterGroup(0);
        exit('inside: ' + Inside + ' || caller after: ' + Describe(Item));
    end;

    local procedure CalleeX(Item: Record "BVF Item"): Text
    begin
        exit(Describe(Item));
    end;

    procedure CalleeGlobalX(Item: Record "BVF Item"): Text
    begin
        exit(Describe(Item));
    end;
}

codeunit 73793 "BVF View Facts Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Item: Record "BVF Item";
        Entry: Record "BVF Entry";
    begin
        Item.DeleteAll();
        Entry.DeleteAll();
        AddItem('A1', 5, 1);
        AddItem('A2', 0, 2);
        AddItem('A3', 7, 1);
        AddEntry(1, 'A1', 20260110D, 7, 100);
        AddEntry(2, 'A1', 20260310D, 3, -40);
    end;

    local procedure AddItem(No: Code[20]; Amt: Decimal; K: Integer)
    var
        Item: Record "BVF Item";
    begin
        Item.Init();
        Item."No." := No;
        Item.Amount := Amt;
        Item.Kind := K;
        Item.Insert();
    end;

    local procedure AddEntry(EntryNo: Integer; ItemNo: Code[20]; D: Date; K: Integer; Amt: Decimal)
    var
        Entry: Record "BVF Entry";
    begin
        Entry.Init();
        Entry."Entry No." := EntryNo;
        Entry."Item No." := ItemNo;
        Entry."Posting Date" := D;
        Entry.Kind := K;
        Entry.Amount := Amt;
        Entry.Insert();
    end;

    // Table: no view (control: CurrentKey, AreFieldsLoaded and the rest of the default view).
    [Test]
    procedure Table_NoView()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerT(0);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Verify();
    end;

    // Table extension: no view (control: CurrentKey, AreFieldsLoaded and the rest of the default view).
    [Test]
    procedure Ext_NoView()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerX(0);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Verify();
    end;

    // Table: SetFilter("Date Filter", ..01/31/26), SetFilter("Kind Filter", 7), CalcFields(Net) before the hand-off (the issue's shape).
    [Test]
    procedure Table_TwoFlowFiltersCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerT(1);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=100 g0=[Date Filter: ..01/31/26, Kind Filter: 7] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Verify();
    end;

    // Table extension: SetFilter("Date Filter", ..01/31/26), SetFilter("Kind Filter", 7), CalcFields(Net) before the hand-off (the issue's shape).
    [Test]
    procedure Ext_TwoFlowFiltersCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerX(1);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=100 g0=[Date Filter: ..01/31/26, Kind Filter: 7] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Verify();
    end;

    // Table: SetFilter("Date Filter", ..01/31/26), handed to a global (not local) procedure.
    [Test]
    procedure Table_GlobalCallee()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerT(2);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=100 g0=[Date Filter: ..01/31/26] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Verify();
    end;

    // Table extension: SetFilter("Date Filter", ..01/31/26), handed to a global (not local) procedure.
    [Test]
    procedure Ext_GlobalCallee()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerX(2);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=100 g0=[Date Filter: ..01/31/26] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Verify();
    end;

    // Table: SetFilter(Amount, <>0) in filter group 2, then FilterGroup(0).
    [Test]
    procedure Table_FilterGroup2()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerT(3);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[Amount: <>0] g-1=[] Count=2 Rows=[A1 A3]');
        Observer.Verify();
    end;

    // Table extension: SetFilter(Amount, <>0) in filter group 2, then FilterGroup(0).
    [Test]
    procedure Ext_FilterGroup2()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerX(3);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[Amount: <>0] g-1=[] Count=2 Rows=[A1 A3]');
        Observer.Verify();
    end;

    // Table: SetFilter(Amount, <>0) in filter group -1, then FilterGroup(0).
    [Test]
    procedure Table_FilterGroupMinus1()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerT(4);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[Amount: <>0] Count=2 Rows=[A1 A3]');
        Observer.Verify();
    end;

    // Table extension: SetFilter(Amount, <>0) in filter group -1, then FilterGroup(0).
    [Test]
    procedure Ext_FilterGroupMinus1()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerX(4);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[Amount: <>0] Count=2 Rows=[A1 A3]');
        Observer.Verify();
    end;

    // Table: FilterGroup(2), SetFilter(Amount, <>0), handed off while the caller is in group 2.
    [Test]
    procedure Table_CallerInGroup2()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerT(5);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[Amount: <>0] g-1=[] Count=2 Rows=[A1 A3]');
        Observer.Verify();
    end;

    // Table extension: FilterGroup(2), SetFilter(Amount, <>0), handed off while the caller is in group 2.
    [Test]
    procedure Ext_CallerInGroup2()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerX(5);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[Amount: <>0] g-1=[] Count=2 Rows=[A1 A3]');
        Observer.Verify();
    end;

    // Table: SetCurrentKey(Amount, "No."), SetFilter(Amount, <>0).
    [Test]
    procedure Table_SecondaryKeyOneFilter()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerT(6);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=Amount,No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[Amount: <>0] g2=[] g-1=[] Count=2 Rows=[A1 A3]');
        Observer.Verify();
    end;

    // Table extension: SetCurrentKey(Amount, "No."), SetFilter(Amount, <>0).
    [Test]
    procedure Ext_SecondaryKeyOneFilter()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerX(6);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=Amount,No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[Amount: <>0] g2=[] g-1=[] Count=2 Rows=[A1 A3]');
        Observer.Verify();
    end;

    // Table: SetCurrentKey(Amount, "No.") only (control).
    [Test]
    procedure Table_SecondaryKeyNoFilter()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerT(7);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=Amount,No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A2 A1 A3]');
        Observer.Verify();
    end;

    // Table extension: SetCurrentKey(Amount, "No.") only (control).
    [Test]
    procedure Ext_SecondaryKeyNoFilter()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerX(7);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=Amount,No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A2 A1 A3]');
        Observer.Verify();
    end;

    // Table: Ascending(false).
    [Test]
    procedure Table_Descending()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerT(8);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=No MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A3 A2 A1]');
        Observer.Verify();
    end;

    // Table extension: Ascending(false).
    [Test]
    procedure Ext_Descending()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerX(8);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=No MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A3 A2 A1]');
        Observer.Verify();
    end;

    // Table: Mark(true) on A3 and A1, MarkedOnly(true).
    [Test]
    procedure Table_MarksMarkedOnly()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerT(9);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=Yes AreFieldsLoaded(Kind)=Yes Net=60 g0=[Marked: Yes] g2=[Marked: Yes] g-1=[Marked: Yes] Count=2 Rows=[A1 A3]');
        Observer.Verify();
    end;

    // Table extension: Mark(true) on A3 and A1, MarkedOnly(true).
    [Test]
    procedure Ext_MarksMarkedOnly()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerX(9);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=Yes AreFieldsLoaded(Kind)=Yes Net=60 g0=[Marked: Yes] g2=[Marked: Yes] g-1=[Marked: Yes] Count=2 Rows=[A1 A3]');
        Observer.Verify();
    end;

    // Table: SetLoadFields(Amount) before the Get.
    [Test]
    procedure Table_SetLoadFieldsBeforeRead()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerT(10);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Verify();
    end;

    // Table extension: SetLoadFields(Amount) before the Get.
    [Test]
    procedure Ext_SetLoadFieldsBeforeRead()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerX(10);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Verify();
    end;

    // Table: SetFilter(Amount, <>0), SetFilter(Kind, 1).
    [Test]
    procedure Table_TwoNormalFilters()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerT(11);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[Amount: <>0, Kind: 1] g2=[] g-1=[] Count=2 Rows=[A1 A3]');
        Observer.Verify();
    end;

    // Table extension: SetFilter(Amount, <>0), SetFilter(Kind, 1).
    [Test]
    procedure Ext_TwoNormalFilters()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVF Item";
        T: Text;
    begin
        Seed();
        Item.Get('A1');
        T := Item.CallerX(11);
        Observer.Observe('inside', T.Substring(1, T.IndexOf(' || ') - 1));
        Observer.Observe('caller_after', T.Substring(T.IndexOf(' || ') + 4));
        Observer.Expect('inside', 'inside: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[] g2=[] g-1=[] Count=3 Rows=[A1 A2 A3]');
        Observer.Expect('caller_after', 'caller after: No.=A1 FilterGroup()=0 CurrentKey=No. Ascending=Yes MarkedOnly=No AreFieldsLoaded(Kind)=Yes Net=60 g0=[Amount: <>0, Kind: 1] g2=[] g-1=[] Count=2 Rows=[A1 A3]');
        Observer.Verify();
    end;
}
