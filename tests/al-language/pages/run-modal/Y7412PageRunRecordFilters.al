// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-run-method
// Scope: in-scope (Cloud). TestPage handlers.
// local object: the table's LookupPageId and its secondary key, with the filters a caller sets on it, are what is under test
// Fixtures used: Probe Observer (codeunit 69160); own table 99960, page 99961, test codeunit 99962
// Probe (al-runner issue 7412): Page.Run(0, Rec), Page.Run(Page::X, Rec) and Page.RunModal(0, Rec) on a list page without triggers, where the record
//   carries filters (some on the secondary key, some not) and a current key. The handler reads the rows First / Next walk through, GoToKey of each of
//   the three rows (found, or the error text and code) and the filters of the page's Rec.
// BC versions: 27, 28, 29

table 99960 "LT K12 Ledger Entry"
{
    DataClassification = SystemMetadata;
    LookupPageId = "LT K12 Ledger Entries";
    DrillDownPageId = "LT K12 Ledger Entries";

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Case No."; Code[20]) { }
        field(3; Open; Boolean) { }
        field(4; "Due Date"; Date) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ByCase; "Case No.", Open) { }
    }
}

page 99961 "LT K12 Ledger Entries"
{
    PageType = List;
    SourceTable = "LT K12 Ledger Entry";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Case No."; Rec."Case No.") { ApplicationArea = All; }
                field(Open; Rec.Open) { ApplicationArea = All; }
                field("Due Date"; Rec."Due Date") { ApplicationArea = All; }
            }
        }
    }
}

codeunit 99962 "LT K12 Page Run Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seen: Text;

    // Row 1: not open. Row 2: open, due yesterday. Row 3: open, due in a month. Row 4: open, due yesterday, another case.
    local procedure Seed()
    var
        Entry: Record "LT K12 Ledger Entry";
    begin
        Entry.DeleteAll();
        Entry."Entry No." := 1;
        Entry."Case No." := 'C1';
        Entry.Open := false;
        Entry."Due Date" := Today() - 1;
        Entry.Insert();
        Entry."Entry No." := 2;
        Entry."Case No." := 'C1';
        Entry.Open := true;
        Entry."Due Date" := Today() - 1;
        Entry.Insert();
        Entry."Entry No." := 3;
        Entry."Case No." := 'C1';
        Entry.Open := true;
        Entry."Due Date" := Today() + 30;
        Entry.Insert();
        Entry."Entry No." := 4;
        Entry."Case No." := 'C2';
        Entry.Open := true;
        Entry."Due Date" := Today() - 1;
        Entry.Insert();
        Seen := '';
    end;

    [TryFunction]
    local procedure TryKey(var P: TestPage "LT K12 Ledger Entries"; EntryNo: Integer; var Found: Boolean)
    begin
        Found := P.GoToKey(EntryNo);
    end;

    local procedure KeyReading(var P: TestPage "LT K12 Ledger Entries"; EntryNo: Integer): Text
    var
        Found: Boolean;
    begin
        ClearLastError();
        if TryKey(P, EntryNo, Found) then
            exit('key' + Format(EntryNo) + '=' + Format(Found));
        exit('key' + Format(EntryNo) + ' error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Read(var P: TestPage "LT K12 Ledger Entries")
    var
        Rows: Text;
    begin
        if P.First() then
            repeat
                Rows += P."Entry No.".Value() + ',';
            until not P.Next();
        Seen := 'rows=' + Rows;
        Seen += ' ' + KeyReading(P, 1) + ' ' + KeyReading(P, 2) + ' ' + KeyReading(P, 3) + ' ' + KeyReading(P, 4);
    end;

    [TryFunction]
    local procedure TryKeyStatement(var P: TestPage "LT K12 Ledger Entries"; EntryNo: Integer)
    begin
        P.GoToKey(EntryNo);
    end;

    // Statement form: GoToKey called without using the Boolean it returns (the shape of the report's asserterror).
    local procedure ReadStatements(var P: TestPage "LT K12 Ledger Entries")
    var
        EntryNo: Integer;
    begin
        Seen := '';
        for EntryNo := 1 to 4 do begin
            ClearLastError();
            if TryKeyStatement(P, EntryNo) then
                Seen += 'key' + Format(EntryNo) + '=no error '
            else
                Seen += 'key' + Format(EntryNo) + ' error:' + GetLastErrorText() + '|' + GetLastErrorCode() + ' ';
        end;
    end;

    [PageHandler]
    procedure EntriesStatementHandler(var Entries: TestPage "LT K12 Ledger Entries")
    begin
        ReadStatements(Entries);
    end;

    [PageHandler]
    procedure EntriesHandler(var Entries: TestPage "LT K12 Ledger Entries")
    begin
        Read(Entries);
    end;

    [ModalPageHandler]
    procedure EntriesModalHandler(var Entries: TestPage "LT K12 Ledger Entries")
    begin
        Read(Entries);
        Entries.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('EntriesHandler')]
    procedure Y7412_Run0_IssueShape()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "LT K12 Ledger Entry";
    begin
        Seed();
        Entry.SetCurrentKey("Case No.", Open);
        Entry.SetRange("Case No.", 'C1');
        Entry.SetRange(Open, true);
        Entry.SetFilter("Due Date", '<=%1', Today());
        Page.Run(0, Entry);
        Observer.Observe('Page.Run(0, Entry): case, open, due date filters, secondary key', Seen);
        Observer.Expect('Page.Run(0, Entry): case, open, due date filters, secondary key', 'rows=2, key1=No key2=Yes key3=No key4=No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('EntriesHandler')]
    procedure Y7412_Run_ExplicitPage_And_NoFilter()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "LT K12 Ledger Entry";
    begin
        Seed();
        Entry.SetCurrentKey("Case No.", Open);
        Entry.SetRange("Case No.", 'C1');
        Entry.SetRange(Open, true);
        Entry.SetFilter("Due Date", '<=%1', Today());
        Page.Run(Page::"LT K12 Ledger Entries", Entry);
        Observer.Observe('Page.Run(Page::X, Entry): same filters', Seen);
        Entry.Reset();
        Page.Run(0, Entry);
        Observer.Observe('Page.Run(0, Entry): no filter', Seen);
        Observer.Expect('Page.Run(Page::X, Entry): same filters', 'rows=2, key1=No key2=Yes key3=No key4=No');
        Observer.Expect('Page.Run(0, Entry): no filter', 'rows=1,2,3,4, key1=Yes key2=Yes key3=Yes key4=Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('EntriesHandler')]
    procedure Y7412_Run0_SingleFilters()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "LT K12 Ledger Entry";
    begin
        Seed();
        Entry.SetRange(Open, true);
        Page.Run(0, Entry);
        Observer.Observe('Page.Run(0, Entry): Open filter only, primary key', Seen);
        Entry.Reset();
        Entry.SetFilter("Due Date", '<=%1', Today());
        Page.Run(0, Entry);
        Observer.Observe('Page.Run(0, Entry): due date filter only', Seen);
        Entry.Reset();
        Entry.SetRange("Entry No.", 2, 3);
        Page.Run(0, Entry);
        Observer.Observe('Page.Run(0, Entry): primary key range 2..3', Seen);
        Observer.Expect('Page.Run(0, Entry): Open filter only, primary key', 'rows=2,3,4, key1=No key2=Yes key3=Yes key4=Yes');
        Observer.Expect('Page.Run(0, Entry): due date filter only', 'rows=1,2,4, key1=Yes key2=Yes key3=No key4=Yes');
        Observer.Expect('Page.Run(0, Entry): primary key range 2..3', 'rows=2,3, key1=No key2=Yes key3=Yes key4=No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('EntriesModalHandler')]
    procedure Y7412_RunModal0_Filters()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "LT K12 Ledger Entry";
    begin
        Seed();
        Entry.SetCurrentKey("Case No.", Open);
        Entry.SetRange("Case No.", 'C1');
        Entry.SetRange(Open, true);
        Entry.SetFilter("Due Date", '<=%1', Today());
        Page.RunModal(0, Entry);
        Observer.Observe('Page.RunModal(0, Entry): same filters', Seen);
        Observer.Expect('Page.RunModal(0, Entry): same filters', 'rows=2, key1=No key2=Yes key3=No key4=No');
        Observer.Verify();
    end;

    // Matrix: what a record carries into Page.Run / Page.RunModal beyond plain filters: filter group 2, a view, a copy, CopyFilters, a temporary
    // record, an OR of ranges on one field, and the record after SetRecord-style reuse (Run twice on the same variable).
    [Test]
    [HandlerFunctions('EntriesHandler')]
    procedure Y7412_Run0_FilterGroup_View_Copies()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "LT K12 Ledger Entry";
        Other: Record "LT K12 Ledger Entry";
    begin
        Seed();
        Entry.FilterGroup(2);
        Entry.SetRange("Case No.", 'C1');
        Entry.FilterGroup(0);
        Page.Run(0, Entry);
        Observer.Observe('filter in group 2 only', Seen);
        Entry.Reset();
        Entry.SetView('SORTING("Case No.",Open) WHERE(Open=CONST(Yes),"Due Date"=FILTER(..' + Format(Today() - 1) + '))');
        Page.Run(0, Entry);
        Observer.Observe('SetView with sorting and filters', Seen);
        Entry.Reset();
        Entry.SetRange(Open, true);
        Entry.SetRange("Case No.", 'C2');
        Other.Copy(Entry);
        Page.Run(0, Other);
        Observer.Observe('Copy of a filtered record', Seen);
        Other.Reset();
        Other.CopyFilters(Entry);
        Page.Run(0, Other);
        Observer.Observe('CopyFilters from a filtered record', Seen);
        Entry.Reset();
        Entry.SetFilter("Entry No.", '1|3');
        Page.Run(0, Entry);
        Observer.Observe('OR of two single keys on the primary key', Seen);
        Observer.Expect('filter in group 2 only', 'rows=1,2,3, key1=Yes key2=Yes key3=Yes key4=No');
        Observer.Expect('SetView with sorting and filters', 'rows=2,4, key1=No key2=Yes key3=No key4=Yes');
        Observer.Expect('Copy of a filtered record', 'rows=4, key1=No key2=No key3=No key4=Yes');
        Observer.Expect('CopyFilters from a filtered record', 'rows=4, key1=No key2=No key3=No key4=Yes');
        Observer.Expect('OR of two single keys on the primary key', 'rows=1,3, key1=Yes key2=No key3=Yes key4=No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('EntriesHandler')]
    procedure Y7412_Run0_TemporaryRecord_And_RecordWithCurrentRow()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "LT K12 Ledger Entry";
        Temp: Record "LT K12 Ledger Entry" temporary;
    begin
        Seed();
        Temp."Entry No." := 2;
        Temp.Insert();
        Temp.SetRange(Open, true);
        Page.Run(0, Temp);
        Observer.Observe('temporary record with one row and a filter', Seen);
        Entry.SetRange(Open, true);
        Entry.FindFirst();
        Page.Run(0, Entry);
        Observer.Observe('filtered record positioned on its first row', Seen);
        Entry.SetRange(Open, false);
        Entry.Get(3);
        Page.Run(0, Entry);
        Observer.Observe('record positioned on a row outside its own filter', Seen);
        Observer.Expect('temporary record with one row and a filter', 'rows= key1=No key2=No key3=No key4=No');
        Observer.Expect('filtered record positioned on its first row', 'rows=2,3,4, key1=No key2=Yes key3=Yes key4=Yes');
        Observer.Expect('record positioned on a row outside its own filter', 'rows=1, key1=Yes key2=No key3=No key4=No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('EntriesModalHandler')]
    procedure Y7412_RunModal_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "LT K12 Ledger Entry";
    begin
        Seed();
        Page.RunModal(Page::"LT K12 Ledger Entries", Entry);
        Observer.Observe('RunModal explicit page, no filter', Seen);
        Entry.SetRange(Open, true);
        Page.RunModal(Page::"LT K12 Ledger Entries", Entry);
        Observer.Observe('RunModal explicit page, Open filter', Seen);
        Entry.Reset();
        Entry.SetRange("Case No.", 'C2');
        Page.RunModal(0, Entry);
        Observer.Observe('RunModal(0), case filter on the secondary key field', Seen);
        Observer.Expect('RunModal explicit page, no filter', 'rows=1,2,3,4, key1=Yes key2=Yes key3=Yes key4=Yes');
        Observer.Expect('RunModal explicit page, Open filter', 'rows=2,3,4, key1=No key2=Yes key3=Yes key4=Yes');
        Observer.Expect('RunModal(0), case filter on the secondary key field', 'rows=4, key1=No key2=No key3=No key4=Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('EntriesStatementHandler')]
    procedure Y7412_Run0_StatementForm()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "LT K12 Ledger Entry";
    begin
        Seed();
        Entry.SetCurrentKey("Case No.", Open);
        Entry.SetRange("Case No.", 'C1');
        Entry.SetRange(Open, true);
        Entry.SetFilter("Due Date", '<=%1', Today());
        Page.Run(0, Entry);
        Observer.Observe('GoToKey statements, issue filters (only row 2 passes)', Seen);
        Entry.Reset();
        Page.Run(0, Entry);
        Observer.Observe('GoToKey statements, no filter', Seen);
        Observer.Expect('GoToKey statements, issue filters (only row 2 passes)', 'key1 error:The row does not exist on the TestPage.|TestRowNotFound key2=no error key3 error:The row does not exist on the TestPage.|TestRowNotFound key4 error:The row does not exist on the TestPage.|TestRowNotFound ');
        Observer.Expect('GoToKey statements, no filter', 'key1=no error key2=no error key3=no error key4=no error ');
        Observer.Verify();
    end;
}
