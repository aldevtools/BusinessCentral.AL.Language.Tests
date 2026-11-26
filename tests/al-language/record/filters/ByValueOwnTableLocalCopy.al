// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods/devenv-passing-parameters
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 77370..77373 (BVO Item, BVO Entry, BVO Item Ext,
//   BVO By Value Local Copy Tests)
// local object: the by-value parameter of a procedure of a table and of a table extension (its own table), with a FlowFilter
//   and a FlowField of that table, is what is under test.
// Probe (al-runner issue 8596): a procedure of a table takes a LOCAL record of its own table (Get), sets a view on it and hands
//   it by value to a local procedure of the same object. The callee describes the copy, sets one filter and describes it again;
//   back in the caller, the caller's record is described. ByValueRecordView.al measured Rec.Proc(Rec) (the table procedure's
//   own Rec as the argument) and a codeunit callee; this file measures a local record of the table as the argument, in the
//   table itself and in a table extension of it.
// Table "BVO Item": Amount, a FlowFilter "Date Filter" and a FlowField Net = sum of "BVO Entry".Amount over "Date Filter".
//   Row A1 (Amount 5) has entries 100 on 2026-01-10 and -40 on 2026-03-10; row A2 has Amount 0 and no entries.
// Cells (12): CallerT (table) and CallerX (table extension); the caller's view none, SetFilter("Date Filter", '..%1',
//   2026-01-31) or SetFilter(Amount, '<>%1', 0); the callee's operation SetFilter("Date Filter", '..%1', 2026-12-31) or
//   SetFilter(Amount, '<>%1', 0).
// Describe reads, in this order: No., CalcFields(Net) and Net, FilterGroup(), the rows a FindSet loop visits (which leaves the
//   record on the last row), Count, GetFilters, GetFilter("Date Filter"), GetFilter(Amount). Each test asserts the whole text.
// Facts (measured on BC 29 (Linux host) with an invented app, each test run alone; this pull request's CI checks 27.5, 28.5
//   and 29.0), the same in all 12 cells, table and table extension alike:
//   - inside, before the operation, the copy has no filters: GetFilters, GetFilter("Date Filter") and GetFilter(Amount) are
//     empty, FilterGroup() is 0, Count and the FindSet rows are 2 and Net is 60 (no FlowFilter), also when the caller's view
//     was "Date Filter" '..01/31/26' or Amount '<>0'. The copy keeps the row's values (No. A1);
//   - after the operation, only its own filter: 'Date Filter: ..12/31/26' with Count 2, or 'Amount: <>0' with Count 1;
//     FilterGroup() 0 (No. A2 and Net 0: the first Describe's FindSet loop left the copy on the last row);
//   - back in the caller, its own view is unchanged: no filter (Net 60, Count 2), 'Date Filter: ..01/31/26' (Net 100,
//     Count 2) or 'Amount: <>0' (Net 60, Count 1); No. A1, FilterGroup() 0.
// BC versions: 27.5, 28.5, 29.0

table 77370 "BVO Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Amount; Decimal) { }
        field(3; "Date Filter"; Date) { FieldClass = FlowFilter; }
        field(4; Net; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("BVO Entry".Amount where("Item No." = field("No."), "Posting Date" = field("Date Filter")));
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    // The caller: a local record of this table, Get of this row's No., the caller's view, then the by-value call.
    procedure CallerT(View: Integer; Op: Integer): Text
    var
        Item: Record "BVO Item";
        Inside: Text;
    begin
        Item.Get("No.");
        SetView(Item, View);
        Inside := CalleeT(Item, Op);
        exit('inside: ' + Inside + ' || caller after: ' + Describe(Item));
    end;

    local procedure CalleeT(Item: Record "BVO Item"; Op: Integer): Text
    var
        Before: Text;
    begin
        Before := Describe(Item);
        DoOp(Item, Op);
        exit('before op: ' + Before + ' ; after op: ' + Describe(Item));
    end;

    procedure SetView(var Item: Record "BVO Item"; View: Integer)
    begin
        case View of
            1:
                Item.SetFilter("Date Filter", '..%1', 20260131D);
            2:
                Item.SetFilter(Amount, '<>%1', 0);
        end;
    end;

    procedure DoOp(var Item: Record "BVO Item"; Op: Integer)
    begin
        case Op of
            1:
                Item.SetFilter("Date Filter", '..%1', 20261231D);
            2:
                Item.SetFilter(Amount, '<>%1', 0);
        end;
    end;

    procedure Describe(var Item: Record "BVO Item"): Text
    var
        G: Integer;
        Seen: Integer;
        N: Decimal;
        No: Code[20];
    begin
        No := Item."No.";
        Item.CalcFields(Net);
        N := Item.Net;
        G := Item.FilterGroup();
        if Item.FindSet() then
            repeat
                Seen += 1;
            until Item.Next() = 0;
        exit(StrSubstNo('No.=%1 Net=%2 Count=%3 FindSet rows=%4 GetFilters=[%5] g0 DateFilter=[%6] g0 Amount=[%7] FilterGroup()=%8',
            No, N, Item.Count(), Seen, Item.GetFilters(), Item.GetFilter("Date Filter"), Item.GetFilter(Amount), G));
    end;
}

table 77371 "BVO Entry"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Item No."; Code[20]) { }
        field(3; "Posting Date"; Date) { }
        field(4; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

// The same caller and callee as procedures of a table extension (the shape the runner meets).
tableextension 77372 "BVO Item Ext" extends "BVO Item"
{
    procedure CallerX(View: Integer; Op: Integer): Text
    var
        Item: Record "BVO Item";
        Inside: Text;
    begin
        Item.Get("No.");
        SetView(Item, View);
        Inside := CalleeX(Item, Op);
        exit('inside: ' + Inside + ' || caller after: ' + Describe(Item));
    end;

    local procedure CalleeX(Item: Record "BVO Item"; Op: Integer): Text
    var
        Before: Text;
    begin
        Before := Describe(Item);
        DoOp(Item, Op);
        exit('before op: ' + Before + ' ; after op: ' + Describe(Item));
    end;
}

codeunit 77373 "BVO By Value Local Copy Tests"
{
    Subtype = Test;

    // CallerT / CallerX (View, Op). View: 0 none, 1 "Date Filter" '..01/31/26', 2 Amount '<>0'.
    // Op: 1 "Date Filter" '..12/31/26', 2 Amount '<>0'.

    [Test]
    procedure ByValueLocal_Table_NoView_DateOp_CopyHasNoFilters()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVO Item";
    begin
        Setup(Item);
        Observer.Observe('readings', Item.CallerT(0, 1));
        Observer.Expect('readings', 'inside: before op: No.=A1 Net=60 Count=2 FindSet rows=2 GetFilters=[] g0 DateFilter=[] g0 Amount=[] FilterGroup()=0 ; after op: No.=A2 Net=0 Count=2 FindSet rows=2 GetFilters=[Date Filter: ..12/31/26] g0 DateFilter=[..12/31/26] g0 Amount=[] FilterGroup()=0 || caller after: No.=A1 Net=60 Count=2 FindSet rows=2 GetFilters=[] g0 DateFilter=[] g0 Amount=[] FilterGroup()=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLocal_Table_NoView_AmountOp_CopyHasNoFilters()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVO Item";
    begin
        Setup(Item);
        Observer.Observe('readings', Item.CallerT(0, 2));
        Observer.Expect('readings', 'inside: before op: No.=A1 Net=60 Count=2 FindSet rows=2 GetFilters=[] g0 DateFilter=[] g0 Amount=[] FilterGroup()=0 ; after op: No.=A2 Net=0 Count=1 FindSet rows=1 GetFilters=[Amount: <>0] g0 DateFilter=[] g0 Amount=[<>0] FilterGroup()=0 || caller after: No.=A1 Net=60 Count=2 FindSet rows=2 GetFilters=[] g0 DateFilter=[] g0 Amount=[] FilterGroup()=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLocal_Table_DateView_DateOp_CopyHasNoFilters()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVO Item";
    begin
        Setup(Item);
        Observer.Observe('readings', Item.CallerT(1, 1));
        Observer.Expect('readings', 'inside: before op: No.=A1 Net=60 Count=2 FindSet rows=2 GetFilters=[] g0 DateFilter=[] g0 Amount=[] FilterGroup()=0 ; after op: No.=A2 Net=0 Count=2 FindSet rows=2 GetFilters=[Date Filter: ..12/31/26] g0 DateFilter=[..12/31/26] g0 Amount=[] FilterGroup()=0 || caller after: No.=A1 Net=100 Count=2 FindSet rows=2 GetFilters=[Date Filter: ..01/31/26] g0 DateFilter=[..01/31/26] g0 Amount=[] FilterGroup()=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLocal_Table_DateView_AmountOp_CopyHasNoFilters()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVO Item";
    begin
        Setup(Item);
        Observer.Observe('readings', Item.CallerT(1, 2));
        Observer.Expect('readings', 'inside: before op: No.=A1 Net=60 Count=2 FindSet rows=2 GetFilters=[] g0 DateFilter=[] g0 Amount=[] FilterGroup()=0 ; after op: No.=A2 Net=0 Count=1 FindSet rows=1 GetFilters=[Amount: <>0] g0 DateFilter=[] g0 Amount=[<>0] FilterGroup()=0 || caller after: No.=A1 Net=100 Count=2 FindSet rows=2 GetFilters=[Date Filter: ..01/31/26] g0 DateFilter=[..01/31/26] g0 Amount=[] FilterGroup()=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLocal_Table_AmountView_DateOp_CopyHasNoFilters()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVO Item";
    begin
        Setup(Item);
        Observer.Observe('readings', Item.CallerT(2, 1));
        Observer.Expect('readings', 'inside: before op: No.=A1 Net=60 Count=2 FindSet rows=2 GetFilters=[] g0 DateFilter=[] g0 Amount=[] FilterGroup()=0 ; after op: No.=A2 Net=0 Count=2 FindSet rows=2 GetFilters=[Date Filter: ..12/31/26] g0 DateFilter=[..12/31/26] g0 Amount=[] FilterGroup()=0 || caller after: No.=A1 Net=60 Count=1 FindSet rows=1 GetFilters=[Amount: <>0] g0 DateFilter=[] g0 Amount=[<>0] FilterGroup()=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLocal_Table_AmountView_AmountOp_CopyHasNoFilters()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVO Item";
    begin
        Setup(Item);
        Observer.Observe('readings', Item.CallerT(2, 2));
        Observer.Expect('readings', 'inside: before op: No.=A1 Net=60 Count=2 FindSet rows=2 GetFilters=[] g0 DateFilter=[] g0 Amount=[] FilterGroup()=0 ; after op: No.=A2 Net=0 Count=1 FindSet rows=1 GetFilters=[Amount: <>0] g0 DateFilter=[] g0 Amount=[<>0] FilterGroup()=0 || caller after: No.=A1 Net=60 Count=1 FindSet rows=1 GetFilters=[Amount: <>0] g0 DateFilter=[] g0 Amount=[<>0] FilterGroup()=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLocal_TableExt_NoView_DateOp_CopyHasNoFilters()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVO Item";
    begin
        Setup(Item);
        Observer.Observe('readings', Item.CallerX(0, 1));
        Observer.Expect('readings', 'inside: before op: No.=A1 Net=60 Count=2 FindSet rows=2 GetFilters=[] g0 DateFilter=[] g0 Amount=[] FilterGroup()=0 ; after op: No.=A2 Net=0 Count=2 FindSet rows=2 GetFilters=[Date Filter: ..12/31/26] g0 DateFilter=[..12/31/26] g0 Amount=[] FilterGroup()=0 || caller after: No.=A1 Net=60 Count=2 FindSet rows=2 GetFilters=[] g0 DateFilter=[] g0 Amount=[] FilterGroup()=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLocal_TableExt_NoView_AmountOp_CopyHasNoFilters()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVO Item";
    begin
        Setup(Item);
        Observer.Observe('readings', Item.CallerX(0, 2));
        Observer.Expect('readings', 'inside: before op: No.=A1 Net=60 Count=2 FindSet rows=2 GetFilters=[] g0 DateFilter=[] g0 Amount=[] FilterGroup()=0 ; after op: No.=A2 Net=0 Count=1 FindSet rows=1 GetFilters=[Amount: <>0] g0 DateFilter=[] g0 Amount=[<>0] FilterGroup()=0 || caller after: No.=A1 Net=60 Count=2 FindSet rows=2 GetFilters=[] g0 DateFilter=[] g0 Amount=[] FilterGroup()=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLocal_TableExt_DateView_DateOp_CopyHasNoFilters()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVO Item";
    begin
        Setup(Item);
        Observer.Observe('readings', Item.CallerX(1, 1));
        Observer.Expect('readings', 'inside: before op: No.=A1 Net=60 Count=2 FindSet rows=2 GetFilters=[] g0 DateFilter=[] g0 Amount=[] FilterGroup()=0 ; after op: No.=A2 Net=0 Count=2 FindSet rows=2 GetFilters=[Date Filter: ..12/31/26] g0 DateFilter=[..12/31/26] g0 Amount=[] FilterGroup()=0 || caller after: No.=A1 Net=100 Count=2 FindSet rows=2 GetFilters=[Date Filter: ..01/31/26] g0 DateFilter=[..01/31/26] g0 Amount=[] FilterGroup()=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLocal_TableExt_DateView_AmountOp_CopyHasNoFilters()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVO Item";
    begin
        Setup(Item);
        Observer.Observe('readings', Item.CallerX(1, 2));
        Observer.Expect('readings', 'inside: before op: No.=A1 Net=60 Count=2 FindSet rows=2 GetFilters=[] g0 DateFilter=[] g0 Amount=[] FilterGroup()=0 ; after op: No.=A2 Net=0 Count=1 FindSet rows=1 GetFilters=[Amount: <>0] g0 DateFilter=[] g0 Amount=[<>0] FilterGroup()=0 || caller after: No.=A1 Net=100 Count=2 FindSet rows=2 GetFilters=[Date Filter: ..01/31/26] g0 DateFilter=[..01/31/26] g0 Amount=[] FilterGroup()=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLocal_TableExt_AmountView_DateOp_CopyHasNoFilters()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVO Item";
    begin
        Setup(Item);
        Observer.Observe('readings', Item.CallerX(2, 1));
        Observer.Expect('readings', 'inside: before op: No.=A1 Net=60 Count=2 FindSet rows=2 GetFilters=[] g0 DateFilter=[] g0 Amount=[] FilterGroup()=0 ; after op: No.=A2 Net=0 Count=2 FindSet rows=2 GetFilters=[Date Filter: ..12/31/26] g0 DateFilter=[..12/31/26] g0 Amount=[] FilterGroup()=0 || caller after: No.=A1 Net=60 Count=1 FindSet rows=1 GetFilters=[Amount: <>0] g0 DateFilter=[] g0 Amount=[<>0] FilterGroup()=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLocal_TableExt_AmountView_AmountOp_CopyHasNoFilters()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "BVO Item";
    begin
        Setup(Item);
        Observer.Observe('readings', Item.CallerX(2, 2));
        Observer.Expect('readings', 'inside: before op: No.=A1 Net=60 Count=2 FindSet rows=2 GetFilters=[] g0 DateFilter=[] g0 Amount=[] FilterGroup()=0 ; after op: No.=A2 Net=0 Count=1 FindSet rows=1 GetFilters=[Amount: <>0] g0 DateFilter=[] g0 Amount=[<>0] FilterGroup()=0 || caller after: No.=A1 Net=60 Count=1 FindSet rows=1 GetFilters=[Amount: <>0] g0 DateFilter=[] g0 Amount=[<>0] FilterGroup()=0');
        Observer.Verify();
    end;

    // Inserts the rows when they are missing (rows stay between the tests of the codeunit), then gets A1.
    local procedure Setup(var Item: Record "BVO Item")
    var
        Item2: Record "BVO Item";
        Entry: Record "BVO Entry";
    begin
        if not Item.Get('A1') then begin
            Item."No." := 'A1';
            Item.Amount := 5;
            Item.Insert();
            Item2."No." := 'A2';
            Item2.Amount := 0;
            Item2.Insert();
            Entry."Entry No." := 1;
            Entry."Item No." := 'A1';
            Entry."Posting Date" := 20260110D;
            Entry.Amount := 100;
            Entry.Insert();
            Entry."Entry No." := 2;
            Entry."Posting Date" := 20260310D;
            Entry.Amount := -40;
            Entry.Insert();
        end;
        Item.Get('A1');
    end;
}
