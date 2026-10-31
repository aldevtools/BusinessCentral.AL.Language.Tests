// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfilter/testfilter-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 91761 - 91766 (writer Y17a)
// Probe: written against SaaS BC 29 and the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: gap cycle 1, gap G6. A TestPage filter change (TestFilter.SetFilter) on a list sorted in a secondary key, when the new view
//   holds one row, no row, three rows or more rows than the TestPage window. The Customer Ledger Entries shape: List page,
//   SourceTableView = sorting("Cust No.", "Posting Date") order(descending), OnAfterGetRecord and OnAfterGetCurrRecord, and OnOpenPage
//   `if (Rec.GetFilters() <> '') and not Rec.Find() then if Rec.FindFirst() then;`. Page 91763 is the same ascending; page 91764 is a
//   Worksheet with no SourceTableView that calls SetCurrentKey in OnOpenPage (the SuRefillKey.al shape). Log: O = OnOpenPage,
//   R<n> = OnAfterGetRecord, C<n> = OnAfterGetCurrRecord, A<n> = the action, each followed by ';' (as SuRefillKey.al).
// Rows: Entry No. 1..30; Cust No. C00 for 1-3, else C<nn> (row 10 = C10); Doc Type 1 for rows 5, 15, 20, 25, 30, else 2 (25 rows);
//   Posting Date = January (n * 11 mod 30) + 1, 2024. Inserted evens first, then odds.
// BC versions: 27, 28, 29

table 91761 "LT Y17 RK Entry"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Cust No."; Code[20]) { }
        field(3; "Posting Date"; Date) { }
        field(4; "Doc Type"; Integer) { }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Cust; "Cust No.", "Posting Date") { }
    }
}

page 91762 "LT Y17 RK List Desc"
{
    PageType = List;
    SourceTable = "LT Y17 RK Entry";
    SourceTableView = sorting("Cust No.", "Posting Date") order(descending);
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Cust No."; Rec."Cust No.")
                {
                    ApplicationArea = All;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                }
                field("Doc Type"; Rec."Doc Type")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(LogRec)
            {
                ApplicationArea = All;
                Caption = 'Log Rec';
                trigger OnAction()
                begin
                    Log.Add('A' + Format(Rec."Entry No."));
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('O');
        if (Rec.GetFilters() <> '') and not Rec.Find() then
            if Rec.FindFirst() then;
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R' + Format(Rec."Entry No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec."Entry No."));
    end;

    var
        Log: Codeunit "LT Y17 RK Log";
}

page 91763 "LT Y17 RK List Asc"
{
    PageType = List;
    SourceTable = "LT Y17 RK Entry";
    SourceTableView = sorting("Cust No.", "Posting Date") order(ascending);
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Cust No."; Rec."Cust No.")
                {
                    ApplicationArea = All;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                }
                field("Doc Type"; Rec."Doc Type")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(LogRec)
            {
                ApplicationArea = All;
                Caption = 'Log Rec';
                trigger OnAction()
                begin
                    Log.Add('A' + Format(Rec."Entry No."));
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('O');
        if (Rec.GetFilters() <> '') and not Rec.Find() then
            if Rec.FindFirst() then;
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R' + Format(Rec."Entry No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec."Entry No."));
    end;

    var
        Log: Codeunit "LT Y17 RK Log";
}

page 91764 "LT Y17 RK Ws Key"
{
    PageType = Worksheet;
    SourceTable = "LT Y17 RK Entry";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Cust No."; Rec."Cust No.")
                {
                    ApplicationArea = All;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                }
                field("Doc Type"; Rec."Doc Type")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(LogRec)
            {
                ApplicationArea = All;
                Caption = 'Log Rec';
                trigger OnAction()
                begin
                    Log.Add('A' + Format(Rec."Entry No."));
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('O');
        Rec.SetCurrentKey("Cust No.", "Posting Date");
        if (Rec.GetFilters() <> '') and not Rec.Find() then
            if Rec.FindFirst() then;
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R' + Format(Rec."Entry No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec."Entry No."));
    end;

    var
        Log: Codeunit "LT Y17 RK Log";
}

codeunit 91765 "LT Y17 RK Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

codeunit 91766 "LT Y17 RK Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y17 RK Log";

    local procedure Seed()
    var
        Entry: Record "LT Y17 RK Entry";
        n: Integer;
    begin
        Entry.DeleteAll();
        for n := 1 to 15 do
            AddRow(n * 2);
        for n := 1 to 15 do
            AddRow(n * 2 - 1);
        Log.Take();
    end;

    local procedure AddRow(n: Integer)
    var
        Entry: Record "LT Y17 RK Entry";
    begin
        Entry."Entry No." := n;
        if n <= 3 then
            Entry."Cust No." := 'C00'
        else
            Entry."Cust No." := 'C' + PadStr('', 2 - StrLen(Format(n)), '0') + Format(n);
        Entry."Posting Date" := DMY2Date(((n * 11) mod 30) + 1, 1, 2024);
        if n mod 5 = 0 then
            Entry."Doc Type" := 1
        else
            Entry."Doc Type" := 2;
        if n = 10 then
            Entry."Doc Type" := 2;
        Entry.Insert();
    end;

    // Must-have, the path the blocked Microsoft tests take: many rows, then one row (both filters stay).
    [Test]
    procedure Refill_Desc_ManyThenOne()
    var
        P: TestPage "LT Y17 RK List Desc";
        Count: Integer;
        i: Integer;
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', P."Entry No.".Value() + ':' + Log.Take());
        P.Filter.SetFilter("Doc Type", '2');
        Observer.Observe('filter many', P."Entry No.".Value() + ':' + Log.Take());
        P.Filter.SetFilter("Cust No.", 'C10');
        Observer.Observe('filter one', P."Entry No.".Value() + ':' + Log.Take());
        Observer.Observe('next', Format(P.Next()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        Observer.Observe('first', Format(P.First()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        Observer.Observe('last', Format(P.Last()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        P.Close();
        Observer.Finish();
    end;

    // One row straight after the open (Desc).
    [Test]
    procedure Refill_Desc_OneRow()
    var
        P: TestPage "LT Y17 RK List Desc";
        Count: Integer;
        i: Integer;
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', P."Entry No.".Value() + ':' + Log.Take());
        P.Filter.SetFilter("Cust No.", 'C10');
        Observer.Observe('filter one', P."Entry No.".Value() + ':' + Log.Take());
        Observer.Observe('next', Format(P.Next()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        Observer.Observe('first', Format(P.First()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        P.Close();
        Observer.Finish();
    end;

    // 25 of 30 rows, more than a window (Desc): Last, First, then Next 22 times.
    [Test]
    procedure Refill_Desc_MoreThanWindow()
    var
        P: TestPage "LT Y17 RK List Desc";
        Count: Integer;
        i: Integer;
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', P."Entry No.".Value() + ':' + Log.Take());
        P.Filter.SetFilter("Doc Type", '2');
        Observer.Observe('filter many', P."Entry No.".Value() + ':' + Log.Take());
        Observer.Observe('last', Format(P.Last()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        Observer.Observe('first', Format(P.First()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        for i := 1 to 22 do
            if P.Next() then
                Count += 1;
        Observer.Observe('next 22', Format(Count) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        P.Close();
        Observer.Finish();
    end;

    // One row straight after the open (Asc).
    [Test]
    procedure Refill_Asc_OneRow()
    var
        P: TestPage "LT Y17 RK List Asc";
        Count: Integer;
        i: Integer;
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', P."Entry No.".Value() + ':' + Log.Take());
        P.Filter.SetFilter("Cust No.", 'C10');
        Observer.Observe('filter one', P."Entry No.".Value() + ':' + Log.Take());
        Observer.Observe('next', Format(P.Next()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        Observer.Observe('first', Format(P.First()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        P.Close();
        Observer.Finish();
    end;

    // 25 of 30 rows, more than a window (Asc): Last, First, then Next 22 times.
    [Test]
    procedure Refill_Asc_MoreThanWindow()
    var
        P: TestPage "LT Y17 RK List Asc";
        Count: Integer;
        i: Integer;
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', P."Entry No.".Value() + ':' + Log.Take());
        P.Filter.SetFilter("Doc Type", '2');
        Observer.Observe('filter many', P."Entry No.".Value() + ':' + Log.Take());
        Observer.Observe('last', Format(P.Last()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        Observer.Observe('first', Format(P.First()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        for i := 1 to 22 do
            if P.Next() then
                Count += 1;
        Observer.Observe('next 22', Format(Count) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        P.Close();
        Observer.Finish();
    end;

    // One row straight after the open (Ws).
    [Test]
    procedure Refill_Ws_OneRow()
    var
        P: TestPage "LT Y17 RK Ws Key";
        Count: Integer;
        i: Integer;
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', P."Entry No.".Value() + ':' + Log.Take());
        P.Filter.SetFilter("Cust No.", 'C10');
        Observer.Observe('filter one', P."Entry No.".Value() + ':' + Log.Take());
        Observer.Observe('next', Format(P.Next()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        Observer.Observe('first', Format(P.First()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        P.Close();
        Observer.Finish();
    end;

    // 25 of 30 rows, more than a window (Ws): Last, First, then Next 22 times.
    [Test]
    procedure Refill_Ws_MoreThanWindow()
    var
        P: TestPage "LT Y17 RK Ws Key";
        Count: Integer;
        i: Integer;
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', P."Entry No.".Value() + ':' + Log.Take());
        P.Filter.SetFilter("Doc Type", '2');
        Observer.Observe('filter many', P."Entry No.".Value() + ':' + Log.Take());
        Observer.Observe('last', Format(P.Last()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        Observer.Observe('first', Format(P.First()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        for i := 1 to 22 do
            if P.Next() then
                Count += 1;
        Observer.Observe('next 22', Format(Count) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        P.Close();
        Observer.Finish();
    end;

    // Three rows (C00), ties to the pinned ascending Worksheet refill (SuRefillKey.al Name_Filter_Refill).
    [Test]
    procedure Refill_Desc_ThreeRows()
    var
        P: TestPage "LT Y17 RK List Desc";
        Count: Integer;
        i: Integer;
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', P."Entry No.".Value() + ':' + Log.Take());
        P.Filter.SetFilter("Cust No.", 'C00');
        Observer.Observe('filter three', P."Entry No.".Value() + ':' + Log.Take());
        Observer.Observe('next', Format(P.Next()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        Observer.Observe('last', Format(P.Last()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        P.Close();
        Observer.Finish();
    end;

    // No row matches the new filter.
    [Test]
    procedure Refill_Desc_NoRow()
    var
        P: TestPage "LT Y17 RK List Desc";
        Count: Integer;
        i: Integer;
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', P."Entry No.".Value() + ':' + Log.Take());
        P.Filter.SetFilter("Cust No.", 'NONE');
        Observer.Observe('filter none', P."Entry No.".Value() + ':' + Log.Take());
        Observer.Observe('first', Format(P.First()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        P.Close();
        Observer.Finish();
    end;

    // One row, then an action that only logs the Rec it sees (the Apply Entries step of the Microsoft test).
    [Test]
    procedure Refill_Desc_OneRow_ThenAction()
    var
        P: TestPage "LT Y17 RK List Desc";
        Count: Integer;
        i: Integer;
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', P."Entry No.".Value() + ':' + Log.Take());
        P.Filter.SetFilter("Cust No.", 'C10');
        Observer.Observe('filter one', P."Entry No.".Value() + ':' + Log.Take());
        P.LogRec.Invoke();
        Observer.Observe('action', P."Entry No.".Value() + ':' + Log.Take());
        P.Close();
        Observer.Finish();
    end;
}
